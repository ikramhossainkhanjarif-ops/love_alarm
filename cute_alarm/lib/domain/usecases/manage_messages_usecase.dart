import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class ManageMessagesUseCase {
  final MessageRepository repository;
  ManageMessagesUseCase(this.repository);

  Future<List<MessageEntity>> getAll() => repository.getAllMessages();

  Future<void> add(String text) => repository.addCustomMessage(text);

  Future<void> edit(String id, String newText) =>
      repository.editCustomMessage(id, newText);

  Future<void> delete(String id) => repository.deleteCustomMessage(id);
}
