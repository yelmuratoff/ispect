part of 'status_bloc.dart';

@immutable
sealed class StatusState {
  const StatusState();

  const factory StatusState.initial() = _StatusInitial;
  const factory StatusState.loading() = _StatusLoading;
  const factory StatusState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _StatusError;
  const factory StatusState.loaded({
    required List<IssueTypeWithStatus> status,
  }) = _StatusLoaded;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(Object error, StackTrace stackTrace)? error,
    T Function(List<IssueTypeWithStatus> status)? loaded,
  }) =>
      switch (this) {
        _StatusInitial() => initial?.call() ?? orElse(),
        _StatusLoading() => loading?.call() ?? orElse(),
        final _StatusError value => error?.call(value.error, value.stackTrace) ?? orElse(),
        final _StatusLoaded value => loaded?.call(value.status) ?? orElse(),
      };
}

final class _StatusInitial extends StatusState {
  const _StatusInitial();
}

final class _StatusLoading extends StatusState {
  const _StatusLoading();
}

final class _StatusError extends StatusState {
  const _StatusError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

final class _StatusLoaded extends StatusState {
  const _StatusLoaded({
    required this.status,
  });

  final List<IssueTypeWithStatus> status;
}
