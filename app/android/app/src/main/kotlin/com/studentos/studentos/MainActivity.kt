package com.studentos.studentos

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var focus: FocusChannel? = null
    private var route: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        UsageChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        focus = FocusChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        remember(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        remember(intent)
        // Already open: tell Dart now instead of waiting for the next resume.
        if (route != null) focus?.pushRoute()
    }

    private fun remember(intent: Intent?) {
        intent?.getStringExtra(EXTRA_ROUTE)?.let { route = it }
        if (intent?.getBooleanExtra(EXTRA_UNPIN_FOR_ALARM, false) == true) {
            intent.removeExtra(EXTRA_UNPIN_FOR_ALARM)
            // An alarm is ringing while light lockdown pins the app: unpin so
            // the alarm screen can show, then open it.
            try { stopLockTask() } catch (e: Exception) {}
            startActivity(
                Intent(this, AlarmActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    /** The screen Android asked for (e.g. Focus after a blocked app), once. */
    fun takeRoute(): String? = route.also { route = null }

    @Deprecated("Needed for the sound picker's result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (focus?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    companion object {
        const val EXTRA_ROUTE = "studentos_route"
        const val EXTRA_UNPIN_FOR_ALARM = "studentos_unpin_for_alarm"

        /** Opens the focus timer; Dart maps it to the tab and panel. */
        const val ROUTE_TIMER = "timer"
    }
}
