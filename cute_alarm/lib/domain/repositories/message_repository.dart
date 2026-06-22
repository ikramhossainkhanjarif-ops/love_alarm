import '../entities/message_entity.dart';

abstract class MessageRepository {
  /// All messages (built-in + custom), with used/unused state.
  Future<List<MessageEntity>> getAllMessages();

  /// Returns today's message, deterministically picking a random unused
  /// message and marking it used. When all messages have been used, the
  /// "used" pool resets so messages can repeat again, but never before
  /// every message has had a turn.
  Future<MessageEntity> getTodaysMessage();

  Future<void> addCustomMessage(String text);
  Future<void> editCustomMessage(String id, String newText);
  Future<void> deleteCustomMessage(String id);

  Future<void> resetUsedCycle();
}
