package com.studentos.studentos

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Money widget: spent today and what is left this month. The app writes the
 * `money_*` keys on every change; they are stamped with their day and month
 * so a stale figure is never shown as today's. No network.
 */
class FinanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val model = MoneyModel.load(context)
        for (appWidgetId in appWidgetIds) {
            val views = WidgetSupport.sized(
                appWidgetManager, appWidgetId, SIZES,
                legacyPick = { _, maxH ->
                    if (maxH in 1..99) R.layout.widget_money_small else R.layout.widget_money
                },
            ) { layout -> buildViews(context, layout, model) }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        WidgetSupport.scheduleTick(
            context, FinanceWidgetProvider::class.java, TICK_CODE,
            WidgetSupport.nextMidnight(System.currentTimeMillis()),
        )
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        if (WidgetSupport.resizedLegacy()) onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == WidgetSupport.ACTION_TICK) {
            WidgetSupport.refresh(context, FinanceWidgetProvider::class.java)
        } else {
            super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        WidgetSupport.cancelTick(context, FinanceWidgetProvider::class.java, TICK_CODE)
    }

    private class MoneyModel(
        val spentCents: Long,
        /** Null when the stored month is not this month. */
        val balanceCents: Long?,
    ) {
        companion object {
            fun load(ctx: Context): MoneyModel {
                val data = HomeWidgetPlugin.getData(ctx)
                val now = Date()
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now)
                val month = SimpleDateFormat("yyyy-MM", Locale.US).format(now)
                fun cents(key: String): Long = when (val v = data.all[key]) {
                    is Number -> v.toLong()
                    is String -> v.toLongOrNull() ?: 0L
                    else -> 0L
                }
                val spent = if (data.getString("money_day", null) == today) cents("money_spent_today") else 0L
                val balance =
                    if (data.getString("money_month", null) == month) cents("money_month_balance") else null
                return MoneyModel(spent, balance)
            }
        }
    }

    companion object {
        private const val TICK_CODE = 27

        private val SIZES = linkedMapOf(
            SizeF(110f, 50f) to R.layout.widget_money_small,
            SizeF(180f, 110f) to R.layout.widget_money,
        )

        private fun buildViews(ctx: Context, layoutId: Int, m: MoneyModel): RemoteViews {
            val views = RemoteViews(ctx.packageName, layoutId)
            val small = layoutId == R.layout.widget_money_small
            views.setTextViewText(R.id.money_amount, WidgetSupport.peso(m.spentCents))

            val balance = m.balanceCents
            val negative = balance != null && balance < 0
            val line = when {
                balance == null ->
                    ctx.getString(if (small) R.string.widget_short_new else R.string.widget_month_new)
                negative -> ctx.getString(
                    if (small) R.string.widget_short_over else R.string.widget_month_over,
                    WidgetSupport.peso(balance),
                )
                else -> ctx.getString(
                    if (small) R.string.widget_short_left else R.string.widget_month_left,
                    WidgetSupport.peso(balance),
                )
            }
            // Two views per layout, one per colour, so each follows light and
            // dark mode through the layout's own colour resources.
            views.setTextViewText(R.id.money_month_pos, line)
            views.setTextViewText(R.id.money_month_neg, line)
            views.setViewVisibility(R.id.money_month_pos, if (negative) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.money_month_neg, if (negative) View.VISIBLE else View.GONE)
            views.setImageViewResource(
                R.id.widget_ponpon,
                if (negative) R.drawable.ponpon_smug else R.drawable.ponpon_happy,
            )
            views.setOnClickPendingIntent(android.R.id.background, WidgetSupport.openApp(ctx, "finance", 21))
            return views
        }
    }
}
