import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

class GetAlarmsUseCase {
  final AlarmRepository repository;
  GetAlarmsUseCase(this.repository);

  Future<List<AlarmEntity>> call() => repository.getAlarms();
}
