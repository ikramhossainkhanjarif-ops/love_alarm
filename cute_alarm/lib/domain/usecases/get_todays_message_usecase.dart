import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class GetTodaysMessageUseCase {
  final MessageRepository repository;
  GetTodaysMessageUseCase(this.repository);

  Future<MessageEntity> call() => repository.getTodaysMessage();
}
