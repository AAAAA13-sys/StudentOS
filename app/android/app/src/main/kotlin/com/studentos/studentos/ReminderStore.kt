package com.studentos.studentos

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * Keeps the upcoming event reminders the app computed (see `ReminderFire` in
 * Dart) so they fire, and are put back after a reboot, without the app
 * running. Each reminder takes one of [MAX] alarm slots.
 */
object ReminderStore {
    private const val PREFS = "studentos_reminders"
    private const val KEY_LIST = "list"
    const val MAX = 64
    private const val REQUEST_BASE = 300_000
    const val EXTRA_ENTRY = "entry"
    const val ACTION_FIRE = "com.studentos.studentos.REMINDER"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(ctx: Context): List<JSONObject> {
        val arr = try {
            JSONArray(prefs(ctx).getString(KEY_LIST, "[]") ?: "[]")
        } catch (e: Exception) {
            JSONArray()
        }
        return (0 until arr.length()).mapNotNull { arr.optJSONObject(it) }
    }

    private fun save(ctx: Context, list: List<JSONObject>) {
        val arr = JSONArray()
        list.forEach { arr.put(it) }
        prefs(ctx).edit().putString(KEY_LIST, arr.toString()).apply()
    }

    /** Replaces the stored list with [entries] and schedules it. */
    fun replace(ctx: Context, entries: JSONArray) {
        for (slot in 0 until MAX) cancelSlot(ctx, slot)
        val list = (0 until minOf(entries.length(), MAX)).mapNotNull { entries.optJSONObject(it) }
        save(ctx, list)
        scheduleAll(ctx)
    }

    /** Drops reminders already past and schedules the rest. */
    fun scheduleAll(ctx: Context) {
        val now = System.currentTimeMillis()
        val live = load(ctx).filter { it.optLong("fireAt", 0L) > now }.take(MAX)
        save(ctx, live)
        for (slot in 0 until MAX) cancelSlot(ctx, slot)
        live.forEachIndexed { slot, entry -> schedule(ctx, slot, entry) }
    }

    /** Forgets [id] after it fired. Its alarm already went off. */
    fun remove(ctx: Context, id: Int) {
        save(ctx, load(ctx).filter { it.optInt("id") != id })
    }

    private fun pending(ctx: Context, slot: Int, entry: JSONObject?): PendingIntent {
        val intent = Intent(ctx, ReminderReceiver::class.java).setAction(ACTION_FIRE)
        if (entry != null) intent.putExtra(EXTRA_ENTRY, entry.toString())
        return PendingIntent.getBroadcast(
            ctx, REQUEST_BASE + slot, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun cancelSlot(ctx: Context, slot: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pending(ctx, slot, null))
    }

    private fun schedule(ctx: Context, slot: Int, entry: JSONObject) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = entry.optLong("fireAt", 0L)
        val op = pending(ctx, slot, entry)
        try {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, op)
        } catch (e: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, op)
            } else {
                am.set(AlarmManager.RTC_WAKEUP, at, op)
            }
        }
    }
}
