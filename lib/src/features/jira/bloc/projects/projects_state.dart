part of 'projects_bloc.dart';

@immutable
sealed class ProjectsState {
  const ProjectsState();
}

final class ProjectsInitial extends ProjectsState {
  const ProjectsInitial();
}

final class ProjectsLoading extends ProjectsState {
  const ProjectsLoading();
}

final class ProjectsLoaded extends ProjectsState {
  const ProjectsLoaded({
    required this.projects,
  });

  final List<Project> projects;
}

final class ProjectsError extends ProjectsState {
  const ProjectsError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}
