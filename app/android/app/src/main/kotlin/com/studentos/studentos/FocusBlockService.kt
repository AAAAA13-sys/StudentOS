package com.studentos.studentos

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.telecom.TelecomManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Strict lockdown. While a strict focus phase runs, opening any app that is
 * not on the allow list sends the user straight back to StudentOS. Phone
 * calls, the keyboard and the system UI always pass. It reads nothing from
 * the screen: only which app came to the front.
 */
class FocusBlockService : AccessibilityService() {
    private var lastBounce = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (!FocusStore.strictNow(this)) return
        if (pkg in alwaysAllowed() || pkg in FocusStore.allowedApps(this)) return

        val now = System.currentTimeMillis()
        if (now - lastBounce < 600) return
        lastBounce = now
        startActivity(
            Intent(this, MainActivity::class.java)
                .putExtra(MainActivity.EXTRA_ROUTE, MainActivity.ROUTE_TIMER)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                ),
        )
        val until = FocusStore.focusEnd(this)?.let {
            SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(it))
        }
        Toast.makeText(
            this,
            if (until == null) "Focus is on" else "Focus is on until $until",
            Toast.LENGTH_SHORT,
        ).show()
    }

    private fun alwaysAllowed(): Set<String> {
        val set = mutableSetOf(
            packageName,
            "android",
            "com.android.systemui",
            "com.android.server.telecom",
            "com.android.phone",
            "com.android.dialer",
            "com.google.android.dialer",
            "com.samsung.android.dialer",
            "com.android.incallui",
            "com.android.emergency",
            "com.google.android.apps.safetyhub",
            "com.android.permissioncontroller",
            "com.google.android.permissioncontroller",
        )
        try {
            val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            telecom.defaultDialerPackage?.let { set.add(it) }
        } catch (e: Exception) {}
        // The keyboard in use, so typing in StudentOS still works.
        Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?.substringBefore('/')?.let { set.add(it) }
        return set
    }

    override fun onInterrupt() {}

    companion object {
        fun isEnabled(ctx: Context): Boolean {
            val enabled = Settings.Secure.getString(
                ctx.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            val me = "${ctx.packageName}/${FocusBlockService::class.java.name}"
            val short = "${ctx.packageName}/.FocusBlockService"
            return enabled.split(':').any { it.equals(me, true) || it.equals(short, true) }
        }
    }
}
