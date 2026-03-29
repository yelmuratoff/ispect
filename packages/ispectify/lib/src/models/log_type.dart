import 'package:ispectify/ispectify.dart';

/// Log type categories, each with a unique string [key] and [category].
///
/// Use [fromLogLevel] to map a [LogLevel] to its canonical type,
/// or [fromKey] for reverse lookup by string key.
enum ISpectLogType {
  // ── Network ─────────────────────────────────────────────────────────
  httpRequest('http-request', category: TraceCategoryIds.network),
  httpResponse('http-response', category: TraceCategoryIds.network),
  httpError('http-error', category: TraceCategoryIds.network),

  // ── WebSocket ───────────────────────────────────────────────────────
  wsSent('ws-sent', category: TraceCategoryIds.ws),
  wsReceived('ws-received', category: TraceCategoryIds.ws),
  wsError('ws-error', category: TraceCategoryIds.ws),

  // ── State management ────────────────────────────────────────────────
  blocEvent('bloc-event', category: TraceCategoryIds.state),
  blocTransition('bloc-transition', category: TraceCategoryIds.state),
  blocState('bloc-state', category: TraceCategoryIds.state),
  blocCreate('bloc-create', category: TraceCategoryIds.state),
  blocClose('bloc-close', category: TraceCategoryIds.state),
  blocDone('bloc-done', category: TraceCategoryIds.state),
  blocError('bloc-error', category: TraceCategoryIds.state),
  riverpodAdd('riverpod-add', category: TraceCategoryIds.state),
  riverpodUpdate('riverpod-update', category: TraceCategoryIds.state),
  riverpodDispose('riverpod-dispose', category: TraceCategoryIds.state),
  riverpodFail('riverpod-fail', category: TraceCategoryIds.state),
  stateChange('state-change', category: TraceCategoryIds.state),
  stateError('state-error', category: TraceCategoryIds.state),

  // ── Database ────────────────────────────────────────────────────────
  dbQuery('db-query', category: TraceCategoryIds.db),
  dbResult('db-result', category: TraceCategoryIds.db),
  dbError('db-error', category: TraceCategoryIds.db),

  // ── Auth ────────────────────────────────────────────────────────────
  authSuccess('auth-success', category: TraceCategoryIds.auth),
  authError('auth-error', category: TraceCategoryIds.auth),

  // ── Storage ─────────────────────────────────────────────────────────
  storageResult('storage-result', category: TraceCategoryIds.storage),
  storageQuery('storage-query', category: TraceCategoryIds.storage),
  storageError('storage-error', category: TraceCategoryIds.storage),

  // ── Push ────────────────────────────────────────────────────────────
  pushReceived('push-received', category: TraceCategoryIds.push),
  pushSent('push-sent', category: TraceCategoryIds.push),
  pushError('push-error', category: TraceCategoryIds.push),

  // ── Payment ─────────────────────────────────────────────────────────
  paymentSuccess('payment-success', category: TraceCategoryIds.payment),
  paymentError('payment-error', category: TraceCategoryIds.payment),

  // ── SSE ─────────────────────────────────────────────────────────────
  sseReceived('sse-received', category: TraceCategoryIds.sse),
  sseError('sse-error', category: TraceCategoryIds.sse),

  // ── gRPC ────────────────────────────────────────────────────────────
  grpcRequest('grpc-request', category: TraceCategoryIds.grpc),
  grpcResponse('grpc-response', category: TraceCategoryIds.grpc),
  grpcError('grpc-error', category: TraceCategoryIds.grpc),

  // ── GraphQL ─────────────────────────────────────────────────────────
  graphqlRequest('graphql-request', category: TraceCategoryIds.graphql),
  graphqlResponse('graphql-response', category: TraceCategoryIds.graphql),
  graphqlError('graphql-error', category: TraceCategoryIds.graphql),

  // ── Navigation ──────────────────────────────────────────────────────
  route('route', category: TraceCategoryIds.navigation),

  // ── Analytics ───────────────────────────────────────────────────────
  analytics('analytics', category: TraceCategoryIds.analytics),

  // ── General (no specific category) ──────────────────────────────────
  error('error'),
  critical('critical'),
  info('info'),
  debug('debug'),
  verbose('verbose'),
  warning('warning'),
  exception('exception'),
  good('good'),
  print('print'),
  provider('provider'),
  ;

  const ISpectLogType(this.key, {this.category = TraceCategoryIds.general});

  final String key;

  /// Category ID for grouping in UI. References [TraceCategoryIds] constants.
  final String category;

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
        ISpectLogType.blocError ||
        ISpectLogType.riverpodFail ||
        ISpectLogType.dbError ||
        ISpectLogType.wsError ||
        ISpectLogType.authError ||
        ISpectLogType.storageError ||
        ISpectLogType.pushError ||
        ISpectLogType.paymentError ||
        ISpectLogType.stateError ||
        ISpectLogType.sseError ||
        ISpectLogType.grpcError ||
        ISpectLogType.graphqlError =>
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
        ISpectLogType.blocError => LogLevel.error,
        ISpectLogType.riverpodFail => LogLevel.error,
        ISpectLogType.dbError => LogLevel.error,
        ISpectLogType.wsError ||
        ISpectLogType.authError ||
        ISpectLogType.storageError ||
        ISpectLogType.pushError ||
        ISpectLogType.paymentError ||
        ISpectLogType.stateError ||
        ISpectLogType.sseError ||
        ISpectLogType.grpcError ||
        ISpectLogType.graphqlError =>
          LogLevel.error,
        ISpectLogType.info => LogLevel.info,
        ISpectLogType.debug => LogLevel.debug,
        ISpectLogType.verbose => LogLevel.verbose,
        ISpectLogType.warning => LogLevel.warning,
        _ => LogLevel.info,
      };

  static final Map<ISpectLogType, AnsiPen> _defaultPens = {
    // Error types
    ISpectLogType.critical: AnsiPen()..red(),
    ISpectLogType.error: AnsiPen()..red(),
    ISpectLogType.exception: AnsiPen()..red(),
    ISpectLogType.httpError: AnsiPen()..red(),
    ISpectLogType.blocError: AnsiPen()..red(),
    ISpectLogType.riverpodFail: AnsiPen()..red(),
    ISpectLogType.dbError: AnsiPen()..red(),
    ISpectLogType.wsError: AnsiPen()..red(),
    ISpectLogType.authError: AnsiPen()..red(),
    ISpectLogType.storageError: AnsiPen()..red(),
    ISpectLogType.pushError: AnsiPen()..red(),
    ISpectLogType.paymentError: AnsiPen()..red(),
    ISpectLogType.stateError: AnsiPen()..red(),
    ISpectLogType.sseError: AnsiPen()..red(),
    ISpectLogType.grpcError: AnsiPen()..red(),
    ISpectLogType.graphqlError: AnsiPen()..red(),
    // Warning / verbose / general
    ISpectLogType.warning: AnsiPen()..xterm(172),
    ISpectLogType.verbose: AnsiPen()..xterm(08),
    ISpectLogType.info: AnsiPen()..blue(),
    ISpectLogType.debug: AnsiPen()..gray(),
    // Network
    ISpectLogType.httpRequest: AnsiPen()..xterm(207),
    ISpectLogType.httpResponse: AnsiPen()..xterm(35),
    // BLoC
    ISpectLogType.blocEvent: AnsiPen()..xterm(51),
    ISpectLogType.blocTransition: AnsiPen()..xterm(49),
    ISpectLogType.blocCreate: AnsiPen()..xterm(35),
    ISpectLogType.blocClose: AnsiPen()..xterm(198),
    ISpectLogType.blocState: AnsiPen()..xterm(38),
    ISpectLogType.blocDone: AnsiPen()..green(),
    // Riverpod
    ISpectLogType.riverpodAdd: AnsiPen()..xterm(51),
    ISpectLogType.riverpodUpdate: AnsiPen()..xterm(49),
    ISpectLogType.riverpodDispose: AnsiPen()..xterm(198),
    // DB
    ISpectLogType.dbQuery: AnsiPen()..blue(),
    ISpectLogType.dbResult: AnsiPen()..green(),
    // WebSocket
    ISpectLogType.wsSent: AnsiPen()..xterm(207),
    ISpectLogType.wsReceived: AnsiPen()..xterm(35),
    // Navigation / misc
    ISpectLogType.route: AnsiPen()..xterm(135),
    ISpectLogType.good: AnsiPen()..green(),
    ISpectLogType.analytics: AnsiPen()..yellow(),
    ISpectLogType.provider: AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9),
    ISpectLogType.print: AnsiPen()..blue(),
    // Auth
    ISpectLogType.authSuccess: AnsiPen()..green(),
    // Storage
    ISpectLogType.storageResult: AnsiPen()..green(),
    ISpectLogType.storageQuery: AnsiPen()..blue(),
    // Push
    ISpectLogType.pushReceived: AnsiPen()..xterm(208),
    ISpectLogType.pushSent: AnsiPen()..xterm(207),
    // Payment
    ISpectLogType.paymentSuccess: AnsiPen()..green(),
    // State
    ISpectLogType.stateChange: AnsiPen()..xterm(49),
    // SSE
    ISpectLogType.sseReceived: AnsiPen()..xterm(35),
    // gRPC
    ISpectLogType.grpcRequest: AnsiPen()..xterm(207),
    ISpectLogType.grpcResponse: AnsiPen()..xterm(35),
    // GraphQL
    ISpectLogType.graphqlRequest: AnsiPen()..xterm(141),
    ISpectLogType.graphqlResponse: AnsiPen()..xterm(35),
  };

  /// Built-in ANSI color for this log type.
  AnsiPen get defaultPen => _defaultPens[this] ?? ConsoleUtils.fallbackPen;
}
