import 'package:equatable/equatable.dart';
import '../../../domain/entities/alarm_entity.dart';

abstract class AlarmListState extends Equatable {
  const AlarmListState();
  @override
  List<Object?> get props => [];
}

class AlarmListLoading extends AlarmListState {
  const AlarmListLoading();
}

class AlarmListLoaded extends AlarmListState {
  final List<AlarmEntity> alarms;
  const AlarmListLoaded(this.alarms);
  @override
  List<Object?> get props => [alarms];
}

class AlarmListError extends AlarmListState {
  final String message;
  const AlarmListError(this.message);
  @override
  List<Object?> get props => [message];
}
