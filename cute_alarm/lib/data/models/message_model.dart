import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.text,
    required super.isCustom,
    required super.isUsed,
  });

  factory MessageModel.fromEntity(MessageEntity e) => MessageModel(
        id: e.id,
        text: e.text,
        isCustom: e.isCustom,
        isUsed: e.isUsed,
      );

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCustom': isCustom,
      'isUsed': isUsed,
    };
  }
}
