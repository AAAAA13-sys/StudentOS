package com.studentos.studentos

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Finance widget: today's safe-to-spend. Only the app can work it out, so it
 * is stamped with its day and hidden once that day is over.
 */
class FinanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val fresh = data.getString("safe_spend_date", "") == today
        val amount = if (fresh) data.getString("safe_spend_amount", "") ?: "" else ""
        val note = if (fresh) data.getString("safe_spend_note", "") ?: "" else ""
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_finance).apply {
                setTextViewText(R.id.finance_amount, amount.ifEmpty { "—" })
                setTextViewText(
                    R.id.finance_note,
                    if (amount.isEmpty()) "Open StudentOS to work out today" else note,
                )
                setViewVisibility(
                    R.id.finance_note,
                    if (amount.isEmpty() || note.isNotEmpty()) View.VISIBLE else View.GONE,
                )
                setOnClickPendingIntent(
                    R.id.finance_root,
                    WidgetSupport.openApp(context, "finance", 21),
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
