import '../../domain/entities/alarm_entity.dart';

class AlarmModel extends AlarmEntity {
  const AlarmModel({
    required super.id,
    required super.hour,
    required super.minute,
    required super.isEnabled,
    required super.repeatDays,
    required super.label,
    required super.soundAssetPath,
    required super.vibrate,
    required super.snoozeMinutes,
    required super.createdAt,
  });

  factory AlarmModel.fromEntity(AlarmEntity e) => AlarmModel(
        id: e.id,
        hour: e.hour,
        minute: e.minute,
        isEnabled: e.isEnabled,
        repeatDays: e.repeatDays,
        label: e.label,
        soundAssetPath: e.soundAssetPath,
        vibrate: e.vibrate,
        snoozeMinutes: e.snoozeMinutes,
        createdAt: e.createdAt,
      );

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      isEnabled: json['isEnabled'] as bool,
      repeatDays: (json['repeatDays'] as List<dynamic>)
          .map((e) => e as int)
          .toSet(),
      label: json['label'] as String? ?? '',
      soundAssetPath: json['soundAssetPath'] as String? ??
          'assets/sounds/alarm_sound.mp3',
      vibrate: json['vibrate'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays.toList(),
      'label': label,
      'soundAssetPath': soundAssetPath,
      'vibrate': vibrate,
      'snoozeMinutes': snoozeMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
