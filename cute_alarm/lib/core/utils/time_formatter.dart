import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class TimeFormatter {
  TimeFormatter._();

  static String formatHourMinute(int hour, int minute, {bool use24h = false}) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return use24h
        ? DateFormat('HH:mm').format(dt)
        : DateFormat('h:mm a').format(dt);
  }

  static String formatRepeatDays(Set<int> days) {
    if (days.isEmpty) return 'One time';
    if (days.length == 7) return 'Every day';
    final weekdays = {1, 2, 3, 4, 5};
    final weekend = {6, 7};
    if (days.length == 5 && days.containsAll(weekdays)) return 'Weekdays';
    if (days.length == 2 && days.containsAll(weekend)) return 'Weekends';

    final sorted = days.toList()..sort();
    return sorted
        .map((d) => AppConstants.weekdayShortLabels[d - 1])
        .join(', ');
  }

  static String formatFullDate(DateTime dt) {
    return DateFormat('EEEE, MMMM d, yyyy').format(dt);
  }

  static String formatClock(DateTime dt) {
    return DateFormat('h:mm').format(dt);
  }

  static String formatAmPm(DateTime dt) {
    return DateFormat('a').format(dt);
  }
}
