package com.studentos.studentos

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Calendar
import java.util.Locale

/** Shared by the two home-screen widgets (Today and Money). */
object WidgetSupport {
    const val ACTION_TICK = "com.studentos.studentos.WIDGET_TICK"

    /** Opens StudentOS at [route] (see `openRoute` handling in Dart). */
    fun openApp(ctx: Context, route: String, requestCode: Int): PendingIntent =
        PendingIntent.getActivity(
            ctx,
            requestCode,
            Intent(ctx, MainActivity::class.java)
                .putExtra(MainActivity.EXTRA_ROUTE, route)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Redraws every placed copy of the widget [provider], if any. */
    fun refresh(ctx: Context, provider: Class<*>) {
        val manager = AppWidgetManager.getInstance(ctx)
        val ids = manager.getAppWidgetIds(ComponentName(ctx, provider))
        if (ids.isEmpty()) return
        ctx.sendBroadcast(
            Intent(ctx, provider)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
        )
    }

    /**
     * The views for one placed widget. Android 12+ picks among [sizes] itself
     * as the widget is resized; older versions get the layout [legacyPick]
     * chooses from the current size options (min width, max height, in dp).
     */
    fun sized(
        manager: AppWidgetManager,
        appWidgetId: Int,
        sizes: Map<SizeF, Int>,
        legacyPick: (minWidthDp: Int, maxHeightDp: Int) -> Int,
        build: (layoutId: Int) -> RemoteViews,
    ): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(sizes.mapValues { build(it.value) })
        }
        val o = manager.getAppWidgetOptions(appWidgetId)
        return build(
            legacyPick(
                o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0),
                o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0),
            ),
        )
    }

    /** True before Android 12, where a resize needs an explicit redraw. */
    fun resizedLegacy(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.S

    /** Asks [provider] to redraw at [atMillis] (inexact, no permission needed). */
    fun scheduleTick(ctx: Context, provider: Class<*>, requestCode: Int, atMillis: Long) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.set(AlarmManager.RTC, atMillis, tickIntent(ctx, provider, requestCode))
    }

    fun cancelTick(ctx: Context, provider: Class<*>, requestCode: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(tickIntent(ctx, provider, requestCode))
    }

    private fun tickIntent(ctx: Context, provider: Class<*>, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            ctx,
            requestCode,
            Intent(ctx, provider).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Start of the next local day, plus a second. */
    fun nextMidnight(now: Long): Long {
        val c = Calendar.getInstance()
        c.timeInMillis = now
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 1)
        c.set(Calendar.MILLISECOND, 0)
        c.add(Calendar.DAY_OF_YEAR, 1)
        return c.timeInMillis
    }

    /** "P1,830" or "P120.50" with the peso sign; the minus is left to the caller. */
    fun peso(cents: Long): String {
        val abs = Math.abs(cents)
        val whole = NumberFormat.getIntegerInstance(Locale.US).format(abs / 100)
        val frac = abs % 100
        val sign = "₱"
        return if (frac == 0L) "$sign$whole" else "$sign$whole.${frac.toString().padStart(2, '0')}"
    }
}
