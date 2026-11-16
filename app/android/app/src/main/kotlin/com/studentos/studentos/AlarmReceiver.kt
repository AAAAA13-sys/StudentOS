package com.studentos.studentos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/** Fires when an alarm, a snooze or a wake-up check is due. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_RING) return
        val id = intent.getIntExtra(EXTRA_ID, Int.MIN_VALUE)
        val kind = intent.getIntExtra(EXTRA_KIND, AlarmStore.KIND_MAIN)
        val spec = AlarmStore.find(context, id) ?: return

        if (kind == AlarmStore.KIND_MAIN) {
            // A fresh morning: snoozes start over.
            AlarmStore.setSnoozesUsed(context, id, 0)
            if (spec.days == 0) {
                AlarmStore.markRangOnce(context, id)
            } else {
                spec.nextTrigger(System.currentTimeMillis() + 60_000)?.let {
                    AlarmStore.schedule(context, id, AlarmStore.KIND_MAIN, it)
                }
            }
        }

        val service = Intent(context, AlarmService::class.java)
            .setAction(AlarmService.ACTION_START)
            .putExtra(AlarmService.EXTRA_ALARM, spec.json.toString())
            .putExtra(AlarmService.EXTRA_CHECK, kind == AlarmStore.KIND_CHECK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(service)
        } else {
            context.startService(service)
        }
    }

    companion object {
        const val ACTION_RING = "com.studentos.studentos.RING"
        const val EXTRA_ID = "id"
        const val EXTRA_KIND = "kind"
    }
}

/** Puts alarms and a running focus session back after a reboot or clock change. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AlarmStore.scheduleAll(context)
        FocusStore.reschedule(context)
    }
}
