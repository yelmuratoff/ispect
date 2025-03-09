import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';

part 'status_state.dart';

class StatusCubit extends Cubit<StatusState> {
  StatusCubit() : super(const StatusState.initial());

  Future<void> getStatuses() async {
    emit(const StatusState.loading());
    try {
      final project =
          await ISpectJiraClient.getStatuses(); // Project info general

      emit(
        StatusState.loaded(
          status: project.where((element) => !element.subtask).toList(),
        ),
      );
    } catch (e, stackTrace) {
      ISpect.logger.handle(exception: e, stackTrace: stackTrace);
      emit(StatusState.error(error: e, stackTrace: stackTrace));
    }
  }
}
