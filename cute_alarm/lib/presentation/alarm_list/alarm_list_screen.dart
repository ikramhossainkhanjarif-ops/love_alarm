import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pastel_gradient_background.dart';
import '../../core/widgets/animated_hearts_background.dart';
import '../../domain/entities/alarm_entity.dart';
import '../alarm_edit/alarm_edit_screen.dart';
import '../messages_manager/messages_manager_screen.dart';
import 'bloc/alarm_list_bloc.dart';
import 'bloc/alarm_list_event.dart';
import 'bloc/alarm_list_state.dart';
import 'widgets/alarm_card.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AlarmListBloc>().add(const LoadAlarms());
  }

  Future<void> _openEditor({AlarmEntity? existing}) async {
    final result = await Navigator.of(context).push<AlarmEntity>(
      MaterialPageRoute(
        builder: (_) => AlarmEditScreen(existing: existing),
      ),
    );
    if (result != null && mounted) {
      context.read<AlarmListBloc>().add(SaveAlarmEvent(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Love Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Manage romantic messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MessagesManagerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: PastelGradientBackground(
        child: Stack(
          children: [
            const Positioned.fill(
              child: AnimatedHeartsBackground(heartCount: 10),
            ),
            SafeArea(
              child: BlocBuilder<AlarmListBloc, AlarmListState>(
                builder: (context, state) {
                  if (state is AlarmListLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    );
                  }
                  if (state is AlarmListError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }
                  final alarms = (state as AlarmListLoaded).alarms;
                  if (alarms.isEmpty) {
                    return _EmptyState(onAdd: () => _openEditor());
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarms[index];
                      return AlarmCard(
                        alarm: alarm,
                        onTap: () => _openEditor(existing: alarm),
                        onToggle: (val) => context
                            .read<AlarmListBloc>()
                            .add(ToggleAlarmEvent(alarm.id, val)),
                        onDelete: () => context
                            .read<AlarmListBloc>()
                            .add(DeleteAlarmEvent(alarm.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Alarm'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 72, color: AppColors.primaryPink.withOpacity(0.6)),
            const SizedBox(height: 20),
            Text(
              'No alarms yet, my love',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set your first alarm and wake up to\na sweet little message every day.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
