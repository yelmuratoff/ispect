import 'package:ispectify/ispectify.dart';

/// Enum representing various log types used in the ISpectify library.
///
/// Each log type is associated with a unique string key and can be mapped
/// to a corresponding `LogLevel` using the provided extension.
///
/// - **General Log Types**:
///   - `error`: Represents an error log.
///   - `critical`: Represents a critical log.
///   - `info`: Represents an informational log.
///   - `debug`: Represents a debug log.
///   - `verbose`: Represents a verbose log.
///   - `warning`: Represents a warning log.
///   - `exception`: Represents an exception log.
///
/// - **HTTP Log Types**:
///   - `httpError`: Represents an HTTP error log.
///   - `httpRequest`: Represents an HTTP request log.
///   - `httpResponse`: Represents an HTTP response log.
///
/// - **Bloc Log Types**:
///   - `blocEvent`: Represents a Bloc event log.
///   - `blocTransition`: Represents a Bloc transition log.
///   - `blocClose`: Represents a Bloc close log.
///   - `blocCreate`: Represents a Bloc creation log.
///   - `blocState`: Represents a Bloc state log.
///
/// - **Riverpod Log Types**:
///   - `riverpodAdd`: Represents a Riverpod addition log.
///   - `riverpodUpdate`: Represents a Riverpod update log.
///   - `riverpodDispose`: Represents a Riverpod disposal log.
///   - `riverpodFail`: Represents a Riverpod failure log.
///
/// - **Miscellaneous Log Types**:
///   - `route`: Represents a route log.
///   - `good`: Represents a positive or successful log.
///   - `analytics`: Represents an analytics log.
///   - `provider`: Represents a provider log.
///   - `print`: Represents a print log.
///
/// Each log type can be mapped to a `LogLevel` using the `level` getter
/// provided in the `ISpectifyLogTypeExt` extension. The `fromLogLevel`
/// method allows conversion from a `LogLevel` to the corresponding
/// `ISpectifyLogType`.
///
/// Example:
/// ```dart
/// final logType = ISpectifyLogType.fromLogLevel(LogLevel.error);
/// print(logType.key); // Outputs: "error"
/// ```
enum ISpectifyLogType {
  error('error'),
  critical('critical'),
  info('info'),
  debug('debug'),
  verbose('verbose'),
  warning('warning'),
  exception('exception'),

  httpError('http-error'),
  httpRequest('http-request'),
  httpResponse('http-response'),

  blocEvent('bloc-event'),
  blocTransition('bloc-transition'),
  blocClose('bloc-close'),
  blocCreate('bloc-create'),
  blocState('bloc-state'),

  riverpodAdd('riverpod-add'),
  riverpodUpdate('riverpod-update'),
  riverpodDispose('riverpod-dispose'),
  riverpodFail('riverpod-fail'),

  dbQuery('db-query'),
  dbResult('db-result'),
  dbError('db-error'),

  route('route'),
  good('good'),
  analytics('analytics'),
  provider('provider'),
  print('print');

  const ISpectifyLogType(this.key);

  final String key;

  /// Converts a `LogLevel` to its corresponding [ISpectifyLogType].
  ///
  /// If the provided `logLevel` is `null`, the method defaults to returning
  /// `ISpectifyLogType.debug`.
  ///
  /// Throws a `StateError` if no matching [ISpectifyLogType] is found for the
  /// given `logLevel`.
  ///
  /// - Parameter `logLevel`: The [LogLevel` to be converted.
  /// - Returns: The corresponding `ISpectifyLogType` for the given [logLevel].
  static ISpectifyLogType fromLogLevel(LogLevel? logLevel) {
    if (logLevel == null) return ISpectifyLogType.debug;

    return ISpectifyLogType.values.firstWhere((e) => e.level == logLevel);
  }

  static Set<String> get keys =>
      ISpectifyLogType.values.map((e) => e.key).toSet();

  bool get isErrorType => switch (this) {
        ISpectifyLogType.error ||
        ISpectifyLogType.critical ||
        ISpectifyLogType.exception ||
        ISpectifyLogType.httpError ||
        ISpectifyLogType.riverpodFail ||
        ISpectifyLogType.dbError =>
          true,
        _ => false,
      };
}

extension ISpectifyLogTypeExt on ISpectifyLogType {
  /// Maps the current `ISpectifyLogType` instance to its corresponding `LogLevel`.
  ///
  /// Returns:
  /// - `LogLevel.error` for `ISpectifyLogType.error`.
  /// - `LogLevel.critical` for `ISpectifyLogType.critical`.
  /// - `LogLevel.info` for `ISpectifyLogType.info`.
  /// - `LogLevel.debug` for `ISpectifyLogType.debug`.
  /// - `LogLevel.verbose` for `ISpectifyLogType.verbose`.
  /// - `LogLevel.warning` for `ISpectifyLogType.warning`.
  /// - Defaults to `LogLevel.info` for any other cases.
  LogLevel get level => switch (this) {
        ISpectifyLogType.error => LogLevel.error,
        ISpectifyLogType.critical => LogLevel.critical,
        ISpectifyLogType.exception => LogLevel.error,
        ISpectifyLogType.httpError => LogLevel.error,
        ISpectifyLogType.riverpodFail => LogLevel.error,
        ISpectifyLogType.dbError => LogLevel.error,
        ISpectifyLogType.info => LogLevel.info,
        ISpectifyLogType.debug => LogLevel.debug,
        ISpectifyLogType.verbose => LogLevel.verbose,
        ISpectifyLogType.warning => LogLevel.warning,
        _ => LogLevel.info,
      };
}
