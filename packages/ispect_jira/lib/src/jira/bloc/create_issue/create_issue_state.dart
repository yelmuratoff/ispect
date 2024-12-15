part of 'create_issue_cubit.dart';

enum CreateIssueEnum {
  initial,
  issue,
  transition,
  attachment,
  finished,
}

@immutable
sealed class CreateIssueState {
  const CreateIssueState();

  const factory CreateIssueState.initial() = _CreateIssueInitial;

  const factory CreateIssueState.loading({
    required CreateIssueEnum type,
    required String message,
  }) = _CreateIssueLoading;

  const factory CreateIssueState.loaded({
    required String key,
  }) = _CreateIssueLoaded;

  const factory CreateIssueState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _CreateIssueError;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function(
      CreateIssueEnum type,
      String message,
    )? loading,
    T Function(String value)? loaded,
    T Function(Object error, StackTrace stackTrace)? error,
  }) =>
      switch (this) {
        _CreateIssueInitial() => initial?.call() ?? orElse(),
        final _CreateIssueLoading value => loading?.call(
              value.type,
              value.message,
            ) ??
            orElse(),
        final _CreateIssueLoaded value => loaded?.call(value.key) ?? orElse(),
        final _CreateIssueError value =>
          error?.call(value.error, value.stackTrace) ?? orElse(),
      };
}

final class _CreateIssueInitial extends CreateIssueState {
  const _CreateIssueInitial();
}

final class _CreateIssueLoading extends CreateIssueState {
  const _CreateIssueLoading({
    required this.type,
    required this.message,
  });

  final CreateIssueEnum type;
  final String message;
}

final class _CreateIssueLoaded extends CreateIssueState {
  const _CreateIssueLoaded({
    required this.key,
  });

  final String key;
}

final class _CreateIssueError extends CreateIssueState {
  const _CreateIssueError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}
