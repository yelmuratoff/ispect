import 'package:ispectify/ispectify.dart';

class DbErrorData {
  DbErrorData({
    required this.durationMs,
    this.exception,
    this.stackTrace,
    this.driverError,
  });

  final int durationMs;
  final Object? exception;
  final StackTrace? stackTrace;
  final Object? driverError;

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      {
        'duration-ms': durationMs,
        'exception': exception?.toString(),
        'stack-trace': stackTrace?.toString(),
        'driver-error': driverError,
      };
}
