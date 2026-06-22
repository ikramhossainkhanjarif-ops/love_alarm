import '../repositories/alarm_repository.dart';

class DeleteAlarmUseCase {
  final AlarmRepository repository;
  DeleteAlarmUseCase(this.repository);

  Future<void> call(String id) => repository.deleteAlarm(id);
}
