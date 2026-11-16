package com.studentos.studentos

import android.Manifest
import android.app.ActivityManager
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/** The Focus tab's bridge to Android: alarms, phone settings and lockdown. */
class FocusChannel(private val activity: MainActivity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.studentos/focus")
    private val ctx: Context get() = activity.applicationContext
    private var pendingSound: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncAlarms" -> {
                val list = call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()
                AlarmStore.replace(ctx, JSONArray(list.map { JSONObject(it) }))
                result.success(null)
            }
            "takeFiredOnce" -> result.success(AlarmStore.takeFiredOnce(ctx))
            "testAlarm" -> {
                val alarm = call.argument<Map<String, Any?>>("alarm")
                if (alarm == null) return result.error("bad_args", "alarm is required", null)
                val o = JSONObject(alarm).put("id", AlarmStore.TEST_ID)
                val intent = Intent(ctx, AlarmService::class.java)
                    .setAction(AlarmService.ACTION_START)
                    .putExtra(AlarmService.EXTRA_ALARM, o.toString())
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ctx.startForegroundService(intent)
                else ctx.startService(intent)
                result.success(null)
            }
            "pickSound" -> pickSound(call.argument<String>("current"), result)
            "readiness" -> result.success(readiness())
            "openSetting" -> {
                openSetting(call.argument<String>("which") ?: "")
                result.success(null)
            }
            "startFocus" -> {
                val session = call.argument<Map<String, Any?>>("session")
                if (session == null) return result.error("bad_args", "session is required", null)
                FocusStore.start(ctx, JSONObject(session))
                result.success(null)
            }
            "stopFocus" -> {
                FocusStore.stop(ctx)
                result.success(null)
            }
            "setPinned" -> {
                setPinned(call.argument<Boolean>("pinned") == true)
                result.success(null)
            }
            "launchableApps" -> result.success(launchableApps())
            "takeRoute" -> result.success(activity.takeRoute())
            "pinWidget" -> result.success(pinWidget(call.argument<String>("which") ?: ""))
            else -> result.notImplemented()
        }
    }

    /** Asks Dart to open the screen Android wants (see [MainActivity]). */
    fun pushRoute() {
        channel.invokeMethod("openRoute", null)
    }

    // Sound picker.

    private fun pickSound(current: String?, result: MethodChannel.Result) {
        pendingSound?.success(null)
        pendingSound = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
            .putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_RINGTONE)
            .putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Alarm sound")
            .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            .putExtra(
                RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                current?.let { Uri.parse(it) } ?: Settings.System.DEFAULT_ALARM_ALERT_URI,
            )
        try {
            activity.startActivityForResult(intent, REQUEST_SOUND)
        } catch (e: ActivityNotFoundException) {
            pendingSound = null
            result.success(null)
        }
    }

    /** Called from [MainActivity.onActivityResult]. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SOUND) return false
        val result = pendingSound ?: return true
        pendingSound = null
        if (resultCode != android.app.Activity.RESULT_OK || data == null) {
            result.success(null)
            return true
        }
        @Suppress("DEPRECATION")
        val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null || uri == Settings.System.DEFAULT_ALARM_ALERT_URI) {
            result.success(mapOf("uri" to "", "name" to "Phone's alarm sound"))
            return true
        }
        val name = try {
            RingtoneManager.getRingtone(ctx, uri)?.getTitle(ctx) ?: "Alarm sound"
        } catch (e: Exception) { "Alarm sound" }
        result.success(mapOf("uri" to uri.toString(), "name" to name))
        return true
    }

    // Phone settings.

    private fun readiness(): Map<String, Boolean> {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "notifications" to nm.areNotificationsEnabled(),
            "exactAlarms" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()),
            "fullScreen" to (Build.VERSION.SDK_INT < 34 || nm.canUseFullScreenIntent()),
            "battery" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                pm.isIgnoringBatteryOptimizations(ctx.packageName)),
            "overlay" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(ctx)),
            "accessibility" to FocusBlockService.isEnabled(ctx),
        )
    }

    private fun openSetting(which: String) {
        val pkg = Uri.parse("package:${ctx.packageName}")
        if (which == "notifications" && Build.VERSION.SDK_INT >= 33 &&
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            // Asks in place first; Settings is the fallback once it was refused.
            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFY)
            return
        }
        val intent = when (which) {
            "notifications" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName)
            } else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
            "exactAlarms" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, pkg)
            } else null
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) {
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, pkg)
            } else null
            "batteryUnrestricted" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                @Suppress("BatteryLife")
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, pkg)
            } else null
            "overlay" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkg)
            } else null
            "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            "appInfo" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
            else -> null
        } ?: return
        try {
            activity.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            try {
                activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg))
            } catch (e: ActivityNotFoundException) {}
        }
    }

    // Light lockdown.

    private fun setPinned(pinned: Boolean) {
        val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val inLockTask = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            @Suppress("DEPRECATION")
            am.isInLockTaskMode
        }
        try {
            if (pinned && !inLockTask) activity.startLockTask()
            if (!pinned && inLockTask) activity.stopLockTask()
        } catch (e: Exception) {
            // Pinning turned off on this phone, or not in the foreground.
        }
    }

    private fun launchableApps(): List<Map<String, String>> {
        val pm = ctx.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val found = pm.queryIntentActivities(launcher, 0)
        return found.map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { it.first != ctx.packageName }
            .distinctBy { it.first }
            .map { mapOf("package" to it.first, "label" to it.second) }
    }

    /** Android 8+: the launcher shows its own "Add to home screen" prompt. */
    private fun pinWidget(which: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val provider = when (which) {
            "calendar" -> CalendarWidgetProvider::class.java
            "finance" -> FinanceWidgetProvider::class.java
            "clock" -> ClockWidgetProvider::class.java
            else -> return false
        }
        val manager = android.appwidget.AppWidgetManager.getInstance(ctx)
        if (!manager.isRequestPinAppWidgetSupported) return false
        return manager.requestPinAppWidget(android.content.ComponentName(ctx, provider), null, null)
    }

    companion object {
        const val REQUEST_SOUND = 4601
        const val REQUEST_NOTIFY = 4602
    }
}
