import 'package:equatable/equatable.dart';
import '../../../domain/entities/alarm_entity.dart';

abstract class AlarmListEvent extends Equatable {
  const AlarmListEvent();
  @override
  List<Object?> get props => [];
}

class LoadAlarms extends AlarmListEvent {
  const LoadAlarms();
}

class SaveAlarmEvent extends AlarmListEvent {
  final AlarmEntity alarm;
  const SaveAlarmEvent(this.alarm);
  @override
  List<Object?> get props => [alarm];
}

class DeleteAlarmEvent extends AlarmListEvent {
  final String id;
  const DeleteAlarmEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleAlarmEvent extends AlarmListEvent {
  final String id;
  final bool enabled;
  const ToggleAlarmEvent(this.id, this.enabled);
  @override
  List<Object?> get props => [id, enabled];
}
