import 'package:ispectify/ispectify.dart';

/// Enum representing various log types used in the ISpectLogger library.
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
/// provided in the `ISpectLogTypeExt` extension. The `fromLogLevel`
/// method allows conversion from a `LogLevel` to the corresponding
/// `ISpectLogType`.
///
/// Example:
/// ```dart
/// final logType = ISpectLogType.fromLogLevel(LogLevel.error);
/// print(logType.key); // Outputs: "error"
/// ```
enum ISpectLogType {
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
  blocDone('bloc-done'),
  blocError('bloc-error'),

  riverpodAdd('riverpod-add'),
  riverpodUpdate('riverpod-update'),
  riverpodDispose('riverpod-dispose'),
  riverpodFail('riverpod-fail'),

  dbQuery('db-query'),
  dbResult('db-result'),
  dbError('db-error'),

  wsSent('ws-sent'),
  wsReceived('ws-received'),

  route('route'),
  good('good'),
  analytics('analytics'),
  provider('provider'),
  print('print');

  const ISpectLogType(this.key);

  final String key;

  static final Map<String, ISpectLogType> _byKey = {
    for (final type in ISpectLogType.values) type.key: type,
  };

  static final Map<LogLevel, ISpectLogType> _byLevel = {
    LogLevel.critical: ISpectLogType.critical,
    LogLevel.error: ISpectLogType.error,
    LogLevel.warning: ISpectLogType.warning,
    LogLevel.info: ISpectLogType.info,
    LogLevel.debug: ISpectLogType.debug,
    LogLevel.verbose: ISpectLogType.verbose,
  };

  static final Set<String> _errorKeys = {
    for (final type in ISpectLogType.values)
      if (type.isErrorType) type.key,
  };

  /// Converts a `LogLevel` to its corresponding [ISpectLogType].
  ///
  /// If the provided `logLevel` is `null`, the method defaults to returning
  /// `ISpectLogType.debug`.
  ///
  /// Throws a `StateError` if no matching [ISpectLogType] is found for the
  /// given `logLevel`.
  ///
  /// - Parameter `logLevel`: The [LogLevel` to be converted.
  /// - Returns: The corresponding `ISpectLogType` for the given [logLevel].
  static ISpectLogType fromLogLevel(LogLevel? logLevel) {
    if (logLevel == null) return ISpectLogType.debug;

    final type = _byLevel[logLevel];
    if (type == null) {
      throw StateError('No log type registered for level $logLevel');
    }
    return type;
  }

  static ISpectLogType? fromKey(String key) => _byKey[key];

  static Set<String> get keys => _byKey.keys.toSet();

  static bool isErrorKey(String? key) =>
      key != null && _errorKeys.contains(key);

  bool get isErrorType => switch (this) {
        ISpectLogType.error ||
        ISpectLogType.critical ||
        ISpectLogType.exception ||
        ISpectLogType.httpError ||
        ISpectLogType.riverpodFail ||
        ISpectLogType.dbError =>
          true,
        _ => false,
      };
}

extension ISpectLogTypeExt on ISpectLogType {
  /// Maps the current `ISpectLogType` instance to its corresponding `LogLevel`.
  ///
  /// Returns:
  /// - `LogLevel.error` for `ISpectLogType.error`.
  /// - `LogLevel.critical` for `ISpectLogType.critical`.
  /// - `LogLevel.info` for `ISpectLogType.info`.
  /// - `LogLevel.debug` for `ISpectLogType.debug`.
  /// - `LogLevel.verbose` for `ISpectLogType.verbose`.
  /// - `LogLevel.warning` for `ISpectLogType.warning`.
  /// - Defaults to `LogLevel.info` for any other cases.
  LogLevel get level => switch (this) {
        ISpectLogType.error => LogLevel.error,
        ISpectLogType.critical => LogLevel.critical,
        ISpectLogType.exception => LogLevel.error,
        ISpectLogType.httpError => LogLevel.error,
        ISpectLogType.riverpodFail => LogLevel.error,
        ISpectLogType.dbError => LogLevel.error,
        ISpectLogType.blocError => LogLevel.error,
        ISpectLogType.info => LogLevel.info,
        ISpectLogType.debug => LogLevel.debug,
        ISpectLogType.verbose => LogLevel.verbose,
        ISpectLogType.warning => LogLevel.warning,
        _ => LogLevel.info,
      };

  /// Returns the default ANSI pen (color) for this log type.
  ///
  /// These are the built-in colors that will be used if no custom
  /// override is provided via `ISpectLoggerOptions`.
  AnsiPen get defaultPen => switch (this) {
        ISpectLogType.critical => AnsiPen()..red(),
        ISpectLogType.error => AnsiPen()..red(),
        ISpectLogType.exception => AnsiPen()..red(),
        ISpectLogType.httpError => AnsiPen()..red(),
        ISpectLogType.blocError => AnsiPen()..red(),
        ISpectLogType.riverpodFail => AnsiPen()..red(),
        ISpectLogType.dbError => AnsiPen()..red(),
        ISpectLogType.warning => AnsiPen()..xterm(172),
        ISpectLogType.verbose => AnsiPen()..xterm(08),
        ISpectLogType.info => AnsiPen()..blue(),
        ISpectLogType.debug => AnsiPen()..gray(),
        ISpectLogType.httpRequest => AnsiPen()..xterm(207),
        ISpectLogType.httpResponse => AnsiPen()..xterm(35),
        ISpectLogType.blocEvent => AnsiPen()..xterm(51),
        ISpectLogType.blocTransition => AnsiPen()..xterm(49),
        ISpectLogType.blocCreate => AnsiPen()..xterm(35),
        ISpectLogType.blocClose => AnsiPen()..xterm(198),
        ISpectLogType.blocState => AnsiPen()..xterm(38),
        ISpectLogType.blocDone => AnsiPen()..green(),
        ISpectLogType.riverpodAdd => AnsiPen()..xterm(51),
        ISpectLogType.riverpodUpdate => AnsiPen()..xterm(49),
        ISpectLogType.riverpodDispose => AnsiPen()..xterm(198),
        ISpectLogType.route => AnsiPen()..xterm(135),
        ISpectLogType.good => AnsiPen()..green(),
        ISpectLogType.analytics => AnsiPen()..yellow(),
        ISpectLogType.provider => AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9),
        ISpectLogType.print => AnsiPen()..blue(),
        ISpectLogType.dbQuery => AnsiPen()..blue(),
        ISpectLogType.dbResult => AnsiPen()..green(),
        ISpectLogType.wsSent => AnsiPen()..xterm(207),
        ISpectLogType.wsReceived => AnsiPen()..xterm(35),
      };
}
