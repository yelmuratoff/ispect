part of 'base.dart';

/// Log emitted when an event handler completes (successfully or with error).
///
/// Corresponds to [BlocObserver.onDone].
/// Called after an event handler finishes processing, regardless of success or failure.
/// May include error details if the handler threw an exception.
final class BlocDoneLog extends BlocLifecycleLog {
  BlocDoneLog({
    required Bloc<dynamic, dynamic> super.bloc,
    required this.settings,
    required this.event,
    required this.hasError,
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final payload = settings.printEventFullData
                ? event
                : event?.runtimeType ?? 'null';
            final status = hasError ? 'failed' : 'completed';
            return event == null
                ? '${bloc.runtimeType} event handler $status'
                : '${bloc.runtimeType} event handler $status'
                    '\nEVENT: $payload';
          },
          exception: error is Exception ? error : null,
          error: error is Error ? error : null,
          stackTrace: stackTrace != null && stackTrace != StackTrace.empty
              ? stackTrace
              : null,
          logLevel: hasError ? LogLevel.error : LogLevel.info,
          additionalData: <String, dynamic>{
            if (event != null) 'event': event,
            'completed-with-error': hasError,
          },
        );

  final ISpectBlocSettings settings;
  final Object? event;
  final bool hasError;

  static const String logKey = 'bloc-done';
}
