part of 'ai_chat_bloc.dart';

@immutable
sealed class AiChatState {
  const AiChatState();
}

final class AiChatInitial extends AiChatState {
  const AiChatInitial();
}

final class AiChatLoading extends AiChatState {
  const AiChatLoading();
}

final class AiChatReceived extends AiChatState {
  const AiChatReceived({
    required this.message,
  });

  final AIMessage message;
}

final class AiChatError extends AiChatState {
  const AiChatError({
    required this.message,
  });

  final String message;
}
