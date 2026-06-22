import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// Persists alarms as a JSON-encoded list under a single SharedPreferences
/// key. Simple, dependency-free, and perfectly fine for the small number of
/// alarms a personal alarm clock app will ever hold.
class AlarmLocalDataSource {
  static const String _key = 'romantic_alarm.alarms_v1';

  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
