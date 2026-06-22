import 'package:flutter_test/flutter_test.dart';
import 'package:romantic_alarm/domain/entities/alarm_entity.dart';

void main() {
  group('AlarmEntity.nextTrigger', () {
    test('one-time alarm later today fires today', () {
      final now = DateTime(2026, 6, 20, 7, 0); // Saturday
      final alarm = AlarmEntity(
        id: '1',
        hour: 8,
        minute: 30,
        isEnabled: true,
        repeatDays: const {},
        label: '',
        soundAssetPath: 'x',
        vibrate: true,
        snoozeMinutes: 5,
        createdAt: now,
      );
      final next = alarm.nextTrigger(now);
      expect(next.day, 20);
      expect(next.hour, 8);
      expect(next.minute, 30);
    });

    test('one-time alarm already passed today rolls to tomorrow', () {
      final now = DateTime(2026, 6, 20, 9, 0);
      final alarm = AlarmEntity(
        id: '1',
        hour: 8,
        minute: 30,
        isEnabled: true,
        repeatDays: const {},
        label: '',
        soundAssetPath: 'x',
        vibrate: true,
        snoozeMinutes: 5,
        createdAt: now,
      );
      final next = alarm.nextTrigger(now);
      expect(next.day, 21);
    });

    test('repeating alarm picks next matching weekday', () {
      // Saturday June 20, 2026; alarm set for Mon/Wed/Fri at 7:00.
      final now = DateTime(2026, 6, 20, 10, 0);
      final alarm = AlarmEntity(
        id: '1',
        hour: 7,
        minute: 0,
        isEnabled: true,
        repeatDays: const {1, 3, 5}, // Mon, Wed, Fri
        label: '',
        soundAssetPath: 'x',
        vibrate: true,
        snoozeMinutes: 5,
        createdAt: now,
      );
      final next = alarm.nextTrigger(now);
      // Next Monday after Sat June 20 is June 22.
      expect(next.day, 22);
      expect(next.weekday, DateTime.monday);
    });

    test('daily alarm with time later today fires today', () {
      final now = DateTime(2026, 6, 20, 6, 0);
      final alarm = AlarmEntity(
        id: '1',
        hour: 7,
        minute: 0,
        isEnabled: true,
        repeatDays: const {1, 2, 3, 4, 5, 6, 7},
        label: '',
        soundAssetPath: 'x',
        vibrate: true,
        snoozeMinutes: 5,
        createdAt: now,
      );
      final next = alarm.nextTrigger(now);
      expect(next.day, 20);
    });
  });
}
