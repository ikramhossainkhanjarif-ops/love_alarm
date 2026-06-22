import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String text;
  final bool isCustom; // false = built-in 200, true = user-added
  final bool isUsed; // used in the current non-repeating cycle

  const MessageEntity({
    required this.id,
    required this.text,
    required this.isCustom,
    required this.isUsed,
  });

  MessageEntity copyWith({
    String? id,
    String? text,
    bool? isCustom,
    bool? isUsed,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      isCustom: isCustom ?? this.isCustom,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  @override
  List<Object?> get props => [id, text, isCustom, isUsed];
}
