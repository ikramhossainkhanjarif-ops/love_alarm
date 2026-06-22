import 'package:flutter/services.dart';
import '../../domain/entities/alarm_entity.dart';

/// Bridges to native Android code (Kotlin) to schedule exact, reboot-
/// surviving alarms via AlarmManager + a BroadcastReceiver, and to launch
/// the app's single Activity with full-screen / show-over-lock-screen
/// flags so the ringing UI appears even from a locked or killed state.
///
/// See android/app/src/main/kotlin/.../AlarmSchedulerPlugin.kt for the
/// native implementation.
class NativeAlarmScheduler {
  static const MethodChannel _channel =
      MethodChannel('romantic_alarm/native_alarms');

  /// Schedules (or re-schedules) the native exact alarm for [alarm].
  /// [triggerAtMillis] is the epoch millis when it should fire next.
  static Future<void> scheduleAlarm({
    required AlarmEntity alarm,
    required int triggerAtMillis,
  }) async {
    await _channel.invokeMethod('scheduleAlarm', {
      'id': alarm.id,
      'triggerAtMillis': triggerAtMillis,
      'label': alarm.label,
      'soundAssetPath': alarm.soundAssetPath,
      'vibrate': alarm.vibrate,
      'snoozeMinutes': alarm.snoozeMinutes,
      'isRepeating': !alarm.isOneTime,
      'repeatDays': alarm.repeatDays.toList(),
      'hour': alarm.hour,
      'minute': alarm.minute,
    });
  }

  static Future<void> cancelAlarm(String id) async {
    await _channel.invokeMethod('cancelAlarm', {'id': id});
  }

  /// Re-schedules every enabled alarm. Called on app start and after boot
  /// (the native BootReceiver calls back into Dart-independent native
  /// logic, but we also proactively resync from Dart on launch).
  static Future<void> rescheduleAll(List<Map<String, dynamic>> alarms) async {
    await _channel.invokeMethod('rescheduleAll', {'alarms': alarms});
  }

  /// Requests the user grant "exact alarm" permission on Android 12+ if
  /// not already granted. No-op on older versions.
  static Future<bool> ensureExactAlarmPermission() async {
    final result =
        await _channel.invokeMethod<bool>('ensureExactAlarmPermission');
    return result ?? true;
  }

  /// Requests battery-optimization exemption so the alarm reliably fires.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  /// Stops the native alarm sound/vibration (called when user dismisses or
  /// snoozes from the Flutter ringing screen).
  static Future<void> stopRinging() async {
    await _channel.invokeMethod('stopRinging');
  }

  /// Snoozes the currently ringing alarm by [minutes].
  static Future<void> snooze(String id, int minutes) async {
    await _channel.invokeMethod('snooze', {'id': id, 'minutes': minutes});
  }

  /// Listens for "alarmFired" / "snoozeFired" calls coming from native code
  /// when the app is already running in the foreground/background, so the
  /// Flutter side can navigate to the ringing screen without relying solely
  /// on the full-screen Activity intent.
  static void setAlarmFiredHandler(
    Future<void> Function(Map<String, dynamic> payload) handler,
  ) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmFired') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        await handler(args);
      }
    });
  }

  /// Reads the launch payload if the app was cold-started directly from
  /// the alarm's full-screen intent (so we know to jump straight to the
  /// ringing screen instead of the home/alarm-list screen).
  static Future<Map<String, dynamic>?> getInitialAlarmPayload() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getInitialAlarmPayload');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }
}
