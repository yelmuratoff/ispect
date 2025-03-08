import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/data/models/log_description.dart';
import '../../core/domain/ai_repository.dart';
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
      emit(const LogDescriptionsLoading());

      final logDescriptions = await aiRepository.generateLogDescription(
        payload: payload,
      );
      emit(LogDescriptionsLoaded(logDescriptions: logDescriptions));
    } catch (e) {
      emit(LogDescriptionsError(message: e.toString()));
    }
  }
}
