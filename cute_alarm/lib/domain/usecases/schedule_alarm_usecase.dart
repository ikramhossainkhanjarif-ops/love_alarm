import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

class ScheduleAlarmUseCase {
  final AlarmRepository repository;
  ScheduleAlarmUseCase(this.repository);

  Future<void> call(AlarmEntity alarm) async {
    await repository.saveAlarm(alarm);
  }
}
