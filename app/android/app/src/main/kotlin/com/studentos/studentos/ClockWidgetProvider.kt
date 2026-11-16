package com.studentos.studentos

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Clock widget: the next alarm, and either a live focus countdown or a
 * Start focus button. Read straight from the Android-side stores, so it is
 * right even when the app has not been opened.
 */
class ClockWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val now = System.currentTimeMillis()
        val next = AlarmStore.all(context)
            .mapNotNull { a -> a.nextTrigger(now)?.let { it to a } }
            .minByOrNull { it.first }
        val session = FocusStore.session(context)
        val phases = session?.let { FocusStore.phases(it) } ?: emptyList()
        val phase = phases.firstOrNull { now >= it.start && now < it.end }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_clock).apply {
                if (next == null) {
                    setTextViewText(R.id.clock_alarm_time, "No alarm set")
                    setTextViewText(R.id.clock_alarm_detail, "Tap to add one")
                } else {
                    val (at, alarm) = next
                    setTextViewText(
                        R.id.clock_alarm_time,
                        SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(at)),
                    )
                    setTextViewText(
                        R.id.clock_alarm_detail,
                        listOf(dayWord(at, now), alarm.label).filter { it.isNotBlank() }
                            .joinToString(" · "),
                    )
                }
                setOnClickPendingIntent(
                    R.id.clock_alarm_area,
                    WidgetSupport.openApp(context, "clock", 22),
                )

                if (phase == null) {
                    setViewVisibility(R.id.clock_focus_running, View.GONE)
                    setViewVisibility(R.id.clock_start_focus, View.VISIBLE)
                    setOnClickPendingIntent(
                        R.id.clock_start_focus,
                        WidgetSupport.openApp(context, "start_focus", 23),
                    )
                } else {
                    setViewVisibility(R.id.clock_start_focus, View.GONE)
                    setViewVisibility(R.id.clock_focus_running, View.VISIBLE)
                    val total = phases.count { it.kind == "focus" }
                    val label = when (phase.kind) {
                        "focus" -> "Focus"
                        "short" -> "Short break"
                        else -> "Long break"
                    }
                    setTextViewText(R.id.clock_focus_label, "$label · round ${phase.round} of $total")
                    // The chronometer counts down on its own; no updates needed.
                    val base = SystemClock.elapsedRealtime() + (phase.end - now)
                    setChronometer(R.id.clock_focus_timer, base, null, true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.clock_focus_timer, true)
                    }
                    setOnClickPendingIntent(
                        R.id.clock_focus_running,
                        WidgetSupport.openApp(context, MainActivity.ROUTE_TIMER, 24),
                    )
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    /** "Today", "Tomorrow" or the weekday. */
    private fun dayWord(at: Long, now: Long): String {
        val a = Calendar.getInstance().apply { timeInMillis = at }
        val n = Calendar.getInstance().apply { timeInMillis = now }
        val days = (a.get(Calendar.YEAR) * 400 + a.get(Calendar.DAY_OF_YEAR)) -
            (n.get(Calendar.YEAR) * 400 + n.get(Calendar.DAY_OF_YEAR))
        return when (days) {
            0 -> "Today"
            1 -> "Tomorrow"
            else -> SimpleDateFormat("EEEE", Locale.getDefault()).format(Date(at))
        }
    }

    companion object {
        fun refresh(ctx: Context) = WidgetSupport.refresh(ctx, ClockWidgetProvider::class.java)
    }
}
