import '../../domain/entities/alarm_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_datasource.dart';
import '../datasources/native_alarm_scheduler.dart';
import '../models/alarm_model.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDataSource localDataSource;

  AlarmRepositoryImpl(this.localDataSource);

  @override
  Future<List<AlarmEntity>> getAlarms() async {
    final models = await localDataSource.loadAlarms();
    // Keep most-recently-created first for a nicer list ordering... but
    // actually nicer UX is sorted by time-of-day. We sort by hour/minute.
    models.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return models;
  }

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {
    final alarms = await localDataSource.loadAlarms();
    final model = AlarmModel.fromEntity(alarm);
    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      alarms[idx] = model;
    } else {
      alarms.add(model);
    }
    await localDataSource.saveAlarms(alarms);
    await _syncNative(model);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    final alarms = await localDataSource.loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await localDataSource.saveAlarms(alarms);
    await NativeAlarmScheduler.cancelAlarm(id);
  }

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    final alarms = await localDataSource.loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final updated = AlarmModel.fromEntity(
      alarms[idx].copyWith(isEnabled: enabled),
    );
    alarms[idx] = updated;
    await localDataSource.saveAlarms(alarms);

    if (enabled) {
      await _syncNative(updated);
    } else {
      await NativeAlarmScheduler.cancelAlarm(id);
    }
  }

  Future<void> _syncNative(AlarmModel model) async {
    if (!model.isEnabled) {
      await NativeAlarmScheduler.cancelAlarm(model.id);
      return;
    }
    final next = model.nextTrigger(DateTime.now());
    await NativeAlarmScheduler.scheduleAlarm(
      alarm: model,
      triggerAtMillis: next.millisecondsSinceEpoch,
    );
  }

  /// Re-syncs every enabled alarm with the native scheduler. Call this on
  /// app startup to recover from edge cases (e.g. reboot edge cases not
  /// fully covered by the native BootReceiver, or app updates that clear
  /// scheduled alarms).
  Future<void> resyncAllWithNative() async {
    final alarms = await localDataSource.loadAlarms();
    for (final alarm in alarms.where((a) => a.isEnabled)) {
      await _syncNative(alarm);
    }
  }
}
