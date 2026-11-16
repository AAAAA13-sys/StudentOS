package com.studentos.studentos

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Today widget: the next event, the next alarm, and either a Start focus
 * button or the running focus countdown. The app writes `upcoming_events`;
 * everything else is read from the Android-side stores, so it is right even
 * with the app closed. No network.
 */
class CalendarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val model = TodayModel.load(context)
        for (appWidgetId in appWidgetIds) {
            val views = WidgetSupport.sized(
                appWidgetManager, appWidgetId, SIZES,
                legacyPick = { minW, maxH ->
                    when {
                        maxH in 1..99 -> R.layout.widget_today_small
                        minW in 1..199 -> R.layout.widget_today_narrow
                        else -> R.layout.widget_today
                    }
                },
            ) { layout -> buildViews(context, layout, model) }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        WidgetSupport.scheduleTick(context, CalendarWidgetProvider::class.java, TICK_CODE, model.nextTickAt)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        // Android 12+ switches layouts by itself; older versions need a redraw.
        if (WidgetSupport.resizedLegacy()) onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == WidgetSupport.ACTION_TICK) refresh(context) else super.onReceive(context, intent)
    }

    override fun onDisabled(context: Context) {
        WidgetSupport.cancelTick(context, CalendarWidgetProvider::class.java, TICK_CODE)
    }

    /** What the widget shows, worked out once per redraw. */
    private class TodayModel(
        val title: String,
        val whenText: String,
        val smallSub: String,
        val alarmText: String,
        val mood: Int,
        val phase: FocusPhaseSpec?,
        val rounds: Int,
        val now: Long,
        val nextTickAt: Long,
    ) {
        companion object {
            fun load(ctx: Context): TodayModel {
                val now = System.currentTimeMillis()
                val event = nextEvent(ctx, now)
                val alarm = AlarmStore.all(ctx)
                    .mapNotNull { a -> a.nextTrigger(now) }
                    .minOrNull()
                val session = FocusStore.session(ctx)
                val phases = session?.let { FocusStore.phases(it) } ?: emptyList()
                val phase = phases.firstOrNull { now >= it.start && now < it.end }

                val time = SimpleDateFormat("h:mm a", Locale.getDefault())
                val title = event?.first ?: ctx.getString(R.string.widget_no_events)
                val whenText = if (event == null) ctx.getString(R.string.widget_free_time)
                else dayWord(event.second, now) + " · " + time.format(Date(event.second))
                val alarmText = if (alarm == null) ctx.getString(R.string.widget_no_alarm)
                else ctx.getString(
                    R.string.widget_alarm_at,
                    (if (dayDiff(alarm, now) == 0) "" else alarmDay(alarm) + " ") + time.format(Date(alarm)),
                )
                val smallAlarm = alarm?.let {
                    ctx.getString(R.string.widget_alarm_short, time.format(Date(it)))
                }
                val smallSub = if (event == null) smallAlarm ?: whenText
                else listOfNotNull(
                    (if (dayDiff(event.second, now) == 0) "" else dayWord(event.second, now) + " ") +
                        time.format(Date(event.second)),
                    smallAlarm,
                ).joinToString(" · ")

                val mood = when {
                    phase?.kind == "focus" -> R.drawable.ponpon_focused
                    phase != null || event == null -> R.drawable.ponpon_sleepy
                    else -> R.drawable.ponpon_happy
                }
                // Redraw when the shown event starts, the alarm rings, or the
                // day turns over, whichever comes first.
                val tick = listOfNotNull(
                    event?.second?.plus(1000),
                    alarm?.plus(1000),
                    WidgetSupport.nextMidnight(now),
                ).filter { it > now }.min()
                return TodayModel(
                    title, whenText, smallSub, alarmText, mood, phase,
                    phases.count { it.kind == "focus" }, now, tick,
                )
            }

            /** First stored occurrence that has not started yet. */
            private fun nextEvent(ctx: Context, now: Long): Pair<String, Long>? {
                val raw = HomeWidgetPlugin.getData(ctx).getString("upcoming_events", "[]") ?: "[]"
                val arr = try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    val s = o.optLong("s", 0L)
                    if (s > now) return o.optString("t", "") to s
                }
                return null
            }

            private fun dayDiff(at: Long, now: Long): Int {
                val a = Calendar.getInstance().apply { timeInMillis = at }
                val n = Calendar.getInstance().apply { timeInMillis = now }
                return (a.get(Calendar.YEAR) * 400 + a.get(Calendar.DAY_OF_YEAR)) -
                    (n.get(Calendar.YEAR) * 400 + n.get(Calendar.DAY_OF_YEAR))
            }

            /** Short day for the alarm row so the time is never cut off: "Tue". */
            private fun alarmDay(at: Long): String =
                SimpleDateFormat("EEE", Locale.getDefault()).format(Date(at))

            /** "Today", "Tomorrow", or "Wed, Nov 18". */
            private fun dayWord(at: Long, now: Long): String = when (dayDiff(at, now)) {
                0 -> "Today"
                1 -> "Tomorrow"
                else -> SimpleDateFormat("EEE, MMM d", Locale.getDefault()).format(Date(at))
            }
        }
    }

    companion object {
        private const val TICK_CODE = 26

        private val SIZES = linkedMapOf(
            SizeF(110f, 50f) to R.layout.widget_today_small,
            SizeF(110f, 110f) to R.layout.widget_today_narrow,
            SizeF(250f, 110f) to R.layout.widget_today,
        )

        fun refresh(ctx: Context) = WidgetSupport.refresh(ctx, CalendarWidgetProvider::class.java)

        private fun buildViews(ctx: Context, layoutId: Int, m: TodayModel): RemoteViews {
            val views = RemoteViews(ctx.packageName, layoutId)
            val small = layoutId == R.layout.widget_today_small
            views.setTextViewText(R.id.today_title, m.title)
            views.setTextViewText(R.id.today_when, if (small) m.smallSub else m.whenText)
            views.setTextViewText(R.id.today_alarm, m.alarmText)
            views.setImageViewResource(R.id.widget_ponpon, m.mood)

            val calendar = WidgetSupport.openApp(ctx, "calendar", 20)
            views.setOnClickPendingIntent(android.R.id.background, calendar)
            views.setOnClickPendingIntent(R.id.today_event_area, calendar)
            views.setOnClickPendingIntent(R.id.today_alarm_area, WidgetSupport.openApp(ctx, "clock", 22))

            val phase = m.phase
            if (phase == null) {
                views.setViewVisibility(R.id.today_chip, View.GONE)
                views.setViewVisibility(R.id.today_start, View.VISIBLE)
                views.setOnClickPendingIntent(R.id.today_start, WidgetSupport.openApp(ctx, "start_focus", 23))
            } else {
                views.setViewVisibility(R.id.today_start, View.GONE)
                views.setViewVisibility(R.id.today_chip, View.VISIBLE)
                views.setTextViewText(
                    R.id.today_chip_label,
                    if (phase.kind == "focus") "Focus ${phase.round}/${m.rounds}" else "Break",
                )
                // The chronometer counts down on its own; no updates needed.
                val base = SystemClock.elapsedRealtime() + (phase.end - m.now)
                views.setChronometer(R.id.today_timer, base, null, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.today_timer, true)
                }
                views.setOnClickPendingIntent(
                    R.id.today_chip,
                    WidgetSupport.openApp(ctx, MainActivity.ROUTE_TIMER, 24),
                )
            }
            return views
        }
    }
}
