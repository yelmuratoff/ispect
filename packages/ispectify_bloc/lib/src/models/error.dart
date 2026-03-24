part of 'base.dart';

/// Log emitted when an error is thrown in a Bloc or Cubit.
///
/// Corresponds to [BlocObserver.onError].
/// Captures unhandled exceptions thrown during state emission or event processing.
final class BlocErrorLog extends BlocLifecycleLog {
  factory BlocErrorLog({
    required BlocBase<dynamic> bloc,
    required Object thrown,
    StackTrace? stackTrace,
  }) {
    final typeName = bloc.runtimeType.toString();
    return BlocErrorLog._internal(
      bloc: bloc,
      thrown: thrown,
      stackTrace: stackTrace,
      typeName: typeName,
    );
  }

  BlocErrorLog._internal({
    required super.bloc,
    required this.thrown,
    required String typeName,
    StackTrace? stackTrace,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final errorType = thrown.runtimeType;
            return '$typeName threw an error'
                '\nERROR: $errorType';
          },
          exception: thrown is Exception ? thrown : null,
          error: thrown is Error ? thrown : null,
          stackTrace: _normalizeStackTrace(stackTrace),
          logLevel: LogLevel.error,
        );

  final Object thrown;

  static const String logKey = 'bloc-error';
}
