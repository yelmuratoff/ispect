part of 'ai_chat_bloc.dart';

@immutable
sealed class AiChatEvent {
  const AiChatEvent();
}

class SendMessage extends AiChatEvent {
  const SendMessage(this.message);
  final UserMessage message;
}

class InitChat extends AiChatEvent {
  const InitChat({
    required this.logs,
  });

  final List<TalkerData> logs;
}
