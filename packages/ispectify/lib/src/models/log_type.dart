import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/logger/console_utils.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/trace/trace_category_ids.dart';
import 'package:meta/meta.dart';

/// Describes a log type — built-in or user-defined.
///
/// Built-in types are exposed as `static const` fields (e.g.
/// [ISpectLogType.httpRequest]). Custom types are created the same way:
///
/// ```dart
/// const firebaseRead = ISpectLogType(
///   'firebase-read',
///   category: 'firebase',
///   level: LogLevel.debug,
///   title: 'Firebase Read',
/// );
/// ```
///
/// Register custom types with the UI filter via `ISpectTheme.customLogTypes`.
/// Set colors and icons per-key via `ISpectTheme.logColors` /
/// `ISpectTheme.logIcons`. Category labels go in `ISpectTheme.categoryLabels`.
@immutable
final class ISpectLogType {
  const ISpectLogType(
    this.key, {
    this.category = TraceCategoryIds.general,
    this.isError = false,
    this.level = LogLevel.info,
    this.title,
  });

  /// Unique string identifier used throughout the pipeline (e.g. `'http-request'`).
  final String key;

  /// Category ID for grouping in the filter UI. May be any string.
  /// Built-in IDs live in [TraceCategoryIds].
  final String category;

  /// Whether logs of this type represent an error condition.
  final bool isError;

  /// Severity level used when this type is passed to [ISpectLogger.log].
  final LogLevel level;

  /// Human-readable display name shown in filter chips.
  /// Falls back to a formatted version of [key] when `null`
  /// (e.g. `'http-request'` → `'Http Request'`).
  final String? title;

  // ── General ────────────────────────────────────────────────────────────────
  static const error = ISpectLogType(
    'error',
    isError: true,
    level: LogLevel.error,
  );
  static const critical = ISpectLogType(
    'critical',
    isError: true,
    level: LogLevel.critical,
  );
  static const exception = ISpectLogType(
    'exception',
    isError: true,
    level: LogLevel.error,
  );
  static const info = ISpectLogType('info');
  static const debug = ISpectLogType('debug', level: LogLevel.debug);
  static const verbose = ISpectLogType('verbose', level: LogLevel.verbose);
  static const warning = ISpectLogType('warning', level: LogLevel.warning);
  static const good = ISpectLogType('good');
  static const print = ISpectLogType('print');
  static const provider = ISpectLogType('provider');
  static const analytics = ISpectLogType(
    'analytics',
    category: TraceCategoryIds.analytics,
  );

  // ── Network ────────────────────────────────────────────────────────────────
  static const httpRequest = ISpectLogType(
    'http-request',
    category: TraceCategoryIds.network,
  );
  static const httpResponse = ISpectLogType(
    'http-response',
    category: TraceCategoryIds.network,
  );
  static const httpError = ISpectLogType(
    'http-error',
    category: TraceCategoryIds.network,
    isError: true,
    level: LogLevel.error,
  );

  // ── WebSocket ──────────────────────────────────────────────────────────────
  static const wsSent = ISpectLogType(
    'ws-sent',
    category: TraceCategoryIds.ws,
  );
  static const wsReceived = ISpectLogType(
    'ws-received',
    category: TraceCategoryIds.ws,
  );
  static const wsError = ISpectLogType(
    'ws-error',
    category: TraceCategoryIds.ws,
    isError: true,
    level: LogLevel.error,
  );
  static const wsState = ISpectLogType(
    'ws-state',
    category: TraceCategoryIds.ws,
  );

  // ── State (BLoC / Riverpod) ────────────────────────────────────────────────
  static const blocEvent = ISpectLogType(
    'bloc-event',
    category: TraceCategoryIds.state,
  );
  static const blocTransition = ISpectLogType(
    'bloc-transition',
    category: TraceCategoryIds.state,
  );
  static const blocState = ISpectLogType(
    'bloc-state',
    category: TraceCategoryIds.state,
  );
  static const blocCreate = ISpectLogType(
    'bloc-create',
    category: TraceCategoryIds.state,
  );
  static const blocClose = ISpectLogType(
    'bloc-close',
    category: TraceCategoryIds.state,
  );
  static const blocDone = ISpectLogType(
    'bloc-done',
    category: TraceCategoryIds.state,
  );
  static const blocError = ISpectLogType(
    'bloc-error',
    category: TraceCategoryIds.state,
    isError: true,
    level: LogLevel.error,
  );
  static const riverpodAdd = ISpectLogType(
    'riverpod-add',
    category: TraceCategoryIds.state,
  );
  static const riverpodUpdate = ISpectLogType(
    'riverpod-update',
    category: TraceCategoryIds.state,
  );
  static const riverpodDispose = ISpectLogType(
    'riverpod-dispose',
    category: TraceCategoryIds.state,
  );
  static const riverpodFail = ISpectLogType(
    'riverpod-fail',
    category: TraceCategoryIds.state,
    isError: true,
    level: LogLevel.error,
  );
  static const stateChange = ISpectLogType(
    'state-change',
    category: TraceCategoryIds.state,
  );
  static const stateError = ISpectLogType(
    'state-error',
    category: TraceCategoryIds.state,
    isError: true,
    level: LogLevel.error,
  );

  // ── Database ───────────────────────────────────────────────────────────────
  static const dbQuery = ISpectLogType(
    'db-query',
    category: TraceCategoryIds.db,
  );
  static const dbResult = ISpectLogType(
    'db-result',
    category: TraceCategoryIds.db,
  );
  static const dbError = ISpectLogType(
    'db-error',
    category: TraceCategoryIds.db,
    isError: true,
    level: LogLevel.error,
  );

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const authSuccess = ISpectLogType(
    'auth-success',
    category: TraceCategoryIds.auth,
  );
  static const authError = ISpectLogType(
    'auth-error',
    category: TraceCategoryIds.auth,
    isError: true,
    level: LogLevel.error,
  );

  // ── Storage ────────────────────────────────────────────────────────────────
  static const storageResult = ISpectLogType(
    'storage-result',
    category: TraceCategoryIds.storage,
  );
  static const storageQuery = ISpectLogType(
    'storage-query',
    category: TraceCategoryIds.storage,
  );
  static const storageError = ISpectLogType(
    'storage-error',
    category: TraceCategoryIds.storage,
    isError: true,
    level: LogLevel.error,
  );

  // ── Push ───────────────────────────────────────────────────────────────────
  static const pushReceived = ISpectLogType(
    'push-received',
    category: TraceCategoryIds.push,
  );
  static const pushSent = ISpectLogType(
    'push-sent',
    category: TraceCategoryIds.push,
  );
  static const pushError = ISpectLogType(
    'push-error',
    category: TraceCategoryIds.push,
    isError: true,
    level: LogLevel.error,
  );

  // ── Payment ────────────────────────────────────────────────────────────────
  static const paymentSuccess = ISpectLogType(
    'payment-success',
    category: TraceCategoryIds.payment,
  );
  static const paymentError = ISpectLogType(
    'payment-error',
    category: TraceCategoryIds.payment,
    isError: true,
    level: LogLevel.error,
  );

  // ── SSE ────────────────────────────────────────────────────────────────────
  static const sseReceived = ISpectLogType(
    'sse-received',
    category: TraceCategoryIds.sse,
  );
  static const sseError = ISpectLogType(
    'sse-error',
    category: TraceCategoryIds.sse,
    isError: true,
    level: LogLevel.error,
  );

  // ── gRPC ───────────────────────────────────────────────────────────────────
  static const grpcRequest = ISpectLogType(
    'grpc-request',
    category: TraceCategoryIds.grpc,
  );
  static const grpcResponse = ISpectLogType(
    'grpc-response',
    category: TraceCategoryIds.grpc,
  );
  static const grpcError = ISpectLogType(
    'grpc-error',
    category: TraceCategoryIds.grpc,
    isError: true,
    level: LogLevel.error,
  );

  // ── GraphQL ────────────────────────────────────────────────────────────────
  static const graphqlRequest = ISpectLogType(
    'graphql-request',
    category: TraceCategoryIds.graphql,
  );
  static const graphqlResponse = ISpectLogType(
    'graphql-response',
    category: TraceCategoryIds.graphql,
  );
  static const graphqlError = ISpectLogType(
    'graphql-error',
    category: TraceCategoryIds.graphql,
    isError: true,
    level: LogLevel.error,
  );

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const route = ISpectLogType(
    'route',
    category: TraceCategoryIds.navigation,
  );

  // ── Performance ────────────────────────────────────────────────────────────
  static const performanceJank = ISpectLogType(
    'performance-jank',
    category: TraceCategoryIds.performance,
    level: LogLevel.warning,
  );
  static const performanceError = ISpectLogType(
    'performance-error',
    category: TraceCategoryIds.performance,
    isError: true,
    level: LogLevel.error,
  );

  // ── Discovery ──────────────────────────────────────────────────────────────

  /// All built-in log types. Used for filter UI and key discovery.
  static const List<ISpectLogType> builtIn = [
    error,
    critical,
    exception,
    info,
    debug,
    verbose,
    warning,
    good,
    print,
    provider,
    analytics,
    httpRequest,
    httpResponse,
    httpError,
    wsSent,
    wsReceived,
    wsError,
    wsState,
    blocEvent,
    blocTransition,
    blocState,
    blocCreate,
    blocClose,
    blocDone,
    blocError,
    riverpodAdd,
    riverpodUpdate,
    riverpodDispose,
    riverpodFail,
    stateChange,
    stateError,
    dbQuery,
    dbResult,
    dbError,
    authSuccess,
    authError,
    storageResult,
    storageQuery,
    storageError,
    pushReceived,
    pushSent,
    pushError,
    paymentSuccess,
    paymentError,
    sseReceived,
    sseError,
    grpcRequest,
    grpcResponse,
    grpcError,
    graphqlRequest,
    graphqlResponse,
    graphqlError,
    route,
    performanceJank,
    performanceError,
  ];

  static final Map<String, ISpectLogType> _byKey = {
    for (final t in builtIn) t.key: t,
  };

  static final Map<LogLevel, ISpectLogType> _byLevel = {
    LogLevel.critical: critical,
    LogLevel.error: error,
    LogLevel.warning: warning,
    LogLevel.info: info,
    LogLevel.debug: debug,
    LogLevel.verbose: verbose,
  };

  /// Returns the canonical built-in type for [logLevel].
  /// Defaults to [debug] when [logLevel] is `null`.
  static ISpectLogType fromLogLevel(LogLevel? logLevel) {
    if (logLevel == null) return debug;
    final type = _byLevel[logLevel];
    if (type == null) throw StateError('No log type for level $logLevel');
    return type;
  }

  /// Looks up a built-in type by its [key]. Returns `null` for unknown keys.
  static ISpectLogType? fromKey(String key) => _byKey[key];

  /// Set of all built-in type keys.
  static Set<String> get keys => _byKey.keys.toSet();

  /// Returns `true` if [key] belongs to a built-in error type.
  static bool isErrorKey(String? key) =>
      key != null && (_byKey[key]?.isError ?? false);

  // ── ANSI console colors ────────────────────────────────────────────────────

  static final Map<String, AnsiPen> _defaultPens = {
    // errors
    'error': AnsiPen()..red(),
    'critical': AnsiPen()..red(),
    'exception': AnsiPen()..red(),
    'http-error': AnsiPen()..red(),
    'bloc-error': AnsiPen()..red(),
    'riverpod-fail': AnsiPen()..red(),
    'db-error': AnsiPen()..red(),
    'ws-error': AnsiPen()..red(),
    'auth-error': AnsiPen()..red(),
    'storage-error': AnsiPen()..red(),
    'push-error': AnsiPen()..red(),
    'payment-error': AnsiPen()..red(),
    'state-error': AnsiPen()..red(),
    'sse-error': AnsiPen()..red(),
    'grpc-error': AnsiPen()..red(),
    'graphql-error': AnsiPen()..red(),
    // general
    'warning': AnsiPen()..xterm(172),
    'verbose': AnsiPen()..xterm(8),
    'info': AnsiPen()..blue(),
    'debug': AnsiPen()..gray(),
    // network
    'http-request': AnsiPen()..xterm(207),
    'http-response': AnsiPen()..xterm(35),
    // bloc
    'bloc-event': AnsiPen()..xterm(51),
    'bloc-transition': AnsiPen()..xterm(49),
    'bloc-create': AnsiPen()..xterm(35),
    'bloc-close': AnsiPen()..xterm(198),
    'bloc-state': AnsiPen()..xterm(38),
    'bloc-done': AnsiPen()..green(),
    // riverpod
    'riverpod-add': AnsiPen()..xterm(51),
    'riverpod-update': AnsiPen()..xterm(49),
    'riverpod-dispose': AnsiPen()..xterm(198),
    // db
    'db-query': AnsiPen()..blue(),
    'db-result': AnsiPen()..green(),
    // websocket
    'ws-sent': AnsiPen()..xterm(207),
    'ws-received': AnsiPen()..xterm(35),
    'ws-state': AnsiPen()..xterm(44),
    // navigation / misc
    'route': AnsiPen()..xterm(135),
    'good': AnsiPen()..green(),
    'analytics': AnsiPen()..yellow(),
    'provider': AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9),
    'print': AnsiPen()..blue(),
    // auth
    'auth-success': AnsiPen()..green(),
    // storage
    'storage-result': AnsiPen()..green(),
    'storage-query': AnsiPen()..blue(),
    // push
    'push-received': AnsiPen()..xterm(208),
    'push-sent': AnsiPen()..xterm(207),
    // payment
    'payment-success': AnsiPen()..green(),
    // state
    'state-change': AnsiPen()..xterm(49),
    // sse
    'sse-received': AnsiPen()..xterm(35),
    // grpc
    'grpc-request': AnsiPen()..xterm(207),
    'grpc-response': AnsiPen()..xterm(35),
    // graphql
    'graphql-request': AnsiPen()..xterm(141),
    'graphql-response': AnsiPen()..xterm(35),
  };

  /// Built-in ANSI console color for this log type.
  AnsiPen get defaultPen => _defaultPens[key] ?? ConsoleUtils.fallbackPen;

  // ── Display ────────────────────────────────────────────────────────────────

  /// Human-readable display title.
  ///
  /// Returns [title] if explicitly set; otherwise returns [key] as-is.
  String get displayTitle => title ?? key;

  // ── Value semantics ────────────────────────────────────────────────────────

  /// Two types are equal when their [key] matches.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ISpectLogType && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ISpectLogType($key)';
}
