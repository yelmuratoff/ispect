part of 'base.dart';

/// Log emitted when an event handler completes (successfully or with error).
///
/// Corresponds to [BlocObserver.onDone].
/// Called after an event handler finishes processing, regardless of success or failure.
/// May include error details if the handler threw an exception.
final class BlocDoneLog extends BlocLifecycleLog {
  factory BlocDoneLog({
    required Bloc<dynamic, dynamic> bloc,
    required ISpectBlocSettings settings,
    required Object? event,
    required bool hasError,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final typeName = bloc.runtimeType.toString();
    return BlocDoneLog._internal(
      bloc: bloc,
      settings: settings,
      event: event,
      hasError: hasError,
      error: error,
      stackTrace: stackTrace,
      typeName: typeName,
    );
  }

  BlocDoneLog._internal({
    required Bloc<dynamic, dynamic> bloc,
    required this.settings,
    required this.event,
    required this.hasError,
    required String typeName,
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          bloc: bloc,
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final status = hasError ? 'failed' : 'completed';
            return event == null
                ? '$typeName event handler $status'
                : '$typeName event handler $status'
                    '\nEVENT: ${settings.formatEvent(event)}';
          },
          exception: error is Exception ? error : null,
          error: error is Error ? error : null,
          stackTrace: normalizeStackTrace(stackTrace),
          logLevel: hasError ? LogLevel.error : LogLevel.info,
          additionalData: settings.redactAdditionalData(<String, dynamic>{
            if (event != null) 'event': event,
            'completed-with-error': hasError,
          }),
        );

  final ISpectBlocSettings settings;
  final Object? event;
  final bool hasError;

  static const String logKey = 'bloc-done';
}
