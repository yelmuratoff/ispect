final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String message;
  final DateTime createdAt;
}

final class UserMessage extends ChatMessage {
  const UserMessage({
    required super.id,
    required super.message,
    required super.createdAt,
  });
}

final class AIMessage extends ChatMessage {
  const AIMessage({
    required super.id,
    required super.message,
    required super.createdAt,
  });

  factory AIMessage.fromResponse(int id, String message, DateTime createdAt) =>
      AIMessage(
        id: id,
        message: message,
        createdAt: createdAt,
      );

  factory AIMessage.initial(String welcomeMessage) => AIMessage(
        id: 0,
        message: welcomeMessage,
        createdAt: DateTime.now(),
      );
}
