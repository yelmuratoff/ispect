import 'package:ispect/ispect.dart';

final class HostileExportException implements Exception {
  int calls = 0;

  Object toJson() {
    calls++;
    throw StateError('toJson must not run during copy');
  }

  @override
  String toString() {
    calls++;
    throw StateError('toString must not run during copy');
  }
}

final class HostileExportError implements Error {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('Error.toString must not run during copy');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Error member must not run during copy');
  }
}

final class HostileExportStackTrace implements StackTrace {
  int calls = 0;

  @override
  String toString() {
    calls++;
    throw StateError('StackTrace.toString must not run during copy');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('StackTrace member must not run during copy');
  }
}

({
  ISpectLogData log,
  HostileExportException exception,
  HostileExportError error,
  HostileExportStackTrace stackTrace,
})
hostileCopyLog(String secret) {
  final exception = HostileExportException();
  final error = HostileExportError();
  final stackTrace = HostileExportStackTrace();
  final message =
      'token=$secret${''.padRight(LogExportOutput.maxRecordBytes * 2, 'x')}';
  return (
    log: ISpectLogData(
      message,
      exception: exception,
      error: error,
      stackTrace: stackTrace,
    ),
    exception: exception,
    error: error,
    stackTrace: stackTrace,
  );
}
