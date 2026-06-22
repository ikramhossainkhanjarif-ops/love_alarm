import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_alarms_usecase.dart';
import '../../../domain/usecases/schedule_alarm_usecase.dart';
import '../../../domain/usecases/delete_alarm_usecase.dart';
import '../../../domain/usecases/toggle_alarm_usecase.dart';
import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  final GetAlarmsUseCase getAlarmsUseCase;
  final ScheduleAlarmUseCase scheduleAlarmUseCase;
  final DeleteAlarmUseCase deleteAlarmUseCase;
  final ToggleAlarmUseCase toggleAlarmUseCase;

  AlarmListBloc({
    required this.getAlarmsUseCase,
    required this.scheduleAlarmUseCase,
    required this.deleteAlarmUseCase,
    required this.toggleAlarmUseCase,
  }) : super(const AlarmListLoading()) {
    on<LoadAlarms>(_onLoad);
    on<SaveAlarmEvent>(_onSave);
    on<DeleteAlarmEvent>(_onDelete);
    on<ToggleAlarmEvent>(_onToggle);
  }

  Future<void> _onLoad(LoadAlarms event, Emitter<AlarmListState> emit) async {
    try {
      final alarms = await getAlarmsUseCase();
      emit(AlarmListLoaded(alarms));
    } catch (e) {
      emit(AlarmListError('Could not load alarms: $e'));
    }
  }

  Future<void> _onSave(
      SaveAlarmEvent event, Emitter<AlarmListState> emit) async {
    try {
      await scheduleAlarmUseCase(event.alarm);
      final alarms = await getAlarmsUseCase();
      emit(AlarmListLoaded(alarms));
    } catch (e) {
      emit(AlarmListError('Could not save alarm: $e'));
    }
  }

  Future<void> _onDelete(
      DeleteAlarmEvent event, Emitter<AlarmListState> emit) async {
    try {
      await deleteAlarmUseCase(event.id);
      final alarms = await getAlarmsUseCase();
      emit(AlarmListLoaded(alarms));
    } catch (e) {
      emit(AlarmListError('Could not delete alarm: $e'));
    }
  }

  Future<void> _onToggle(
      ToggleAlarmEvent event, Emitter<AlarmListState> emit) async {
    try {
      await toggleAlarmUseCase(event.id, event.enabled);
      final alarms = await getAlarmsUseCase();
      emit(AlarmListLoaded(alarms));
    } catch (e) {
      emit(AlarmListError('Could not update alarm: $e'));
    }
  }
}
