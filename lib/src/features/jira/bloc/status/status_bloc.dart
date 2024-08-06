import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/src/common/services/talker/talker_wrapper.dart';
import 'package:ispect/src/features/jira/jira_client.dart';

part 'status_state.dart';

class StatusCubit extends Cubit<StatusState> {
  StatusCubit() : super(const StatusState.initial());

  Future<void> getStatuses() async {
    emit(const StatusState.loading());
    try {
      // final status = await _api.status.search(
      //   projectId: JiraClient.projectId,
      //   maxResults: 100,
      // );
      // final project = await _api.projects.getAllStatuses(JiraClient.projectId); // (Story, Task, Bug, Эпик, Подзадача)
      // final project = await _api.projects.getProject(projectIdOrKey: JiraClient.projectId); // Project info general
      final project = await JiraClient.getStatuses(); // Project info general
      // final statuses = await JiraClient.getStatuses();
      // print(project.where((element) => element.name == 'In Progress').first);
      // if (kDebugMode) {
      //   print(project);
      // }
      emit(
        StatusState.loaded(
          status: project.where((element) => !element.subtask).toList(),
        ),
      );
    } catch (e, stackTrace) {
      ISpectTalker.handle(exception: e, stackTrace: stackTrace);
      emit(StatusState.error(error: e, stackTrace: stackTrace));
    }
  }
}
