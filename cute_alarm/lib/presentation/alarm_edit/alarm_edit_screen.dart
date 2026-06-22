import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sound_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pastel_gradient_background.dart';
import '../../domain/entities/alarm_entity.dart';
import '../common/sound_picker_sheet.dart';
import '../common/weekday_selector.dart';

class AlarmEditScreen extends StatefulWidget {
  final AlarmEntity? existing;
  const AlarmEditScreen({super.key, this.existing});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TimeOfDay _time;
  late Set<int> _repeatDays;
  late TextEditingController _labelController;
  late bool _vibrate;
  late int _snoozeMinutes;
  late String _soundAssetPath;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _time = TimeOfDay(hour: e?.hour ?? 7, minute: e?.minute ?? 0);
    _repeatDays = Set.of(e?.repeatDays ?? <int>{1, 2, 3, 4, 5, 6, 7});
    _labelController = TextEditingController(text: e?.label ?? '');
    _vibrate = e?.vibrate ?? true;
    _snoozeMinutes = e?.snoozeMinutes ?? AppConstants.defaultSnoozeMinutes;
    _soundAssetPath = e?.soundAssetPath ?? AppConstants.defaultAlarmSound;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryPink,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _openSoundPicker() async {
    final picked = await showSoundPickerSheet(
      context: context,
      currentAssetPath: _soundAssetPath,
    );
    if (picked != null) {
      setState(() => _soundAssetPath = picked);
    }
  }

  void _save() {
    final alarm = AlarmEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      hour: _time.hour,
      minute: _time.minute,
      isEnabled: widget.existing?.isEnabled ?? true,
      repeatDays: _repeatDays,
      label: _labelController.text.trim(),
      soundAssetPath: _soundAssetPath,
      vibrate: _vibrate,
      snoozeMinutes: _snoozeMinutes,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alarm' : 'New Alarm'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.deepPink,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: PastelGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      _time.format(context),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _SectionCard(
                title: 'Repeat',
                child: WeekdaySelector(
                  selected: _repeatDays,
                  onChanged: (val) => setState(() => _repeatDays = val),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Label',
                child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Good morning, love 💕',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Options',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alarm sound'),
                      subtitle: Text(
                        SoundCatalog.fromAssetPath(_soundAssetPath).name,
                        style: const TextStyle(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textMuted),
                      onTap: _openSoundPicker,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibrate'),
                      value: _vibrate,
                      onChanged: (v) => setState(() => _vibrate = v),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Snooze duration'),
                      trailing: DropdownButton<int>(
                        value: _snoozeMinutes,
                        underline: const SizedBox(),
                        items: const [3, 5, 10, 15, 20]
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('$m min'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _snoozeMinutes = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
