import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocDoneLog extends ISpectifyData {
  BlocDoneLog({
    required this.bloc,
    required this.settings,
    required this.event,
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          () {
            final buffer = StringBuffer()
              ..write('${bloc.runtimeType} completed handler');
            if (event != null) {
              buffer
                ..write(' for ')
                ..write(
                  settings.printEventFullData ? event : event.runtimeType,
                );
            }
            return buffer.toString();
          }(),
          key: logKey,
          title: logKey,
          exception: error is Exception ? error : null,
          error: error is Error ? error : null,
          stackTrace: stackTrace != null && stackTrace != StackTrace.empty
              ? stackTrace
              : null,
          additionalData: <String, dynamic>{
            if (event != null) 'event': event,
            if (error != null) 'error': error,
            if (stackTrace != null && stackTrace != StackTrace.empty)
              'stackTrace': stackTrace,
          },
        );

  final Bloc<dynamic, dynamic> bloc;
  final ISpectBlocSettings settings;
  final Object? event;

  static const String logKey = 'bloc-done';
}
