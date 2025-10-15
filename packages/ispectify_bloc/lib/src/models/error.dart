part of 'base.dart';

final class BlocErrorLog extends BlocLifecycleLog {
  BlocErrorLog({
    required super.bloc,
    required this.thrown,
    StackTrace? stackTrace,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () => '${bloc.runtimeType} threw $thrown',
          exception: thrown is Exception ? thrown : null,
          error: thrown is Error ? thrown : null,
          stackTrace: stackTrace != null && stackTrace != StackTrace.empty
              ? stackTrace
              : null,
          additionalData: <String, dynamic>{
            'error': thrown,
            if (stackTrace != null && stackTrace != StackTrace.empty)
              'stackTrace': stackTrace,
          },
        );

  final Object thrown;

  static const String logKey = 'bloc-error';
}
