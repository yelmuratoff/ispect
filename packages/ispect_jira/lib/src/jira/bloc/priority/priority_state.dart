part of 'priority_cubit.dart';

@immutable
sealed class PriorityState {
  const PriorityState();

  const factory PriorityState.initial() = _PriorityInitial;

  const factory PriorityState.loading() = _PriorityLoading;

  const factory PriorityState.loaded({
    required List<Priority> priorities,
  }) = _PriorityLoaded;

  const factory PriorityState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _PriorityError;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(Object error, StackTrace stackTrace)? error,
    T Function(List<Priority> priorities)? loaded,
  }) =>
      switch (this) {
        _PriorityInitial() => initial?.call() ?? orElse(),
        _PriorityLoading() => loading?.call() ?? orElse(),
        final _PriorityError value =>
          error?.call(value.error, value.stackTrace) ?? orElse(),
        final _PriorityLoaded value =>
          loaded?.call(value.priorities) ?? orElse(),
      };
}

final class _PriorityInitial extends PriorityState {
  const _PriorityInitial();
}

final class _PriorityLoading extends PriorityState {
  const _PriorityLoading();
}

final class _PriorityLoaded extends PriorityState {
  const _PriorityLoaded({
    required this.priorities,
  });

  final List<Priority> priorities;
}

final class _PriorityError extends PriorityState {
  const _PriorityError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}
