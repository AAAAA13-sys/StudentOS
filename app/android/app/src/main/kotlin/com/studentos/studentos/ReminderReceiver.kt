package com.studentos.studentos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

/** Shows one event reminder as a notification that opens that day. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val raw = intent.getStringExtra(ReminderStore.EXTRA_ENTRY) ?: return
        val entry = try { JSONObject(raw) } catch (e: Exception) { return }
        val id = entry.optInt("id")

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Event reminders", NotificationManager.IMPORTANCE_HIGH),
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
        }
        val notification = builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(entry.optString("title"))
            .setContentText(entry.optString("text"))
            .setStyle(Notification.BigTextStyle().bigText(entry.optString("text")))
            .setWhen(entry.optLong("startsAt", System.currentTimeMillis()))
            .setShowWhen(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(
                WidgetSupport.openApp(
                    context, entry.optString("route", "calendar"), 400_000 + (id % 100_000),
                ),
            )
            .build()
        try {
            nm.notify(id, notification)
        } catch (e: SecurityException) {
            // Notifications are off; the app shows a hint in the editor.
        }
        ReminderStore.remove(context, id)
    }

    companion object {
        const val CHANNEL = "event_reminders"
    }
}
