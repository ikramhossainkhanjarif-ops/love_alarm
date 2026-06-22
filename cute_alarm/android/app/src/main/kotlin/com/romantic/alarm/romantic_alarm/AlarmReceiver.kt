package com.romantic.alarm.romantic_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import org.json.JSONObject

/**
 * Fired by [android.app.AlarmManager] at the scheduled time. Runs entirely
 * independently of the Flutter engine / Dart VM (which may not even be
 * alive), so all data needed comes from the broadcast's extras, originally
 * sourced from [NativeAlarmStore].
 *
 * Responsibilities:
 *  1. Re-arm the next occurrence immediately if the alarm repeats.
 *  2. Start the foreground [AlarmRingingService] to play sound/vibration
 *     reliably (this works even before any Activity is shown).
 *  3. Launch [MainActivity] with flags that make it appear as a
 *     full-screen experience even over the lock screen or after the app
 *     process was killed.
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_ALARM_FIRED = "com.romantic.alarm.romantic_alarm.ACTION_ALARM_FIRED"
        const val EXTRA_ALARM_JSON = "extra_alarm_json"
        const val EXTRA_ALARM_ID = "extra_alarm_id"
        const val EXTRA_SNOOZE_MINUTES = "extra_snooze_minutes"
        const val EXTRA_VIBRATE = "extra_vibrate"
        const val EXTRA_LABEL = "extra_label"
        const val EXTRA_SOUND_ASSET_PATH = "extra_sound_asset_path"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val json = intent.getStringExtra(EXTRA_ALARM_JSON) ?: return
        val alarm = try {
            NativeAlarmData.fromJson(JSONObject(json))
        } catch (e: Exception) {
            return
        }

        // Re-arm the next occurrence right away for repeating alarms, so
        // the cycle continues even if Dart never gets a chance to resync.
        if (alarm.isRepeating && alarm.repeatDays.isNotEmpty()) {
            AlarmScheduler.schedule(context, alarm)
        } else {
            // One-time alarm: it has fired, so remove it from the native
            // store (Dart's own alarm list still has the record and will
            // reflect "isEnabled = false" the next time it loads, via the
            // normal Flutter-side flow when the user interacts with it).
            NativeAlarmStore(context).removeAlarm(alarm.id)
        }

        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            putExtra(EXTRA_ALARM_ID, alarm.id)
            putExtra(EXTRA_SNOOZE_MINUTES, alarm.snoozeMinutes)
            putExtra(EXTRA_VIBRATE, alarm.vibrate)
            putExtra(EXTRA_LABEL, alarm.label)
            putExtra(EXTRA_SOUND_ASSET_PATH, alarm.soundAssetPath)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(context, serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        val activityIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            putExtra(EXTRA_ALARM_ID, alarm.id)
            putExtra(EXTRA_SNOOZE_MINUTES, alarm.snoozeMinutes)
            putExtra(MainActivity.EXTRA_LAUNCHED_FROM_ALARM, true)
        }
        context.startActivity(activityIntent)
    }
}
