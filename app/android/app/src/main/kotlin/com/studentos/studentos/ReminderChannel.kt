package com.studentos.studentos

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/** Hands the app's upcoming event reminders to [ReminderStore]. */
class ReminderChannel(private val ctx: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, "com.studentos/reminders").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncReminders" -> {
                val list = call.argument<List<Map<String, Any?>>>("reminders") ?: emptyList()
                ReminderStore.replace(ctx, JSONArray(list.map { JSONObject(it) }))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
