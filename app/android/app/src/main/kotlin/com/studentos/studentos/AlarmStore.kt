package com.studentos.studentos

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/** One alarm as the app sent it (see `Alarm.toNative` in Dart). */
data class AlarmSpec(
    val id: Int,
    val hour: Int,
    val minute: Int,
    val days: Int,
    val label: String,
    val enabled: Boolean,
    val soundUri: String?,
    val volume: Int,
    val rampSeconds: Int,
    val volumeLock: Boolean,
    val vibrate: Boolean,
    val challenge: String,
    val challengeCount: Int,
    val difficulty: String,
    val phrase: String,
    val snoozeLimit: Int,
    val snoozeMinutes: Int,
    val wakeCheck: Boolean,
    val wakeCheckMinutes: Int,
    val json: JSONObject,
) {
    companion object {
        fun from(o: JSONObject) = AlarmSpec(
            id = o.getInt("id"),
            hour = o.getInt("hour"),
            minute = o.getInt("minute"),
            days = o.optInt("days", 0),
            label = o.optString("label", ""),
            enabled = o.optBoolean("enabled", true),
            soundUri = if (o.isNull("soundUri")) null else o.optString("soundUri").ifEmpty { null },
            volume = o.optInt("volume", 100).coerceIn(10, 100),
            rampSeconds = o.optInt("rampSeconds", 0).coerceIn(0, 300),
            volumeLock = o.optBoolean("volumeLock", true),
            vibrate = o.optBoolean("vibrate", true),
            challenge = o.optString("challenge", "math"),
            challengeCount = o.optInt("challengeCount", 3).coerceIn(1, 50),
            difficulty = o.optString("difficulty", "medium"),
            phrase = o.optString("phrase", "I am awake and I am getting up now"),
            snoozeLimit = o.optInt("snoozeLimit", 1).coerceIn(0, 10),
            snoozeMinutes = o.optInt("snoozeMinutes", 5).coerceIn(1, 60),
            wakeCheck = o.optBoolean("wakeCheck", true),
            wakeCheckMinutes = o.optInt("wakeCheckMinutes", 5).coerceIn(1, 60),
            json = o,
        )
    }

    /** Next ring strictly after [nowMs], or null when it is off. */
    fun nextTrigger(nowMs: Long): Long? {
        if (!enabled) return null
        val c = Calendar.getInstance()
        c.timeInMillis = nowMs
        c.set(Calendar.HOUR_OF_DAY, hour)
        c.set(Calendar.MINUTE, minute)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        for (ahead in 0..7) {
            if (ahead > 0) c.add(Calendar.DAY_OF_YEAR, 1)
            if (c.timeInMillis <= nowMs) continue
            // Calendar: Sunday = 1 ... Saturday = 7. Bit 0 is Monday.
            val bit = (c.get(Calendar.DAY_OF_WEEK) + 5) % 7
            if (days == 0 || (days shr bit) and 1 == 1) return c.timeInMillis
        }
        return null
    }
}

/**
 * Keeps the alarm list on the Android side so alarms ring, and are put back
 * after a reboot, without the app running.
 */
object AlarmStore {
    private const val PREFS = "studentos_alarms"
    private const val KEY_ALARMS = "alarms"
    private const val KEY_FIRED = "fired_once"
    private const val KEY_SNOOZES = "snoozes_used"

    const val KIND_MAIN = 0
    const val KIND_SNOOZE = 1
    const val KIND_CHECK = 2

    /** Id used for "Test" rings, which are never stored. */
    const val TEST_ID = -1

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun all(ctx: Context): List<AlarmSpec> {
        val raw = prefs(ctx).getString(KEY_ALARMS, "[]") ?: "[]"
        val arr = try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
        return (0 until arr.length()).mapNotNull {
            try { AlarmSpec.from(arr.getJSONObject(it)) } catch (e: Exception) { null }
        }
    }

    fun find(ctx: Context, id: Int): AlarmSpec? = all(ctx).firstOrNull { it.id == id }

    /** Replaces the list and schedules every enabled alarm again. */
    fun replace(ctx: Context, alarms: JSONArray) {
        val old = all(ctx)
        prefs(ctx).edit().putString(KEY_ALARMS, alarms.toString()).apply()
        for (a in old) cancel(ctx, a.id, KIND_MAIN)
        scheduleAll(ctx)
    }

    fun scheduleAll(ctx: Context) {
        val now = System.currentTimeMillis()
        for (a in all(ctx)) {
            val at = a.nextTrigger(now)
            if (at == null) cancel(ctx, a.id, KIND_MAIN) else schedule(ctx, a.id, KIND_MAIN, at)
        }
        CalendarWidgetProvider.refresh(ctx)
    }

    /** After a one-time alarm rings it is off until the app turns it on. */
    fun markRangOnce(ctx: Context, id: Int) {
        val arr = JSONArray()
        for (a in all(ctx)) {
            val o = a.json
            if (a.id == id && a.days == 0) o.put("enabled", false)
            arr.put(o)
        }
        val fired = JSONArray(prefs(ctx).getString(KEY_FIRED, "[]") ?: "[]")
        fired.put(id)
        prefs(ctx).edit()
            .putString(KEY_ALARMS, arr.toString())
            .putString(KEY_FIRED, fired.toString())
            .apply()
    }

    fun takeFiredOnce(ctx: Context): List<Int> {
        val fired = try {
            JSONArray(prefs(ctx).getString(KEY_FIRED, "[]") ?: "[]")
        } catch (e: Exception) { JSONArray() }
        prefs(ctx).edit().remove(KEY_FIRED).apply()
        return (0 until fired.length()).map { fired.getInt(it) }
    }

    fun snoozesUsed(ctx: Context, id: Int) = prefs(ctx).getInt("$KEY_SNOOZES.$id", 0)

    fun setSnoozesUsed(ctx: Context, id: Int, n: Int) =
        prefs(ctx).edit().putInt("$KEY_SNOOZES.$id", n).apply()

    private fun requestCode(id: Int, kind: Int) = 100_000 + id * 10 + kind

    private fun ringIntent(ctx: Context, id: Int, kind: Int): PendingIntent {
        val intent = Intent(ctx, AlarmReceiver::class.java)
            .setAction(AlarmReceiver.ACTION_RING)
            .putExtra(AlarmReceiver.EXTRA_ID, id)
            .putExtra(AlarmReceiver.EXTRA_KIND, kind)
        return PendingIntent.getBroadcast(
            ctx, requestCode(id, kind), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Uses `setAlarmClock`: the most reliable timing Android offers, exempt
     * from Doze, and it shows the alarm icon in the status bar.
     */
    fun schedule(ctx: Context, id: Int, kind: Int, atMs: Long) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val show = PendingIntent.getActivity(
            ctx, 7, Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val op = ringIntent(ctx, id, kind)
        try {
            am.setAlarmClock(AlarmManager.AlarmClockInfo(atMs, show), op)
        } catch (e: SecurityException) {
            // Exact alarms not allowed (Android 12 with the setting off):
            // the closest fallback still fires through Doze.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, op)
            } else {
                am.set(AlarmManager.RTC_WAKEUP, atMs, op)
            }
        }
    }

    fun cancel(ctx: Context, id: Int, kind: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(ringIntent(ctx, id, kind))
    }
}
