part of 'current_user_cubit.dart';

@immutable
sealed class CurrentUserState {
  const CurrentUserState();

  const factory CurrentUserState.initial() = _CurrentUserInitial;

  const factory CurrentUserState.loading() = _CurrentUserLoading;

  const factory CurrentUserState.loaded({
    required User user,
  }) = _CurrentUserLoaded;

  const factory CurrentUserState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _CurrentUserError;

  bool get isError => this is _CurrentUserError;

  bool get isLoading => this is _CurrentUserLoading;

  bool get isLoaded => this is _CurrentUserLoaded;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? loaded,
    T Function(Object error, StackTrace stackTrace)? error,
  }) =>
      switch (this) {
        _CurrentUserInitial() => initial?.call() ?? orElse(),
        _CurrentUserLoading() => loading?.call() ?? orElse(),
        final _CurrentUserLoaded value => loaded?.call(value.user) ?? orElse(),
        final _CurrentUserError value => error?.call(value.error, value.stackTrace) ?? orElse(),
      };

  void mapOrNull({
    VoidCallback? initial,
    VoidCallback? loading,
    void Function(_CurrentUserLoaded value)? loaded,
    void Function(_CurrentUserError value)? error,
  }) {
    if (this is _CurrentUserInitial) {
      if (initial == null) return;
      initial();
    }
    if (this is _CurrentUserLoading) {
      if (loading == null) return;
      loading();
    }
    if (this is _CurrentUserLoaded) {
      if (loaded == null) return;
      loaded(this as _CurrentUserLoaded);
    }
    if (this is _CurrentUserError) {
      if (error == null) return;
      error(this as _CurrentUserError);
    }
  }
}

final class _CurrentUserInitial extends CurrentUserState {
  const _CurrentUserInitial();
}

final class _CurrentUserLoading extends CurrentUserState {
  const _CurrentUserLoading();
}

final class _CurrentUserLoaded extends CurrentUserState {
  const _CurrentUserLoaded({
    required this.user,
  });

  final User user;
}

final class _CurrentUserError extends CurrentUserState {
  const _CurrentUserError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}
