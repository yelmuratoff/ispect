part of 'base.dart';

/// Log emitted when an error is thrown in a Bloc or Cubit.
///
/// Corresponds to [BlocObserver.onError].
/// Captures unhandled exceptions thrown during state emission or event processing.
final class BlocErrorLog extends BlocLifecycleLog {
  BlocErrorLog({
    required super.bloc,
    required this.thrown,
    StackTrace? stackTrace,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final errorType = thrown.runtimeType;
            return '${bloc.runtimeType} threw an error'
                '\nERROR: $errorType';
          },
          exception: thrown is Exception ? thrown : null,
          error: thrown is Error ? thrown : null,
          stackTrace: stackTrace != null && stackTrace != StackTrace.empty
              ? stackTrace
              : null,
          logLevel: LogLevel.error,
        );

  final Object thrown;

  static const String logKey = 'bloc-error';
}
