package com.studentos.studentos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/** Shared by the three home-screen widgets (Calendar, Finance, Clock). */
object WidgetSupport {
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
}
