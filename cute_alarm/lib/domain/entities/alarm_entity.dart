import 'package:equatable/equatable.dart';

/// Days of week represented as 1 (Monday) .. 7 (Sunday), ISO-8601 style.
class AlarmEntity extends Equatable {
  final String id;
  final int hour; // 0-23
  final int minute; // 0-59
  final bool isEnabled;
  final Set<int> repeatDays; // empty set = one-time alarm
  final String label;
  final String soundAssetPath;
  final bool vibrate;
  final int snoozeMinutes;
  final DateTime createdAt;

  const AlarmEntity({
    required this.id,
    required this.hour,
    required this.minute,
    required this.isEnabled,
    required this.repeatDays,
    required this.label,
    required this.soundAssetPath,
    required this.vibrate,
    required this.snoozeMinutes,
    required this.createdAt,
  });

  bool get isDaily => repeatDays.length == 7;
  bool get isOneTime => repeatDays.isEmpty;

  AlarmEntity copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? isEnabled,
    Set<int>? repeatDays,
    String? label,
    String? soundAssetPath,
    bool? vibrate,
    int? snoozeMinutes,
    DateTime? createdAt,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      label: label ?? this.label,
      soundAssetPath: soundAssetPath ?? this.soundAssetPath,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Computes the next DateTime this alarm should fire, given [now].
  DateTime nextTrigger(DateTime now) {
    DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);

    if (isOneTime) {
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    // Repeating: find the next matching weekday (including today if time
    // hasn't passed yet).
    for (int i = 0; i < 8; i++) {
      final day = candidate.add(Duration(days: i));
      final weekday = day.weekday; // 1=Mon ... 7=Sun
      if (repeatDays.contains(weekday) && day.isAfter(now)) {
        return day;
      }
    }
    // Fallback (shouldn't happen): tomorrow same time.
    return candidate.add(const Duration(days: 1));
  }

  @override
  List<Object?> get props => [
        id,
        hour,
        minute,
        isEnabled,
        repeatDays,
        label,
        soundAssetPath,
        vibrate,
        snoozeMinutes,
        createdAt,
      ];
}
