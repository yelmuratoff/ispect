part of 'base.dart';

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
            final subject = event == null
                ? bloc.runtimeType
                : '${bloc.runtimeType} ← $payload';
            return hasError
                ? '$subject handler failed'
                : '$subject handler completed';
          },
          exception: error is Exception ? error : null,
          error: error is Error ? error : null,
          stackTrace: stackTrace != null && stackTrace != StackTrace.empty
              ? stackTrace
              : null,
          additionalData: <String, dynamic>{
            if (event != null) 'event': event,
            'completedWithError': hasError,
            if (error != null) 'error': error,
            if (stackTrace != null && stackTrace != StackTrace.empty)
              'stackTrace': stackTrace,
          },
        );

  final ISpectBlocSettings settings;
  final Object? event;
  final bool hasError;

  static const String logKey = 'bloc-done';
}
