import '../repositories/alarm_repository.dart';

class ToggleAlarmUseCase {
  final AlarmRepository repository;
  ToggleAlarmUseCase(this.repository);

  Future<void> call(String id, bool enabled) =>
      repository.setEnabled(id, enabled);
}
