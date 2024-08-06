part of 'boards_cubit.dart';

@immutable
sealed class BoardsState {
  const BoardsState();

  const factory BoardsState.initial() = _BoardsInitial;

  const factory BoardsState.loading() = _BoardsLoading;

  const factory BoardsState.loaded({
    required List<JiraBoard> boards,
  }) = _BoardsLoaded;

  const factory BoardsState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _BoardsError;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(Object error, StackTrace stackTrace)? error,
    T Function(List<JiraBoard> boards)? loaded,
  }) =>
      switch (this) {
        _BoardsInitial() => initial?.call() ?? orElse(),
        _BoardsLoading() => loading?.call() ?? orElse(),
        final _BoardsError value =>
          error?.call(value.error, value.stackTrace) ?? orElse(),
        final _BoardsLoaded value => loaded?.call(value.boards) ?? orElse(),
      };
}

final class _BoardsInitial extends BoardsState {
  const _BoardsInitial();
}

final class _BoardsLoading extends BoardsState {
  const _BoardsLoading();
}

final class _BoardsLoaded extends BoardsState {
  const _BoardsLoaded({required this.boards});
  final List<JiraBoard> boards;
}

final class _BoardsError extends BoardsState {
  const _BoardsError({required this.error, required this.stackTrace});
  final Object error;
  final StackTrace stackTrace;
}
