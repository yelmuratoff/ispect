import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_pipeline.dart';
import 'package:ispectify/src/models/log_factory.dart';
import 'package:ispectify/src/observer/observer_manager.dart';

/// Customizable logging and inspection utility for mobile applications.
///
/// ```dart
/// final inspector = ISpectLogger();
/// inspector.info('Application started');
/// inspector.error('Failed to connect', NetworkException(), StackTrace.current);
///
/// inspector.stream.listen((log) {
///   // Handle log data
/// });
/// ```
class ISpectLogger {
  ISpectLogger({
    ISpectBaseLogger? logger,
    ISpectObserver? observer,
    ISpectLoggerOptions? options,
    ISpectFilter? filter,
    ISpectErrorHandler? errorHandler,
    ILogHistory? history,
  })  : _hasCustomErrorHandler = errorHandler != null,
        _loggerStreamController = StreamController<ISpectLogData>.broadcast() {
    final resolvedOptions = options ?? ISpectLoggerOptions();
    _options = resolvedOptions;
    _logger = logger ?? ISpectBaseLogger();
    _filter = filter;
    _errorHandler = errorHandler ?? ISpectErrorHandler(resolvedOptions);
    _history = history ?? DefaultISpectLoggerHistory(resolvedOptions);
    _pipeline = LogPipeline(
      streamController: _loggerStreamController,
      options: _options,
      consoleLogger: _logger,
      history: _history,
      filter: _filter,
    );
    _observerManager = ObserverManager(() => _logger);
    _replaceObserver(observer);
  }

  final StreamController<ISpectLogData> _loggerStreamController;

  bool _hasCustomErrorHandler;

  bool _isDisposed = false;

  /// Whether this logger has been disposed and can no longer emit logs.
  bool get isDisposed => _isDisposed;

  late ISpectLoggerOptions _options;

  ISpectLoggerOptions get options => _options;

  late ISpectBaseLogger _logger;
  late ISpectErrorHandler _errorHandler;
  ISpectFilter? _filter;
  late LogPipeline _pipeline;

  late final ObserverManager _observerManager;

  void _replaceObserver(ISpectObserver? observer) {
    if (_isDisposed) return;
    _observerManager.replace(observer);
  }

  late ILogHistory _history;

  bool get _isActive => !_isDisposed;

  // ======= OBSERVER METHODS =======

  /// Registers an observer. Remains active until [removeObserver] or
  /// [clearObservers] is called. Prefer [observe] when you want automatic
  /// cleanup via a disposer callback.
  ///
  /// Observers are notified synchronously on the same call stack that emitted
  /// the log. A re-entrant `log(...)` call from inside an observer is dropped
  /// to prevent recursion (see [stream] for the same guard on listeners).
  void addObserver(ISpectObserver observer) {
    if (!_isActive) return;
    _observerManager.add(observer);
  }

  /// Registers an observer and returns a disposer to remove it later — useful
  /// for scoped subscriptions (e.g. widget lifecycle).
  ISpectObserverDisposer observe(ISpectObserver observer) {
    if (!_isActive) return () {};
    return _observerManager.observe(observer);
  }

  void removeObserver(ISpectObserver observer) {
    if (!_isActive) return;
    _observerManager.remove(observer);
  }

  void clearObservers() {
    if (!_isActive) return;
    _observerManager.clear();
  }

  bool get hasObservers => _observerManager.hasObservers;

  /// Wraps each observer call in a try-catch so a single failing observer
  /// cannot break notification for the rest.
  void _notifyObservers(void Function(ISpectObserver) notify) {
    if (!_isActive) return;
    _observerManager.notify(notify);
  }

  /// Replaces only the provided components; others retain their current values.
  void configure({
    ISpectBaseLogger? logger,
    ISpectLoggerOptions? options,
    ISpectObserver? observer,
    ISpectFilter? filter,
    ISpectErrorHandler? errorHandler,
    ILogHistory? history,
  }) {
    if (!_isActive) return;

    if (filter != null) {
      _filter = filter;
    }

    if (observer != null) {
      _replaceObserver(observer);
    }

    if (options != null) {
      _options = options;
    }

    if (logger != null) {
      _logger = logger;
    }

    if (errorHandler != null) {
      _errorHandler = errorHandler;
      _hasCustomErrorHandler = true;
    } else if (!_hasCustomErrorHandler) {
      // Rebuild default handler when options change, but only if no custom
      // handler was ever provided (via constructor or previous configure call).
      _errorHandler = ISpectErrorHandler(_options);
    }

    if (history != null) {
      // Dispose the old history to release resources (e.g. auto-save timers
      // in FileLogHistory) before replacing it.
      _history.dispose();
      _history = history;
    } else if (_history is DefaultISpectLoggerHistory) {
      // Rebuild default history to inherit updated options while
      // keeping the accumulated entries.
      _history = DefaultISpectLoggerHistory(
        _options,
        history: _history.history,
      );
    }

    _pipeline.update(
      options: _options,
      consoleLogger: _logger,
      history: _history,
      filter: _filter,
    );
  }

  void clearFilter() {
    if (!_isActive) return;
    _filter = null;
    _pipeline.clearFilter();
  }

  /// Broadcast stream of log events that pass through the filter. Multiple
  /// listeners may subscribe.
  ///
  /// Listeners are notified synchronously. A re-entrant `log(...)` call from
  /// inside a listener is dropped to prevent recursion; if you need to log
  /// from a listener, schedule it (e.g. `Future.microtask`) so it runs on a
  /// fresh stack.
  Stream<ISpectLogData> get stream => _loggerStreamController.stream;

  List<ISpectLogData> get history => _history.history;

  ILogHistory get logHistory => _history;

  FileLogHistory? get fileLogHistory =>
      _history is FileLogHistory ? _history as FileLogHistory : null;

  // ======= OPTIONS METHODS =======

  void clearHistory() {
    if (!_isActive) return;
    _history.clear();
  }

  void enable() {
    if (!_isActive) return;
    _options = _options.copyWith(enabled: true);
    _pipeline.update(options: _options);
  }

  void disable() {
    if (!_isActive) return;
    _options = _options.copyWith(enabled: false);
    _pipeline.update(options: _options);
  }

  // ======= LOGGING METHODS =======

  /// Routes [exception] through the configured [ISpectErrorHandler] to produce
  /// a typed log entry.
  void handle({
    required Object exception,
    StackTrace? stackTrace,
    Object? message,
  }) {
    if (!_isActive) return;

    final data =
        _errorHandler.handle(exception, stackTrace, message?.toString());

    _processLog(data);
  }

  /// Logs [message] with an explicit [logLevel] and/or [type]. When [type] is
  /// omitted, it is inferred from [logLevel]; when both are omitted, defaults
  /// to [LogLevel.debug].
  ///
  /// Pass a custom [type] for domain-specific keys, e.g.
  /// `const ISpectLogType('my-key', category: 'firebase')`.
  void log(
    Object? message, {
    LogLevel? logLevel,
    ISpectLogType? type,
    Object? exception,
    StackTrace? stackTrace,
    AnsiPen? pen,
    Map<String, dynamic>? additionalData,
  }) {
    final effectiveLogLevel = logLevel ?? (type?.level ?? LogLevel.debug);

    _handleLog(
      message: message,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: effectiveLogLevel,
      pen: pen,
      type: type,
      additionalData: additionalData,
    );
  }

  /// Emits a pre-built [ISpectLogData] entry as-is.
  void logData(ISpectLogData log) {
    if (!_isActive) return;
    _processLog(log);
  }

  void critical(
    Object? msg, {
    Object? exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.critical,
      pen: pen,
      additionalData: additionalData,
    );
  }

  void debug(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.debug,
      pen: pen,
      additionalData: additionalData,
    );
  }

  void error(
    Object? msg, {
    Object? exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.error,
      pen: pen,
      additionalData: additionalData,
    );
  }

  void info(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.info,
      pen: pen,
      additionalData: additionalData,
    );
  }

  void verbose(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.verbose,
      pen: pen,
      additionalData: additionalData,
    );
  }

  void warning(
    Object? msg, {
    Map<String, dynamic>? additionalData,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.warning,
      pen: pen,
      additionalData: additionalData,
    );
  }

  void good(Object? message) {
    _processLog(
      LogFactory.fromType(
        type: ISpectLogType.good,
        message: message,
        options: _options,
      ),
    );
  }

  /// Emits an analytics-flavored entry. [event] is the action name, [analytics]
  /// is the destination service identifier, [parameters] are forwarded payload.
  void track(
    Object? message, {
    String? event,
    String? analytics,
    Map<String, dynamic>? parameters,
  }) {
    _processLog(
      LogFactory.fromType(
        type: ISpectLogType.analytics,
        message: '${event ?? 'Event'}: $message\nParameters: $parameters',
        options: _options,
      ),
    );
  }

  void print(Object? message) {
    _processLog(
      LogFactory.fromType(
        type: ISpectLogType.print,
        message: message,
        options: _options,
      ),
    );
  }

  /// Emits a navigation entry. [transitionId] correlates the entry with a
  /// specific transition via [TraceKeys.correlationId].
  void route(
    Object? message, {
    String? transitionId,
  }) {
    _processLog(
      LogFactory.fromType(
        type: ISpectLogType.route,
        message: message,
        options: _options,
        additionalData: <String, dynamic>{
          if (transitionId != null) TraceKeys.correlationId: transitionId,
          TraceKeys.category: TraceCategoryIds.navigation,
        },
      ),
    );
  }

  void provider(Object? message) {
    _processLog(
      LogFactory.fromType(
        type: ISpectLogType.provider,
        message: message,
        options: _options,
      ),
    );
  }

  void _handleLog({
    Object? message,
    Object? exception,
    StackTrace? stackTrace,
    ISpectLogType? type,
    LogLevel? logLevel,
    AnsiPen? pen,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isActive) return;

    final logType = type ?? ISpectLogType.fromLogLevel(logLevel);
    final data = LogFactory.fromType(
      type: logType,
      level: logLevel,
      message: message,
      exception: exception,
      stackTrace: stackTrace,
      pen: pen,
      options: _options,
      additionalData: additionalData,
    );

    _processLog(data);
  }

  /// Runs filter check, notifies observers, then delegates fan-out (stream,
  /// history, console) to the pipeline.
  /// Guards the whole emit path (observers + pipeline) against re-entrancy:
  /// a `log(...)` call made synchronously from inside an observer is dropped
  /// rather than recursing. Safe without a lock in Dart's single-threaded loop.
  bool _isProcessing = false;

  void _processLog(ISpectLogData data) {
    if (!_isActive) return;
    if (_isProcessing) return;
    if (!_pipeline.shouldProcess(data)) return;

    _isProcessing = true;
    try {
      _notifyObservers(data.notifyObserver);
      _pipeline.dispatch(data);
    } finally {
      _isProcessing = false;
    }
  }

  /// Closes the stream, drops observers, releases history resources. After
  /// this call the logger becomes a no-op.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _observerManager.clear();
    try {
      if (_history case final FileLogHistory fileHistory) {
        await fileHistory.saveToDailyFile();
      }
    } finally {
      _history.dispose();
      await _loggerStreamController.close();
    }
  }
}

typedef ISpectObserverDisposer = void Function();
