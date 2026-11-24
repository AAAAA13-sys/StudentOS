package com.studentos.studentos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Today widget: the next event or shift, due tasks with one-tap check-off,
 * due recall count, the next alarm, and either a Start focus button or the
 * running focus countdown. The app writes `upcoming_events`, `widget_tasks`,
 * `widget_tasks_open_due_count`, and `widget_recall_due`; everything else is
 * read from the Android-side stores, so it is right even with the app closed.
 * No network.
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
                        maxH >= 175 -> R.layout.widget_today_tall
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
        when (intent.action) {
            WidgetSupport.ACTION_TICK -> refresh(context)
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, 0)
                if (taskId > 0) {
                    completeTaskOptimistically(context, taskId)
                }
                refresh(context)
            }
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        WidgetSupport.cancelTick(context, CalendarWidgetProvider::class.java, TICK_CODE)
    }

    private data class WidgetTask(val id: Int, val title: String, val overdue: Boolean)

    /** What the widget shows, worked out once per redraw. */
    private class TodayModel(
        val title: String,
        val whenText: String,
        val smallSub: String,
        val alarmText: String,
        /** Time only, for the 2-column layout where a weekday does not fit. */
        val narrowAlarm: String,
        val mood: Int,
        val phase: FocusPhaseSpec?,
        val rounds: Int,
        val tasks: List<WidgetTask>,
        val openDueCount: Int,
        val recallDue: Int,
        val now: Long,
        val nextTickAt: Long,
    ) {
        companion object {
            fun load(ctx: Context): TodayModel {
                val now = System.currentTimeMillis()
                val prefs = HomeWidgetPlugin.getData(ctx)
                val event = nextEvent(prefs, now)
                val alarm = AlarmStore.all(ctx)
                    .mapNotNull { a -> a.nextTrigger(now) }
                    .minOrNull()
                val session = FocusStore.session(ctx)
                val phases = session?.let { FocusStore.phases(it) } ?: emptyList()
                val phase = phases.firstOrNull { now >= it.start && now < it.end }

                val time = SimpleDateFormat("h:mm a", Locale.getDefault())
                val title = event?.first ?: ctx.getString(R.string.widget_no_events)
                val room = event?.third.orEmpty()
                val withRoom = { t: String -> if (room.isEmpty()) t else "$t · $room" }
                val whenText = if (event == null) ctx.getString(R.string.widget_free_time)
                else withRoom(dayWord(event.second, now) + " · " + time.format(Date(event.second)))
                val alarmText = if (alarm == null) ctx.getString(R.string.widget_no_alarm)
                else ctx.getString(
                    R.string.widget_alarm_at,
                    (if (dayDiff(alarm, now) == 0) "" else alarmDay(alarm) + " ") + time.format(Date(alarm)),
                )
                val narrowAlarm = if (alarm == null) ctx.getString(R.string.widget_no_alarm)
                else time.format(Date(alarm))
                val smallAlarm = alarm?.let {
                    ctx.getString(R.string.widget_alarm_short, time.format(Date(it)))
                }
                val smallSub = if (event == null) smallAlarm ?: whenText
                else listOfNotNull(
                    withRoom(
                        (if (dayDiff(event.second, now) == 0) "" else dayWord(event.second, now) + " ") +
                            time.format(Date(event.second)),
                    ),
                    smallAlarm,
                ).joinToString(" · ")

                val mood = when {
                    phase?.kind == "focus" -> R.drawable.ponpon_focused
                    phase != null || event == null -> R.drawable.ponpon_sleepy
                    else -> R.drawable.ponpon_happy
                }

                val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
                val tasks = loadTasks(prefs, todayKey)
                val openDueCount = maxOf(tasks.size, intPref(prefs, "widget_tasks_open_due_count"))
                val recallDue = maxOf(0, intPref(prefs, "widget_recall_due"))

                // Redraw when the shown event starts, the alarm rings, or the
                // day turns over, whichever comes first.
                val tick = listOfNotNull(
                    event?.second?.plus(1000),
                    alarm?.plus(1000),
                    WidgetSupport.nextMidnight(now),
                ).filter { it > now }.min()
                return TodayModel(
                    title, whenText, smallSub, alarmText, narrowAlarm, mood, phase,
                    phases.count { it.kind == "focus" },
                    tasks, openDueCount, recallDue,
                    now, tick,
                )
            }

            /** First stored occurrence that has not started yet. */
            private fun nextEvent(prefs: SharedPreferences, now: Long): Triple<String, Long, String>? {
                val raw = prefs.getString("upcoming_events", "[]") ?: "[]"
                val arr = try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    val s = o.optLong("s", 0L)
                    if (s > now) return Triple(o.optString("t", ""), s, (if (o.isNull("location")) "" else o.optString("location", "").trim()))
                }
                return null
            }

            private fun loadTasks(prefs: SharedPreferences, todayKey: String): List<WidgetTask> {
                val raw = prefs.getString("widget_tasks", "[]") ?: "[]"
                val arr = try { JSONArray(raw) } catch (e: Exception) { JSONArray() }
                val out = mutableListOf<WidgetTask>()
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    val id = o.optInt("id", 0)
                    val title = o.optString("title", "").trim()
                    if (id <= 0 || title.isEmpty()) continue
                    val dueOn = if (o.isNull("dueOn")) "" else o.optString("dueOn", "").trim()
                    val overdue = if (dueOn.isNotEmpty()) dueOn < todayKey else o.optBoolean("overdue", false)
                    out.add(WidgetTask(id, title, overdue))
                }
                return out
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
        const val ACTION_COMPLETE_TASK = "com.studentos.studentos.COMPLETE_WIDGET_TASK"
        private const val EXTRA_TASK_ID = "task_id"

        private val SIZES = linkedMapOf(
            SizeF(110f, 50f) to R.layout.widget_today_small,
            SizeF(110f, 110f) to R.layout.widget_today_narrow,
            SizeF(250f, 110f) to R.layout.widget_today,
            SizeF(250f, 175f) to R.layout.widget_today_tall,
        )

        fun refresh(ctx: Context) = WidgetSupport.refresh(ctx, CalendarWidgetProvider::class.java)

        private fun intPref(prefs: SharedPreferences, key: String, default: Int = 0): Int =
            when (val v = prefs.all[key]) {
                is Number -> v.toInt()
                is String -> v.toIntOrNull() ?: default
                else -> default
            }

        private fun completeTaskIntent(ctx: Context, taskId: Int, requestCode: Int): PendingIntent =
            PendingIntent.getBroadcast(
                ctx,
                requestCode,
                Intent(ctx, CalendarWidgetProvider::class.java)
                    .setAction(ACTION_COMPLETE_TASK)
                    .putExtra(EXTRA_TASK_ID, taskId),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        private fun completeTaskOptimistically(ctx: Context, taskId: Int) {
            val prefs = HomeWidgetPlugin.getData(ctx)
            val now = System.currentTimeMillis()
            val completedRaw = prefs.getString("widget_completed_task_ids", "[]") ?: "[]"
            val completedArr = try { JSONArray(completedRaw) } catch (e: Exception) { JSONArray() }
            completedArr.put(JSONObject().put("id", taskId).put("at", now))

            val tasksRaw = prefs.getString("widget_tasks", "[]") ?: "[]"
            val tasksArr = try { JSONArray(tasksRaw) } catch (e: Exception) { JSONArray() }
            val remaining = JSONArray()
            var removed = false
            for (i in 0 until tasksArr.length()) {
                val o = tasksArr.optJSONObject(i) ?: continue
                if (o.optInt("id", 0) == taskId) {
                    removed = true
                } else {
                    remaining.put(o)
                }
            }

            val currentDue = intPref(prefs, "widget_tasks_open_due_count")
            val nextDue = if (removed && currentDue > 0) currentDue - 1 else currentDue

            prefs.edit()
                .putString("widget_completed_task_ids", completedArr.toString())
                .putString("widget_tasks", remaining.toString())
                .putInt("widget_tasks_open_due_count", nextDue)
                .commit()
        }

        private fun buildViews(ctx: Context, layoutId: Int, m: TodayModel): RemoteViews {
            val views = RemoteViews(ctx.packageName, layoutId)
            val small = layoutId == R.layout.widget_today_small
            val tall = layoutId == R.layout.widget_today_tall
            val hasTasksBand = layoutId == R.layout.widget_today || tall
            views.setTextViewText(R.id.today_title, m.title)
            views.setTextViewText(R.id.today_when, if (small) m.smallSub else m.whenText)
            views.setTextViewText(
                R.id.today_alarm,
                if (layoutId == R.layout.widget_today_narrow) m.narrowAlarm else m.alarmText,
            )
            views.setImageViewResource(R.id.widget_ponpon, m.mood)

            val calendar = WidgetSupport.openApp(ctx, "calendar", 20)
            views.setOnClickPendingIntent(android.R.id.background, calendar)
            views.setOnClickPendingIntent(R.id.today_event_area, calendar)
            views.setOnClickPendingIntent(R.id.today_alarm_area, WidgetSupport.openApp(ctx, "clock", 22))

            if (!small) {
                views.setOnClickPendingIntent(R.id.today_add, WidgetSupport.openApp(ctx, "add_event", 28))
            }

            if (hasTasksBand) {
                val showTasksArea = m.tasks.isNotEmpty() || m.openDueCount > 0 || m.recallDue > 0
                views.setViewVisibility(R.id.today_tasks_area, if (showTasksArea) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.today_tasks_hairline, if (showTasksArea) View.VISIBLE else View.GONE)

                if (m.tasks.isNotEmpty()) {
                    val t0 = m.tasks[0]
                    views.setViewVisibility(R.id.today_task_0, View.VISIBLE)
                    views.setTextViewText(R.id.today_task_0_title, t0.title)
                    views.setImageViewResource(
                        R.id.today_task_0_check,
                        if (t0.overdue) R.drawable.ic_widget_check_overdue else R.drawable.ic_widget_check,
                    )
                    views.setOnClickPendingIntent(R.id.today_task_0_check, completeTaskIntent(ctx, t0.id, 201))
                    views.setOnClickPendingIntent(R.id.today_task_0, WidgetSupport.openApp(ctx, "open_tasks", 203))
                } else {
                    views.setViewVisibility(R.id.today_task_0, View.GONE)
                }

                if (tall) {
                    if (m.tasks.size > 1) {
                        val t1 = m.tasks[1]
                        views.setViewVisibility(R.id.today_task_1, View.VISIBLE)
                        views.setTextViewText(R.id.today_task_1_title, t1.title)
                        views.setImageViewResource(
                            R.id.today_task_1_check,
                            if (t1.overdue) R.drawable.ic_widget_check_overdue else R.drawable.ic_widget_check,
                        )
                        views.setOnClickPendingIntent(R.id.today_task_1_check, completeTaskIntent(ctx, t1.id, 202))
                        views.setOnClickPendingIntent(R.id.today_task_1, WidgetSupport.openApp(ctx, "open_tasks", 204))
                    } else {
                        views.setViewVisibility(R.id.today_task_1, View.GONE)
                    }
                }

                val shownCount = if (tall) minOf(2, m.tasks.size) else minOf(1, m.tasks.size)
                val moreCount = maxOf(0, m.openDueCount - shownCount)
                if (moreCount > 0) {
                    views.setViewVisibility(R.id.today_tasks_more, View.VISIBLE)
                    views.setTextViewText(R.id.today_tasks_more, ctx.getString(R.string.widget_tasks_more, moreCount))
                    views.setOnClickPendingIntent(R.id.today_tasks_more, WidgetSupport.openApp(ctx, "open_tasks", 205))
                } else {
                    views.setViewVisibility(R.id.today_tasks_more, View.GONE)
                }

                if (m.recallDue > 0) {
                    views.setViewVisibility(R.id.today_recall_chip, View.VISIBLE)
                    views.setTextViewText(R.id.today_recall_chip, ctx.getString(R.string.widget_recall_chip, m.recallDue))
                    views.setOnClickPendingIntent(R.id.today_recall_chip, WidgetSupport.openApp(ctx, "open_recall", 206))
                } else {
                    views.setViewVisibility(R.id.today_recall_chip, View.GONE)
                }

                if (tall) {
                    views.setViewVisibility(
                        R.id.today_tasks_footer,
                        if (moreCount > 0 || m.recallDue > 0) View.VISIBLE else View.GONE,
                    )
                }
            }

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
