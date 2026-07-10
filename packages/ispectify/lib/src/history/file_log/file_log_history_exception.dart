sealed class FileLogHistoryException implements Exception {
  const FileLogHistoryException({
    required this.kind,
    required this.operation,
    this.path,
    this.cause,
    this.stackTrace,
  });

  final String kind;
  final String operation;
  final String? path;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'FileLogHistoryException(kind: $kind, operation: $operation'
      '${path == null ? '' : ', path: $path'})';
}

final class FileLogStorageException extends FileLogHistoryException {
  const FileLogStorageException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'storage');
}

final class FileLogFormatException extends FileLogHistoryException {
  const FileLogFormatException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'format');
}

final class FileLogAccessException extends FileLogHistoryException {
  const FileLogAccessException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'access');
}

final class FileLogLimitException extends FileLogHistoryException {
  const FileLogLimitException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'limit');
}
