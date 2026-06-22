import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

/// Handles persistence for romantic messages.
///
/// Storage design:
/// - The 200 built-in messages ship as a JSON asset (`assets/data/messages_seed.json`)
///   and are treated as read-only "seed" data.
/// - Custom (user-added) messages are stored separately in SharedPreferences
///   as their own JSON list, so editing/deleting never touches the seed file.
/// - A separate "used IDs" set (also in SharedPreferences) tracks which
///   message IDs (built-in or custom) have already been shown in the
///   current cycle, so we never repeat a message until the full pool
///   (built-in + custom) has been exhausted.
/// - A "last shown date" key ensures we only pick a *new* message once per
///   calendar day, while still returning the same message if asked again
///   on the same day (e.g. app re-opened, or alarm view rebuilt).
class MessageLocalDataSource {
  static const String _customKey = 'romantic_alarm.custom_messages_v1';
  static const String _usedIdsKey = 'romantic_alarm.used_message_ids_v1';
  static const String _lastShownDateKey =
      'romantic_alarm.last_shown_date_v1';
  static const String _lastShownIdKey = 'romantic_alarm.last_shown_id_v1';

  static const String _seedAssetPath = 'assets/data/messages_seed.json';

  final _uuid = const Uuid();

  List<MessageModel>? _seedCache;

  Future<List<MessageModel>> _loadSeedMessages() async {
    if (_seedCache != null) return _seedCache!;
    final raw = await rootBundle.loadString(_seedAssetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    _seedCache = decoded
        .map((e) => MessageModel(
              id: e['id'] as String,
              text: e['text'] as String,
              isCustom: false,
              isUsed: false,
            ))
        .toList();
    return _seedCache!;
  }

  Future<List<MessageModel>> _loadCustomMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveCustomMessages(List<MessageModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_customKey, encoded);
  }

  Future<Set<String>> _loadUsedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_usedIdsKey) ?? [];
    return list.toSet();
  }

  Future<void> _saveUsedIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usedIdsKey, ids.toList());
  }

  /// All messages (seed + custom) with `isUsed` populated from the
  /// persisted used-IDs set.
  Future<List<MessageModel>> getAllMessages() async {
    final seed = await _loadSeedMessages();
    final custom = await _loadCustomMessages();
    final usedIds = await _loadUsedIds();

    final all = [...seed, ...custom];
    return all
        .map((m) => MessageModel(
              id: m.id,
              text: m.text,
              isCustom: m.isCustom,
              isUsed: usedIds.contains(m.id),
            ))
        .toList();
  }

  /// Returns the message that should be shown "today", picking a new
  /// random unused message only once per calendar day.
  Future<MessageModel> getTodaysMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    final lastShownDate = prefs.getString(_lastShownDateKey);
    final lastShownId = prefs.getString(_lastShownIdKey);

    final all = await getAllMessages();

    // If we already picked a message today, return the same one (unless
    // it was deleted in the meantime, e.g. a custom message removed).
    if (lastShownDate == todayKey && lastShownId != null) {
      final existing = all.where((m) => m.id == lastShownId);
      if (existing.isNotEmpty) return existing.first;
    }

    final picked = await _pickNextMessage(all);

    await prefs.setString(_lastShownDateKey, todayKey);
    await prefs.setString(_lastShownIdKey, picked.id);

    return picked;
  }

  Future<MessageModel> _pickNextMessage(List<MessageModel> all) async {
    if (all.isEmpty) {
      // Should never happen since seed has 200, but guard anyway.
      return MessageModel(
        id: 'fallback',
        text: 'You are loved more than words can say. ❤️',
        isCustom: false,
        isUsed: false,
      );
    }

    var usedIds = await _loadUsedIds();
    var unused = all.where((m) => !usedIds.contains(m.id)).toList();

    // Cycle complete (or stale IDs from deleted customs) -> reset.
    if (unused.isEmpty) {
      usedIds = {};
      unused = List.of(all);
    }

    final random = Random();
    final picked = unused[random.nextInt(unused.length)];

    usedIds.add(picked.id);
    await _saveUsedIds(usedIds);

    return picked;
  }

  Future<void> resetUsedCycle() async {
    await _saveUsedIds({});
  }

  Future<void> addCustomMessage(String text) async {
    final custom = await _loadCustomMessages();
    custom.add(MessageModel(
      id: 'custom_${_uuid.v4()}',
      text: text.trim(),
      isCustom: true,
      isUsed: false,
    ));
    await _saveCustomMessages(custom);
  }

  Future<void> editCustomMessage(String id, String newText) async {
    final custom = await _loadCustomMessages();
    final idx = custom.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    custom[idx] = MessageModel(
      id: custom[idx].id,
      text: newText.trim(),
      isCustom: true,
      isUsed: custom[idx].isUsed,
    );
    await _saveCustomMessages(custom);
  }

  Future<void> deleteCustomMessage(String id) async {
    final custom = await _loadCustomMessages();
    custom.removeWhere((m) => m.id == id);
    await _saveCustomMessages(custom);

    // Also scrub it from used-IDs so the pool count stays consistent.
    final usedIds = await _loadUsedIds();
    if (usedIds.remove(id)) {
      await _saveUsedIds(usedIds);
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
