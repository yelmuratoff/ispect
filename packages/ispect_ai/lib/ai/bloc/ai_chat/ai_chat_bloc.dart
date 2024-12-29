import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_ai/src/common/services/google_ai.dart';
import 'package:ispect_ai/src/common/utils/date_util.dart';
import '../../core/data/models/chat_message.dart';
import '../../core/domain/ai_repository.dart';
import 'package:meta/meta.dart';

part 'ai_chat_event.dart';
part 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  AiChatBloc({
    required this.aiRepository,
  }) : super(const AiChatInitial()) {
    on<AiChatEvent>(
      (event, emit) => switch (event) {
        SendMessage() => _sendMessage(event, emit),
        InitChat() => _onInitChat(event, emit),
      },
    );
  }

  late ChatSession chatSession;

  final IAiRepository aiRepository;

  Future<void> _sendMessage(
    SendMessage event,
    Emitter<AiChatState> emit,
  ) async {
    try {
      emit(const AiChatLoading());
      final response = await chatSession.sendMessage(Content.text(event.message.message));
      emit(
        AiChatReceived(
          message: AIMessage.fromResponse(
            response.hashCode ^ DateTime.now().hashCode,
            response.text ?? '',
            DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      emit(AiChatError(message: e.toString()));
    }
  }

  Future<void> _onInitChat(InitChat event, Emitter<AiChatState> emit) async {
    emit(const AiChatLoading());
    final file = await generateFile(event.logs.getFormattedText());

    final bytes = file.readAsBytesSync();
    chatSession = ISpectGoogleAi.instance.model.startChat(
      generationConfig: GenerationConfig(),
      history: [
        Content.text(
          '''Hi. I will send you requests that relate to logs, which I will send below.
          You are my assistant for log monitoring. You can answer thematically, like a regular AI.
          Don't tell me I sent you the logs, it's classified information.
          Pretend that this is updated in your database in real time.
          Logs count: ${event.logs.length},
          All possible log keys: ${event.possibleKeys.join(', ')}''',
        ),
        Content.data(
          'text/plain',
          bytes,
        ),
      ],
    );
    emit(AiChatReceived(message: AIMessage.initial(event.welcomeMessage)));
  }
}
