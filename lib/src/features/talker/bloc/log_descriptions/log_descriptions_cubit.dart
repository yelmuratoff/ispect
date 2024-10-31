import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/src/features/talker/core/data/models/log_description.dart';
import 'package:ispect/src/features/talker/core/domain/ai_repository.dart';
import 'package:meta/meta.dart';

part 'log_descriptions_state.dart';

class LogDescriptionsCubit extends Cubit<LogDescriptionsState> {
  LogDescriptionsCubit({
    required this.aiRepository,
  }) : super(const LogDescriptionsInitial());

  final IAiRepository aiRepository;

  Future<void> generateLogDescriptions({
    required LogDescriptionPayload payload,
  }) async {
    try {
      // if (state is! LogDescriptionsLoaded) {
      emit(const LogDescriptionsLoading());
      // }
      final logDescriptions = await aiRepository.generateLogDescription(
        payload: payload,
      );
      emit(LogDescriptionsLoaded(logDescriptions: logDescriptions));
    } catch (e) {
      emit(LogDescriptionsError(message: e.toString()));
    }
  }
}
