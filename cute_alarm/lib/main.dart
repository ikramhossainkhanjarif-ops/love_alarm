import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/alarm_local_datasource.dart';
import 'data/datasources/message_local_datasource.dart';
import 'data/datasources/native_alarm_scheduler.dart';
import 'data/repositories/alarm_repository_impl.dart';
import 'data/repositories/message_repository_impl.dart';
import 'domain/usecases/delete_alarm_usecase.dart';
import 'domain/usecases/get_alarms_usecase.dart';
import 'domain/usecases/get_todays_message_usecase.dart';
import 'domain/usecases/schedule_alarm_usecase.dart';
import 'domain/usecases/toggle_alarm_usecase.dart';
import 'presentation/alarm_list/alarm_list_screen.dart';
import 'presentation/alarm_list/bloc/alarm_list_bloc.dart';
import 'presentation/ringing/ringing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RomanticAlarmApp());
}

/// Global navigator key so native-event callbacks can push the ringing
/// screen on top of whatever is currently showing, from anywhere.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class RomanticAlarmApp extends StatefulWidget {
  const RomanticAlarmApp({super.key});

  @override
  State<RomanticAlarmApp> createState() => _RomanticAlarmAppState();
}

class _RomanticAlarmAppState extends State<RomanticAlarmApp> {
  // --- Dependency wiring (simple manual DI; no extra package needed) ---
  final _alarmLocalDataSource = AlarmLocalDataSource();
  final _messageLocalDataSource = MessageLocalDataSource();

  late final _alarmRepository = AlarmRepositoryImpl(_alarmLocalDataSource);
  late final _messageRepository =
      MessageRepositoryImpl(_messageLocalDataSource);

  late final _alarmListBloc = AlarmListBloc(
    getAlarmsUseCase: GetAlarmsUseCase(_alarmRepository),
    scheduleAlarmUseCase: ScheduleAlarmUseCase(_alarmRepository),
    deleteAlarmUseCase: DeleteAlarmUseCase(_alarmRepository),
    toggleAlarmUseCase: ToggleAlarmUseCase(_alarmRepository),
  );

  late final _getTodaysMessageUseCase =
      GetTodaysMessageUseCase(_messageRepository);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Re-sync alarms with the native AlarmManager on every app start. This
    // covers edge cases like app updates, or if the boot receiver missed
    // a reboot for any OEM-specific reason.
    await _alarmRepository.resyncAllWithNative();

    // Ask for exact-alarm + battery-optimization exemptions politely.
    await NativeAlarmScheduler.ensureExactAlarmPermission();

    // Listen for alarms firing while the app is alive (foreground or
    // background) so we can navigate to the ringing screen even if the
    // OS didn't cold-start us via the full-screen intent.
    NativeAlarmScheduler.setAlarmFiredHandler(_handleAlarmFired);

    // If the app was cold-started directly because the user tapped the
    // full-screen alarm notification, jump straight to the ringing UI.
    final initialPayload = await NativeAlarmScheduler.getInitialAlarmPayload();
    if (initialPayload != null) {
      _navigateToRinging(initialPayload);
    }
  }

  Future<void> _handleAlarmFired(Map<String, dynamic> payload) async {
    _navigateToRinging(payload);
  }

  void _navigateToRinging(Map<String, dynamic> payload) {
    final alarmId = payload['id'] as String? ?? 'unknown';
    final snoozeMinutes = (payload['snoozeMinutes'] as int?) ?? 5;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => RingingScreen(
            alarmId: alarmId,
            getTodaysMessageUseCase: _getTodaysMessageUseCase,
            snoozeMinutes: snoozeMinutes,
          ),
          fullscreenDialog: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _alarmListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _alarmListBloc),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'Romantic Alarm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AlarmListScreen(),
      ),
    );
  }
}
