package com.romantic.alarm.romantic_alarm

import android.app.AlarmManager
import android.app.Application
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Implements the Dart-side `romantic_alarm/native_alarms` MethodChannel
 * (see lib/data/datasources/native_alarm_scheduler.dart). Bridges:
 *  - scheduling / cancelling exact alarms (delegates to [AlarmScheduler])
 *  - exact-alarm + battery-optimization permission requests
 *  - stopping the ringing sound/vibration ([AlarmRingingService])
 *  - snoozing
 *  - reading the "cold start from alarm" payload, if any
 */
class AlarmSchedulerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null
    private var activityBinding: ActivityPluginBinding? = null

    companion object {
        const val CHANNEL_NAME = "romantic_alarm/native_alarms"
        private const val EXTRA_FROM_ALARM = "extra_from_alarm_intent"

        /**
         * Holds the most recent "launched from alarm" intent extras so
         * Dart's `getInitialAlarmPayload()` can retrieve them once, even
         * if the MethodChannel wasn't fully wired up at the exact moment
         * the Activity launched.
         */
        @Volatile
        private var pendingInitialPayload: Map<String, Any?>? = null

        fun attachInitialPayloadFromIntent(intent: Intent?) {
            val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
            if (alarmId != null) {
                val snoozeMinutes =
                    intent.getIntExtra(AlarmReceiver.EXTRA_SNOOZE_MINUTES, 5)
                pendingInitialPayload = mapOf(
                    "id" to alarmId,
                    "snoozeMinutes" to snoozeMinutes
                )
            }
        }

        /**
         * Holds a reference to the live channel instance (if any) so
         * [MainActivity.onNewIntent] can actively push an "onAlarmFired"
         * call to Dart when the app is already running and a new alarm
         * fires — rather than relying solely on the one-shot
         * `getInitialAlarmPayload()` pull, which only covers cold starts.
         */
        @Volatile
        private var activeChannel: MethodChannel? = null

        fun notifyAlarmFiredIfEngineReady(intent: Intent?) {
            val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID) ?: return
            val snoozeMinutes = intent.getIntExtra(AlarmReceiver.EXTRA_SNOOZE_MINUTES, 5)
            activeChannel?.invokeMethod(
                "onAlarmFired",
                mapOf("id" to alarmId, "snoozeMinutes" to snoozeMinutes)
            )
        }
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        activeChannel = channel
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
        activeChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        attachInitialPayloadFromIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context unavailable", null)
            return
        }

        when (call.method) {
            "scheduleAlarm" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("BAD_ARGS", "Missing arguments", null)
                    return
                }
                val data = NativeAlarmData.fromMethodCallArgs(args)
                AlarmScheduler.schedule(context, data)
                result.success(null)
            }

            "cancelAlarm" -> {
                val id = (call.arguments as? Map<*, *>)?.get("id") as? String
                if (id != null) AlarmScheduler.cancel(context, id)
                result.success(null)
            }

            "rescheduleAll" -> {
                @Suppress("UNCHECKED_CAST")
                val alarms = (call.arguments as? Map<*, *>)?.get("alarms") as? List<Map<*, *>>
                alarms?.forEach { map ->
                    val data = NativeAlarmData.fromMethodCallArgs(map)
                    AlarmScheduler.schedule(context, data)
                }
                result.success(null)
            }

            "ensureExactAlarmPermission" -> {
                result.success(ensureExactAlarmPermission(context))
            }

            "requestIgnoreBatteryOptimizations" -> {
                requestIgnoreBatteryOptimizations(context)
                result.success(null)
            }

            "stopRinging" -> {
                val stopIntent = Intent(context, AlarmRingingService::class.java).apply {
                    action = AlarmRingingService.ACTION_STOP
                }
                context.startService(stopIntent)
                result.success(null)
            }

            "snooze" -> {
                val args = call.arguments as? Map<*, *>
                val id = args?.get("id") as? String
                val minutes = (args?.get("minutes") as? Number)?.toInt() ?: 5

                val stopIntent = Intent(context, AlarmRingingService::class.java).apply {
                    action = AlarmRingingService.ACTION_STOP
                }
                context.startService(stopIntent)

                if (id != null) {
                    val stored = NativeAlarmStore(context).getAlarm(id)
                    val alarmData = stored ?: NativeAlarmData(
                        id = id,
                        hour = 0,
                        minute = 0,
                        label = "",
                        soundAssetPath = "assets/sounds/alarm_sound.mp3",
                        vibrate = true,
                        snoozeMinutes = minutes,
                        isRepeating = false,
                        repeatDays = emptyList(),
                        triggerAtMillis = 0L
                    )
                    AlarmScheduler.scheduleSnooze(context, alarmData, minutes)
                }
                result.success(null)
            }

            "getInitialAlarmPayload" -> {
                val payload = pendingInitialPayload
                pendingInitialPayload = null // consume once
                result.success(payload)
            }

            else -> result.notImplemented()
        }
    }

    private fun ensureExactAlarmPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (alarmManager.canScheduleExactAlarms()) return true

        try {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${context.packageName}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            // Some OEMs / emulators may not have this settings screen.
        }
        return false
    }

    private fun requestIgnoreBatteryOptimizations(context: Context) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isIgnoringBatteryOptimizations(context.packageName)) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            } catch (e: Exception) {
                // No-op if unsupported.
            }
        }
    }
}
