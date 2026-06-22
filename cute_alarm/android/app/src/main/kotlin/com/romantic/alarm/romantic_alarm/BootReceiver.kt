package com.romantic.alarm.romantic_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-schedules every previously-armed alarm after the device reboots (or
 * after this app is updated, which also clears AlarmManager state). Reads
 * directly from [NativeAlarmStore], so this works even before the user
 * ever opens the app again — true "survives reboot" behavior.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            AlarmScheduler.rescheduleAllFromStore(context)
        }
    }
}
