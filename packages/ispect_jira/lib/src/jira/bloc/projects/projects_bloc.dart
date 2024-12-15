import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'projects_state.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit() : super(const ProjectsInitial());

  Future<void> getProjects() async {
    emit(const ProjectsLoading());
    try {
      final projects = await ISpectJiraClient.getProjects();
      emit(ProjectsLoaded(projects: projects));
    } catch (error, stackTrace) {
      emit(ProjectsError(error: error, stackTrace: stackTrace));
    }
  }
}
