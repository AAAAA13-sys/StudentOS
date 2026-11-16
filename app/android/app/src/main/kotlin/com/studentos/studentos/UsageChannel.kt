package com.studentos.studentos

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Reads this phone's own usage history for the Phone tab. Nothing leaves the
 * device: results go straight back to Dart, which stores daily totals.
 */
class UsageChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.studentos/usage")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(hasUsageAccess())
            "openUsageAccessSettings" -> result.success(openSettings())
            "queryRange" -> {
                val start = call.argument<Number>("startMs")?.toLong()
                val end = call.argument<Number>("endMs")?.toLong()
                if (start == null || end == null || end <= start) {
                    result.error("bad_args", "startMs and endMs are required", null)
                    return
                }
                worker.execute {
                    val data = try {
                        queryRange(start, end)
                    } catch (e: Exception) {
                        null
                    }
                    main.post { result.success(data) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun hasUsageAccess(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        @Suppress("DEPRECATION")
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openSettings(): Boolean {
        val withPackage = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            .setData(Uri.parse("package:${context.packageName}"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val plain = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        for (intent in listOf(withPackage, plain)) {
            try {
                context.startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Try the next form; some phones do not accept the package.
            }
        }
        return false
    }

    /**
     * Per-app foreground time, screen-on spans and unlock times between
     * [start] and [end]. Null while the phone is locked (the system refuses).
     */
    private fun queryRange(start: Long, end: Long): Map<String, Any>? {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val until = minOf(end, now)
        if (until <= start) return mapOf("apps" to emptyList<Any>(), "screenOn" to emptyList<Any>(), "unlocks" to emptyList<Any>(), "events" to 0)
        // Look back a little so an app or screen already on at [start] counts.
        val events = usm.queryEvents(start - LOOKBACK_MS, until) ?: return null
        val skip = skippedPackages()

        val appMs = HashMap<String, Long>()
        val spans = ArrayList<List<Long>>()
        val unlocks = ArrayList<Long>()
        var openPkg: String? = null
        var openAt = 0L
        var screenOnAt: Long? = null
        var screenStateKnown = false
        var counted = 0
        val e = UsageEvents.Event()

        fun clip(from: Long, to: Long): Long = maxOf(0L, minOf(to, until) - maxOf(from, start))

        fun closeApp(at: Long) {
            val pkg = openPkg ?: return
            if (pkg !in skip) appMs[pkg] = (appMs[pkg] ?: 0L) + clip(openAt, at)
            openPkg = null
        }

        fun closeScreen(at: Long) {
            val from = screenOnAt ?: if (!screenStateKnown) start else null
            if (from != null && at > start) {
                spans.add(listOf(maxOf(from, start), minOf(at, until)))
            }
            screenOnAt = null
            screenStateKnown = true
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.timeStamp >= start) counted++
            when (e.eventType) {
                RESUMED -> if (openPkg != e.packageName) {
                    closeApp(e.timeStamp)
                    openPkg = e.packageName
                    openAt = e.timeStamp
                }
                PAUSED -> if (e.packageName == openPkg) closeApp(e.timeStamp)
                SCREEN_ON -> {
                    screenOnAt = e.timeStamp
                    screenStateKnown = true
                }
                SCREEN_OFF -> {
                    closeApp(e.timeStamp)
                    closeScreen(e.timeStamp)
                }
                SHUTDOWN -> {
                    closeApp(e.timeStamp)
                    if (screenOnAt != null) closeScreen(e.timeStamp)
                }
                UNLOCKED -> if (e.timeStamp >= start) unlocks.add(e.timeStamp)
            }
        }
        // Still in use at the end of the range (for today: right now).
        closeApp(until)
        if (screenOnAt != null) closeScreen(until)

        val pm = context.packageManager
        val apps = appMs.filterValues { it >= 1000L }.map { (pkg, ms) ->
            mapOf("package" to pkg, "label" to labelFor(pm, pkg), "ms" to ms)
        }
        return mapOf(
            "apps" to apps,
            "screenOn" to spans,
            "unlocks" to unlocks,
            "events" to counted,
        )
    }

    /** The launcher, the system UI and this app are not "phone time". */
    private fun skippedPackages(): Set<String> {
        val skip = mutableSetOf(context.packageName, "com.android.systemui")
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        context.packageManager.resolveActivity(home, PackageManager.MATCH_DEFAULT_ONLY)
            ?.activityInfo?.packageName?.let { skip.add(it) }
        return skip
    }

    private fun labelFor(pm: PackageManager, pkg: String): String = try {
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    } catch (e: PackageManager.NameNotFoundException) {
        pkg
    }

    companion object {
        private const val LOOKBACK_MS = 3L * 60 * 60 * 1000
        // UsageEvents.Event constants; the screen and keyguard ones are API 28+
        // and simply never appear on older phones.
        private const val RESUMED = 1
        private const val PAUSED = 2
        private const val SCREEN_ON = 15
        private const val SCREEN_OFF = 16
        private const val UNLOCKED = 18
        private const val SHUTDOWN = 26
    }
}
