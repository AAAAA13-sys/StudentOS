package com.studentos.studentos

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

data class FocusPhaseSpec(val kind: String, val start: Long, val end: Long, val round: Int)

/**
 * The running focus session as the app sent it (see `FocusSession.toNative`
 * in Dart). Read by the strict-lockdown service and the phase-change alarms.
 */
object FocusStore {
    private const val PREFS = "studentos_focus"
    private const val KEY = "session"
    private const val CHANNEL_RUN = "focus_running"
    private const val CHANNEL_CHANGE = "focus_change"
    private const val CHANNEL_CHANGE_QUIET = "focus_change_quiet"
    private const val NOTE_RUN = 4501
    private const val NOTE_CHANGE = 4502
    private const val REQUEST = 900_000

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun session(ctx: Context): JSONObject? = prefs(ctx).getString(KEY, null)?.let {
        try { JSONObject(it) } catch (e: Exception) { null }
    }

    fun phases(s: JSONObject): List<FocusPhaseSpec> {
        val arr = s.optJSONArray("phases") ?: return emptyList()
        return (0 until arr.length()).map {
            val p = arr.getJSONObject(it)
            FocusPhaseSpec(p.getString("kind"), p.getLong("start"), p.getLong("end"), p.optInt("round", 1))
        }
    }

    fun phaseAt(s: JSONObject, now: Long): FocusPhaseSpec? =
        phases(s).firstOrNull { now >= it.start && now < it.end }

    /** True while a strict focus phase is running. */
    fun strictNow(ctx: Context, now: Long = System.currentTimeMillis()): Boolean {
        val s = session(ctx) ?: return false
        return s.optString("lockdown") == "strict" && phaseAt(s, now)?.kind == "focus"
    }

    fun focusEnd(ctx: Context): Long? {
        val s = session(ctx) ?: return null
        return phaseAt(s, System.currentTimeMillis())?.end
    }

    fun allowedApps(ctx: Context): Set<String> {
        val s = session(ctx) ?: return emptySet()
        val arr = s.optJSONArray("allowedApps") ?: JSONArray()
        return (0 until arr.length()).map { arr.getString(it) }.toSet()
    }

    fun start(ctx: Context, session: JSONObject) {
        stop(ctx)
        prefs(ctx).edit().putString(KEY, session.toString()).apply()
        reschedule(ctx)
        FocusTileService.requestListening(ctx)
    }

    fun stop(ctx: Context) {
        val s = session(ctx)
        if (s != null) {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            for (i in phases(s).indices) am.cancel(boundary(ctx, i))
        }
        prefs(ctx).edit().remove(KEY).apply()
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTE_RUN)
        CalendarWidgetProvider.refresh(ctx)
        FocusTileService.requestListening(ctx)
    }

    private fun boundary(ctx: Context, index: Int): PendingIntent = PendingIntent.getBroadcast(
        ctx, REQUEST + index,
        Intent(ctx, FocusReceiver::class.java).putExtra("index", index),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** One alarm at the end of every phase still to come. */
    fun reschedule(ctx: Context) {
        val s = session(ctx) ?: return
        val now = System.currentTimeMillis()
        val list = phases(s)
        if (list.isEmpty() || list.last().end <= now) return stop(ctx)
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        list.forEachIndexed { i, p ->
            if (p.end <= now) return@forEachIndexed
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, p.end, boundary(ctx, i))
                } else {
                    am.setExact(AlarmManager.RTC_WAKEUP, p.end, boundary(ctx, i))
                }
            } catch (e: SecurityException) {
                am.set(AlarmManager.RTC_WAKEUP, p.end, boundary(ctx, i))
            }
        }
        showRunning(ctx)
        CalendarWidgetProvider.refresh(ctx)
    }

    private fun channels(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_RUN) == null) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_RUN, "Focus timer", NotificationManager.IMPORTANCE_LOW)
                    .apply { setShowBadge(false) },
            )
        }
        if (nm.getNotificationChannel(CHANNEL_CHANGE) == null) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_CHANGE, "Focus phase changes", NotificationManager.IMPORTANCE_HIGH)
                    .apply { enableVibration(true) },
            )
        }
        if (nm.getNotificationChannel(CHANNEL_CHANGE_QUIET) == null) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_CHANGE_QUIET, "Focus phase changes (silent)", NotificationManager.IMPORTANCE_DEFAULT)
                    .apply { setSound(null, null); enableVibration(false) },
            )
        }
    }

    private fun openApp(ctx: Context): PendingIntent = PendingIntent.getActivity(
        ctx, 12,
        Intent(ctx, MainActivity::class.java)
            .putExtra(MainActivity.EXTRA_ROUTE, MainActivity.ROUTE_TIMER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun label(kind: String) = when (kind) {
        "focus" -> "Focus"
        "short" -> "Short break"
        else -> "Long break"
    }

    /** The ongoing notification with a live countdown to the phase end. */
    fun showRunning(ctx: Context) {
        val s = session(ctx) ?: return
        val now = System.currentTimeMillis()
        val p = phaseAt(s, now) ?: return
        channels(ctx)
        val total = phases(s).count { it.kind == "focus" }
        val strict = s.optString("lockdown") == "strict" && p.kind == "focus"
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(ctx, CHANNEL_RUN)
        else Notification.Builder(ctx)
        b.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("${label(p.kind)} · round ${p.round} of $total")
            .setContentText(if (strict) "Phone held until the timer ends" else "Ends at the time shown")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openApp(ctx))
            .setWhen(p.end)
            .setShowWhen(true)
            .setUsesChronometer(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) b.setChronometerCountDown(true)
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try { nm.notify(NOTE_RUN, b.build()) } catch (e: SecurityException) {}
    }

    /** Called at a phase end: says what comes next. */
    fun phaseEnded(ctx: Context, index: Int) {
        val s = session(ctx) ?: return
        val list = phases(s)
        val ended = list.getOrNull(index) ?: return
        val next = list.drop(index + 1).firstOrNull { it.end > it.start }
        channels(ctx)
        val chime = s.optBoolean("chime", true)
        val (title, text) = when {
            next == null -> "Session done" to "Every round is finished. Nice work."
            next.kind == "focus" -> "Back to focus" to "Round ${next.round} starts now."
            else -> "${label(next.kind)} · ${(next.end - next.start) / 60_000} min" to
                "Round ${ended.round} done. Stand up and stretch."
        }
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(ctx, if (chime) CHANNEL_CHANGE else CHANNEL_CHANGE_QUIET)
        } else {
            Notification.Builder(ctx).setDefaults(if (chime) Notification.DEFAULT_ALL else 0)
        }
        b.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setAutoCancel(true)
            .setContentIntent(openApp(ctx))
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try { nm.notify(NOTE_CHANGE, b.build()) } catch (e: SecurityException) {}
        if (next == null) {
            // The app logs the finished session the next time it opens.
            nm.cancel(NOTE_RUN)
        } else {
            showRunning(ctx)
        }
        CalendarWidgetProvider.refresh(ctx)
        FocusTileService.requestListening(ctx)
    }
}

class FocusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        FocusStore.phaseEnded(context, intent.getIntExtra("index", -1))
    }
}
