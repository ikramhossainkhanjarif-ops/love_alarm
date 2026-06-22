import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_local_datasource.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageLocalDataSource localDataSource;

  MessageRepositoryImpl(this.localDataSource);

  @override
  Future<List<MessageEntity>> getAllMessages() =>
      localDataSource.getAllMessages();

  @override
  Future<MessageEntity> getTodaysMessage() =>
      localDataSource.getTodaysMessage();

  @override
  Future<void> addCustomMessage(String text) =>
      localDataSource.addCustomMessage(text);

  @override
  Future<void> editCustomMessage(String id, String newText) =>
      localDataSource.editCustomMessage(id, newText);

  @override
  Future<void> deleteCustomMessage(String id) =>
      localDataSource.deleteCustomMessage(id);

  @override
  Future<void> resetUsedCycle() => localDataSource.resetUsedCycle();
}
