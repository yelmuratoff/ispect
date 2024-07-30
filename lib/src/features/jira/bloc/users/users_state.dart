part of 'users_cubit.dart';

@immutable
sealed class UsersState {
  const UsersState();

  const factory UsersState.initial() = _UsersInitial;

  const factory UsersState.loading() = _UsersLoading;

  const factory UsersState.loaded({
    required List<User> users,
  }) = _UsersLoaded;

  const factory UsersState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _UsersError;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(Object error, StackTrace stackTrace)? error,
    T Function(List<User> users)? loaded,
  }) =>
      switch (this) {
        _UsersInitial() => initial?.call() ?? orElse(),
        _UsersLoading() => loading?.call() ?? orElse(),
        final _UsersError value => error?.call(value.error, value.stackTrace) ?? orElse(),
        final _UsersLoaded value => loaded?.call(value.users) ?? orElse(),
      };
}

final class _UsersInitial extends UsersState {
  const _UsersInitial();
}

final class _UsersLoading extends UsersState {
  const _UsersLoading();
}

final class _UsersError extends UsersState {
  const _UsersError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

final class _UsersLoaded extends UsersState {
  const _UsersLoaded({
    required this.users,
  });

  final List<User> users;
}
