package com.romantic.alarm.romantic_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

/**
 * Central place for arming/disarming AlarmManager exact alarms. Used both
 * from the Flutter-facing MethodChannel handler ([AlarmSchedulerPlugin])
 * and from [BootReceiver], so scheduling logic only lives in one spot.
 */
object AlarmScheduler {

    /** Stable per-alarm request code derived from its string ID. */
    private fun requestCodeFor(id: String): Int = id.hashCode()

    private fun pendingIntentFor(context: Context, alarm: NativeAlarmData): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_FIRED
            putExtra(AlarmReceiver.EXTRA_ALARM_JSON, alarm.toJson().toString())
        }
        return PendingIntent.getBroadcast(
            context,
            requestCodeFor(alarm.id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * Schedules (or re-schedules) an exact alarm for [alarm], persisting it
     * in [NativeAlarmStore] so it survives process death and can be
     * re-armed by [BootReceiver] after a reboot.
     */
    fun schedule(context: Context, alarm: NativeAlarmData) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = nextValidTrigger(alarm)
        val updated = alarm.copy(triggerAtMillis = triggerAt)
        val pendingIntent = pendingIntentFor(context, updated)

        armExact(alarmManager, triggerAt, pendingIntent)

        NativeAlarmStore(context).saveAlarm(updated)
    }

    /**
     * Arms a one-shot snooze alarm [minutes] from now. Does NOT update the
     * persisted "next normal occurrence" record, so a reboot mid-snooze
     * falls back correctly to the regular schedule instead of re-arming a
     * stale snooze time in the past.
     */
    fun scheduleSnooze(context: Context, alarm: NativeAlarmData, minutes: Int) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val snoozeTrigger = System.currentTimeMillis() + minutes * 60_000L
        val snoozed = alarm.copy(triggerAtMillis = snoozeTrigger)
        val pendingIntent = pendingIntentFor(context, snoozed)

        armExact(alarmManager, snoozeTrigger, pendingIntent)
    }

    fun cancel(context: Context, id: String) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_FIRED
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCodeFor(id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        NativeAlarmStore(context).removeAlarm(id)
    }

    /**
     * Re-arms every alarm currently in [NativeAlarmStore]. Called by
     * [BootReceiver] after device boot / app update, entirely without
     * needing the Flutter engine to start.
     */
    fun rescheduleAllFromStore(context: Context) {
        val store = NativeAlarmStore(context)
        store.loadAll().values.forEach { alarm ->
            schedule(context, alarm)
        }
    }

    private fun armExact(
        alarmManager: AlarmManager,
        triggerAt: Long,
        pendingIntent: PendingIntent
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent
                    )
                } else {
                    // Permission not granted; fall back to inexact rather
                    // than silently doing nothing. The Dart side proactively
                    // requests the exact-alarm permission on startup.
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent
                )
            }
        } catch (e: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    /**
     * Computes the next valid trigger time for [alarm], honoring its
     * repeat-days set. Recomputed natively (rather than trusting whatever
     * stale `triggerAtMillis` was persisted) so re-arming after a reboot
     * or long device-off period is always correct.
     */
    private fun nextValidTrigger(alarm: NativeAlarmData): Long {
        val now = Calendar.getInstance()
        val candidate = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, alarm.hour)
            set(Calendar.MINUTE, alarm.minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (alarm.repeatDays.isEmpty()) {
            // One-time alarm.
            if (candidate.before(now) || candidate == now) {
                candidate.add(Calendar.DAY_OF_MONTH, 1)
            }
            return candidate.timeInMillis
        }

        // Repeating alarm: find the next matching ISO weekday (1=Mon..7=Sun)
        // on/after today whose time hasn't already passed.
        for (offset in 0..7) {
            val day = candidate.clone() as Calendar
            day.add(Calendar.DAY_OF_MONTH, offset)
            val isoWeekday = isoWeekdayOf(day)
            if (alarm.repeatDays.contains(isoWeekday) && day.after(now)) {
                return day.timeInMillis
            }
        }
        // Fallback (shouldn't be reached given the 0..7 sweep above).
        candidate.add(Calendar.DAY_OF_MONTH, 1)
        return candidate.timeInMillis
    }

    private fun isoWeekdayOf(cal: Calendar): Int {
        // Calendar.DAY_OF_WEEK: Sunday=1 ... Saturday=7
        // ISO-8601 we want: Monday=1 ... Sunday=7
        val javaDay = cal.get(Calendar.DAY_OF_WEEK)
        return if (javaDay == Calendar.SUNDAY) 7 else javaDay - 1
    }
}
