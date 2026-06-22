import 'sound_catalog.dart';

class AppConstants {
  AppConstants._();

  static const String defaultAlarmSound = SoundCatalog.defaultOption.assetPath;
  static const String backgroundImage = 'assets/images/romantic_background.jpg';

  static const List<String> weekdayShortLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Weekday numbers per ISO-8601 (1=Mon..7=Sun), aligned with
  /// [weekdayShortLabels].
  static const List<int> weekdayNumbers = [1, 2, 3, 4, 5, 6, 7];

  static const int defaultSnoozeMinutes = 5;
}
