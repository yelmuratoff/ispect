part of 'labels_bloc.dart';

@immutable
sealed class LabelsState {
  const LabelsState();

  const factory LabelsState.initial() = _LabelsInitial;
  const factory LabelsState.loading() = _LabelsLoading;
  const factory LabelsState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _LabelsError;
  const factory LabelsState.loaded({
    required PageBeanString labels,
  }) = _LabelsLoaded;

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(Object error, StackTrace stackTrace)? error,
    T Function(PageBeanString labels)? loaded,
  }) =>
      switch (this) {
        _LabelsInitial() => initial?.call() ?? orElse(),
        _LabelsLoading() => loading?.call() ?? orElse(),
        final _LabelsError value => error?.call(value.error, value.stackTrace) ?? orElse(),
        final _LabelsLoaded value => loaded?.call(value.labels) ?? orElse(),
      };
}

final class _LabelsInitial extends LabelsState {
  const _LabelsInitial();
}

final class _LabelsLoading extends LabelsState {
  const _LabelsLoading();
}

final class _LabelsError extends LabelsState {
  const _LabelsError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

final class _LabelsLoaded extends LabelsState {
  const _LabelsLoaded({
    required this.labels,
  });

  final PageBeanString labels;
}
