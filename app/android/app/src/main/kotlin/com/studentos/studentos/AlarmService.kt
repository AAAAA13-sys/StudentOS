package com.studentos.studentos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import org.json.JSONObject

/**
 * Rings an alarm until it is properly turned off: alarm stream at the chosen
 * volume (pushed back up if it is turned down), optional slow ramp, strong
 * vibration, and a full-screen screen that needs the challenge solved.
 */
class AlarmService : Service() {
    private val main = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var tones: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var spec: AlarmSpec? = null
    private var isCheck = false
    private var ringing = false
    private var savedVolume = -1
    private var targetVolume = 0
    private var startedAt = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val raw = intent.getStringExtra(EXTRA_ALARM) ?: return stopNow()
                val next = try { AlarmSpec.from(JSONObject(raw)) } catch (e: Exception) { return stopNow() }
                // A second alarm while one rings replaces it.
                silence()
                spec = next
                isCheck = intent.getBooleanExtra(EXTRA_CHECK, false)
                current = next
                currentIsCheck = isCheck
                goForeground(next)
                acquireWake()
                if (isCheck) startCheck() else startRinging()
                openScreen()
            }
            ACTION_DISMISS -> dismiss()
            ACTION_SNOOZE -> snooze()
            ACTION_AWAKE -> {
                // Answered the wake-up check.
                finish()
            }
            else -> if (spec == null) return stopNow()
        }
        return START_NOT_STICKY
    }

    private fun stopNow(): Int {
        stopSelf()
        return START_NOT_STICKY
    }

    private fun acquireWake() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "studentos:alarm").also {
            it.acquire(MAX_RING_MS + 60_000)
        }
    }

    private fun channel(): String {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL) == null) {
            val ch = NotificationChannel(CHANNEL, "Alarms", NotificationManager.IMPORTANCE_HIGH)
            ch.description = "Wake-up alarms and wake-up checks"
            // The service plays the sound itself, on the alarm stream.
            ch.setSound(null, null)
            ch.enableVibration(false)
            ch.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            ch.setBypassDnd(true)
            nm.createNotificationChannel(ch)
        }
        return CHANNEL
    }

    private fun screenIntent(): PendingIntent = PendingIntent.getActivity(
        this, 11,
        Intent(this, AlarmActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun goForeground(s: AlarmSpec) {
        val title = if (isCheck) "Still awake?" else s.label.ifBlank { "Alarm" }
        val text = if (isCheck) "Tap to answer, or the alarm rings again"
        else String.format("%d:%02d · solve it to turn it off", s.hour, s.minute)
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, channel())
        else Notification.Builder(this).setPriority(Notification.PRIORITY_MAX)
        val n = b.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(screenIntent())
            .setFullScreenIntent(screenIntent(), true)
            .build()
        n.flags = n.flags or Notification.FLAG_INSISTENT or Notification.FLAG_NO_CLEAR
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
    }

    /** Opens the alarm screen straight away where Android allows it. */
    private fun openScreen() {
        // Light focus lockdown pins StudentOS, which hides the alarm and its
        // notification. The alarm wins: ask the pinned app to unpin first;
        // it then opens the alarm screen itself.
        val am = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val pinned = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            am.lockTaskModeState != android.app.ActivityManager.LOCK_TASK_MODE_NONE
        if (pinned) {
            try {
                startActivity(
                    Intent(this, MainActivity::class.java)
                        .putExtra(MainActivity.EXTRA_UNPIN_FOR_ALARM, true)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                )
                return
            } catch (e: Exception) {
                // Fall through to the normal attempt.
            }
        }
        try {
            startActivity(
                Intent(this, AlarmActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION),
            )
        } catch (e: Exception) {
            // Blocked from the background: the full-screen notification
            // opens it instead.
        }
    }

    private fun startRinging() {
        val s = spec ?: return
        ringing = true
        startedAt = System.currentTimeMillis()
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val max = audio.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        if (savedVolume < 0) savedVolume = audio.getStreamVolume(AudioManager.STREAM_ALARM)
        targetVolume = maxOf(1, Math.round(max * s.volume / 100f))
        setAlarmVolume(audio)

        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val uri: Uri? = s.soundUri?.let { Uri.parse(it) }
            ?: RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM)
            ?: Settings.System.DEFAULT_ALARM_ALERT_URI
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        player = try {
            MediaPlayer().apply {
                setAudioAttributes(attrs)
                setDataSource(this@AlarmService, uri!!)
                isLooping = true
                prepare()
                val startLevel = if (s.rampSeconds > 0) 0.08f else 1f
                setVolume(startLevel, startLevel)
                start()
            }
        } catch (e: Exception) {
            null
        }
        if (player == null) {
            // No usable sound file (some emulators): loud beeping instead.
            tones = try { ToneGenerator(AudioManager.STREAM_ALARM, 100) } catch (e: Exception) { null }
            beep()
        }
        if (s.vibrate) vibrate()
        main.post(watchdog)
    }

    private fun beep() {
        val t = tones ?: return
        if (!ringing) return
        t.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 900)
        main.postDelayed({ beep() }, 1100)
    }

    private fun setAlarmVolume(audio: AudioManager) {
        try {
            audio.setStreamVolume(AudioManager.STREAM_ALARM, targetVolume, 0)
        } catch (e: SecurityException) {
            // Do Not Disturb may refuse; the alarm stream usually still plays.
        }
    }

    /** Every half second: volume ramp, volume lock and the safety stop. */
    private val watchdog = object : Runnable {
        override fun run() {
            val s = spec ?: return
            if (!ringing) return
            val elapsed = System.currentTimeMillis() - startedAt
            if (s.rampSeconds > 0) {
                val level = (0.08f + 0.92f * elapsed / (s.rampSeconds * 1000f)).coerceAtMost(1f)
                try { player?.setVolume(level, level) } catch (e: Exception) {}
            }
            if (s.volumeLock) {
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                if (audio.getStreamVolume(AudioManager.STREAM_ALARM) < targetVolume) setAlarmVolume(audio)
            }
            if (elapsed > MAX_RING_MS) {
                // An hour of ringing with nobody there: stop to save the
                // battery rather than ring all day.
                finish()
                return
            }
            main.postDelayed(this, 500)
        }
    }

    private fun vibrate() {
        val v = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        vibrator = v
        val pattern = longArrayOf(0, 900, 300, 900, 300, 300, 200)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
            @Suppress("DEPRECATION")
            v.vibrate(VibrationEffect.createWaveform(pattern, 0), attrs)
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(pattern, 0)
        }
    }

    /** The wake-up check: a short nudge, then the full alarm if unanswered. */
    private fun startCheck() {
        try {
            ToneGenerator(AudioManager.STREAM_ALARM, 60).startTone(ToneGenerator.TONE_PROP_BEEP2, 600)
        } catch (e: Exception) {}
        main.postDelayed(escalate, CHECK_WINDOW_MS)
    }

    private val escalate = Runnable {
        isCheck = false
        currentIsCheck = false
        spec?.let { goForeground(it) }
        startRinging()
        openScreen()
        AlarmActivity.refresh()
    }

    private fun dismiss() {
        val s = spec
        val wasCheck = isCheck
        if (s != null && !wasCheck && s.wakeCheck && s.id != AlarmStore.TEST_ID) {
            AlarmStore.schedule(
                this, s.id, AlarmStore.KIND_CHECK,
                System.currentTimeMillis() + s.wakeCheckMinutes * 60_000L,
            )
        }
        finish()
    }

    private fun snooze() {
        val s = spec ?: return finish()
        val used = AlarmStore.snoozesUsed(this, s.id)
        if (used >= s.snoozeLimit) return
        if (s.id != AlarmStore.TEST_ID) {
            AlarmStore.setSnoozesUsed(this, s.id, used + 1)
            AlarmStore.schedule(
                this, s.id, AlarmStore.KIND_SNOOZE,
                System.currentTimeMillis() + s.snoozeMinutes * 60_000L,
            )
        }
        finish()
    }

    private fun silence() {
        ringing = false
        main.removeCallbacksAndMessages(null)
        try { player?.stop() } catch (e: Exception) {}
        player?.release()
        player = null
        tones?.release()
        tones = null
        vibrator?.cancel()
        vibrator = null
    }

    private fun finish() {
        silence()
        if (savedVolume >= 0) {
            val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            try { audio.setStreamVolume(AudioManager.STREAM_ALARM, savedVolume, 0) } catch (e: Exception) {}
            savedVolume = -1
        }
        current = null
        AlarmActivity.close()
        wakeLock?.let { if (it.isHeld) it.release() }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        silence()
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "start"
        const val ACTION_DISMISS = "dismiss"
        const val ACTION_SNOOZE = "snooze"
        const val ACTION_AWAKE = "awake"
        const val EXTRA_ALARM = "alarm"
        const val EXTRA_CHECK = "check"
        private const val CHANNEL = "alarm_ring"
        private const val NOTIFICATION_ID = 4401
        private const val MAX_RING_MS = 60L * 60 * 1000
        const val CHECK_WINDOW_MS = 60_000L

        /** The alarm ringing now, read by the alarm screen. */
        @Volatile var current: AlarmSpec? = null
        @Volatile var currentIsCheck = false

        fun send(ctx: Context, action: String) {
            ctx.startService(Intent(ctx, AlarmService::class.java).setAction(action))
        }

        fun snoozesLeft(ctx: Context): Int {
            val s = current ?: return 0
            return (s.snoozeLimit - AlarmStore.snoozesUsed(ctx, s.id)).coerceAtLeast(0)
        }
    }
}
