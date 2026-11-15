package com.studentos.studentos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import es.antonborri.home_widget.HomeWidgetPlugin

class CalendarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("event_title", "No upcoming events")
                val time = widgetData.getString("event_time", "Enjoy your free time!")
                setTextViewText(R.id.widget_event_title, title)
                setTextViewText(R.id.widget_event_time, time)

                // The figure is for one day only; yesterday's must not be shown.
                val safeSpendDay = widgetData.getString("safe_spend_date", "")
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val isToday = safeSpendDay == today
                val safeSpend =
                    if (isToday) widgetData.getString("safe_spend", "") ?: "" else ""
                setTextViewText(R.id.widget_safe_spend, safeSpend)
                setViewVisibility(
                    R.id.widget_safe_spend,
                    if (safeSpend.isEmpty()) View.GONE else View.VISIBLE
                )

                val pendingIntent = Intent(context, MainActivity::class.java).let { intent ->
                    intent.action = "OPEN_CALENDAR"
                    PendingIntent.getActivity(
                        context,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                }
                setOnClickPendingIntent(R.id.widget_layout_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
