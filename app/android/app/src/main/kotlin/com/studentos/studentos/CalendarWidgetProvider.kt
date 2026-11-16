package com.studentos.studentos

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/** Calendar widget: the next event. Written by the app on every change. */
class CalendarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                setTextViewText(
                    R.id.widget_event_title,
                    data.getString("event_title", "No upcoming events"),
                )
                setTextViewText(
                    R.id.widget_event_time,
                    data.getString("event_time", "Enjoy your free time!"),
                )
                val title = data.getString("event_title", null)
                setImageViewResource(
                    R.id.widget_ponpon,
                    if (title == null || title == "No upcoming events") R.drawable.ponpon_sleepy
                    else R.drawable.ponpon_happy,
                )
                setOnClickPendingIntent(
                    R.id.widget_layout_root,
                    WidgetSupport.openApp(context, "calendar", 20),
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
