import 'package:ispectify/ispectify.dart';

/// Log type categories, each with a unique string [key].
///
/// Use [fromLogLevel] to map a [LogLevel] to its canonical type,
/// or [fromKey] for reverse lookup by string key.
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

  /// Returns the canonical [ISpectLogType] for [logLevel].
  /// Defaults to [debug] when [logLevel] is `null`.
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

  static final Map<ISpectLogType, AnsiPen> _defaultPens = {
    ISpectLogType.critical: AnsiPen()..red(),
    ISpectLogType.error: AnsiPen()..red(),
    ISpectLogType.exception: AnsiPen()..red(),
    ISpectLogType.httpError: AnsiPen()..red(),
    ISpectLogType.blocError: AnsiPen()..red(),
    ISpectLogType.riverpodFail: AnsiPen()..red(),
    ISpectLogType.dbError: AnsiPen()..red(),
    ISpectLogType.warning: AnsiPen()..xterm(172),
    ISpectLogType.verbose: AnsiPen()..xterm(08),
    ISpectLogType.info: AnsiPen()..blue(),
    ISpectLogType.debug: AnsiPen()..gray(),
    ISpectLogType.httpRequest: AnsiPen()..xterm(207),
    ISpectLogType.httpResponse: AnsiPen()..xterm(35),
    ISpectLogType.blocEvent: AnsiPen()..xterm(51),
    ISpectLogType.blocTransition: AnsiPen()..xterm(49),
    ISpectLogType.blocCreate: AnsiPen()..xterm(35),
    ISpectLogType.blocClose: AnsiPen()..xterm(198),
    ISpectLogType.blocState: AnsiPen()..xterm(38),
    ISpectLogType.blocDone: AnsiPen()..green(),
    ISpectLogType.riverpodAdd: AnsiPen()..xterm(51),
    ISpectLogType.riverpodUpdate: AnsiPen()..xterm(49),
    ISpectLogType.riverpodDispose: AnsiPen()..xterm(198),
    ISpectLogType.route: AnsiPen()..xterm(135),
    ISpectLogType.good: AnsiPen()..green(),
    ISpectLogType.analytics: AnsiPen()..yellow(),
    ISpectLogType.provider: AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9),
    ISpectLogType.print: AnsiPen()..blue(),
    ISpectLogType.dbQuery: AnsiPen()..blue(),
    ISpectLogType.dbResult: AnsiPen()..green(),
    ISpectLogType.wsSent: AnsiPen()..xterm(207),
    ISpectLogType.wsReceived: AnsiPen()..xterm(35),
  };

  /// Built-in ANSI color for this log type.
  AnsiPen get defaultPen => _defaultPens[this] ?? ConsoleUtils.fallbackPen;
}
