import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:ispect_jira/src/jira/models/sprint.dart';
import 'package:meta/meta.dart';

part 'sprint_state.dart';

class SprintCubit extends Cubit<SprintState> {
  SprintCubit() : super(const SprintState.initial());

  Future<void> getSprints({
    required int boardId,
  }) async {
    emit(const SprintState.loading());

    try {
      final sprints = await ISpectJiraClient.getSprints(boardId: boardId);

      emit(SprintState.loaded(sprints: sprints));
    } catch (error, stackTrace) {
      emit(SprintState.error(error: error, stackTrace: stackTrace));
    }
  }

  void toInitial() {
    emit(const SprintState.initial());
  }
}
