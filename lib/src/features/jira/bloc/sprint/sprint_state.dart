part of 'sprint_cubit.dart';

@immutable
sealed class SprintState {
  const SprintState();

  const factory SprintState.initial() = _SprintInitial;

  const factory SprintState.loading() = _SprintLoading;

  const factory SprintState.loaded({
    required List<JiraSprint> sprints,
  }) = _SprintLoaded;

  const factory SprintState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _SprintError;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(Object error, StackTrace stackTrace)? error,
    T Function(List<JiraSprint> sprints)? loaded,
  }) =>
      switch (this) {
        _SprintInitial() => initial?.call() ?? orElse(),
        _SprintLoading() => loading?.call() ?? orElse(),
        final _SprintError value =>
          error?.call(value.error, value.stackTrace) ?? orElse(),
        final _SprintLoaded value => loaded?.call(value.sprints) ?? orElse(),
      };
}

final class _SprintInitial extends SprintState {
  const _SprintInitial();
}

final class _SprintLoading extends SprintState {
  const _SprintLoading();
}

final class _SprintLoaded extends SprintState {
  const _SprintLoaded({required this.sprints});
  final List<JiraSprint> sprints;
}

final class _SprintError extends SprintState {
  const _SprintError({required this.error, required this.stackTrace});
  final Object error;
  final StackTrace stackTrace;
}
