import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/factory/log_factory.dart';
import 'package:ispectify/src/logger/log_pipeline.dart';
import 'package:ispectify/src/observer/observer_manager.dart';

/// A customizable logging and inspection utility for mobile applications.
///
/// `ISpectLogger` provides a comprehensive logging system with features such as:
/// - Multiple log levels (debug, info, warning, error, critical, verbose)
/// - Custom log filtering
/// - Error and exception handling
/// - Log history tracking
/// - Stream-based log monitoring
/// - Specialized log types (analytics, routes, providers, etc.)
///
/// ### Example usage:
///
/// ```dart
/// final inspector = ISpectLogger();
/// inspector.info('Application started');
/// inspector.error('Failed to connect', NetworkException(), StackTrace.current);
///
/// // Listen to logs
/// inspector.stream.listen((log) {
///   // Handle log data
/// });
/// ```
class ISpectLogger {
  /// Creates an instance of `ISpectLogger` with optional components.
  ///
  /// All parameters are optional and will be initialized with defaults if not provided.
  ///
  /// - `logger`: Custom implementation of the logging mechanism.
  /// - `observer`: For observing and reacting to log events.
  /// - `options`: Configuration options for the inspector.
  /// - `filter`: For filtering which logs should be processed.
  /// - `errorHandler`: Custom error handling logic.
  /// - `history`: Custom implementation for storing log history.
  ISpectLogger({
    ISpectBaseLogger? logger,
    ISpectObserver? observer,
    ISpectLoggerOptions? options,
    ISpectFilter? filter,
    ISpectErrorHandler? errorHandler,
    ILogHistory? history,
  }) : _loggerStreamController =
            StreamController<ISpectLogData>.broadcast(sync: true) {
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

  /// Broadcast stream controller for log events.
  final StreamController<ISpectLogData> _loggerStreamController;

  bool _isDisposed = false;

  /// Indicates whether this logger has been disposed and can no longer emit logs.
  bool get isDisposed => _isDisposed;

  late ISpectLoggerOptions _options;

  /// Current configuration options for this inspector instance.
  ISpectLoggerOptions get options => _options;

  late ISpectBaseLogger _logger;
  late ISpectErrorHandler _errorHandler;
  ISpectFilter? _filter;
  late LogPipeline _pipeline;

  /// Observers notified of log events.
  late final ObserverManager _observerManager;

  void _replaceObserver(ISpectObserver? observer) {
    if (_isDisposed) return;
    _observerManager.replace(observer);
  }

  late ILogHistory _history;

  bool _ensureActive() => !_isDisposed;

  // ======= OBSERVER METHODS =======

  /// Adds an observer to be notified of log events.
  ///
  /// Multiple observers can be registered, and all will be notified.
  ///
  /// - `observer`: The observer to add.
  void addObserver(ISpectObserver observer) {
    if (!_ensureActive()) return;
    _observerManager.add(observer);
  }

  /// Registers an observer and returns a disposer to remove it later.
  ISpectObserverDisposer observe(ISpectObserver observer) {
    if (!_ensureActive()) return () {};
    return _observerManager.observe(observer);
  }

  /// Removes an observer from the list of registered observers.
  ///
  /// - `observer`: The observer to remove.
  void removeObserver(ISpectObserver observer) {
    if (!_ensureActive()) return;
    _observerManager.remove(observer);
  }

  /// Removes all registered observers.
  void clearObservers() {
    if (!_ensureActive()) return;
    _observerManager.clear();
  }

  /// Indicates whether at least one observer is registered.
  bool get hasObservers => _observerManager.hasObservers;

  /// Helper method to notify all observers with error handling.
  ///
  /// Wraps each observer call in a try-catch to prevent one failing
  /// observer from affecting others.
  void _notifyObservers(void Function(ISpectObserver) notify) {
    if (!_ensureActive()) return;
    _observerManager.notify(notify);
  }

  /// Reconfigures the inspector with new components.
  ///
  /// This method allows updating the configuration of an existing inspector
  /// instance. Only the provided parameters will be updated; others will
  /// retain their current values.
  ///
  /// - `logger`: New logger implementation.
  /// - `options`: New configuration options.
  /// - `observer`: New observer for log events.
  /// - `filter`: New filter for log processing.
  /// - `errorHandler`: New error handler implementation.
  /// - `history`: New history storage implementation.
  void configure({
    ISpectBaseLogger? logger,
    ISpectLoggerOptions? options,
    ISpectObserver? observer,
    ISpectFilter? filter,
    ISpectErrorHandler? errorHandler,
    ILogHistory? history,
  }) {
    if (!_ensureActive()) return;

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
    } else {
      // Rebuild default handler when options change.
      _errorHandler = ISpectErrorHandler(_options);
    }

    if (history != null) {
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

  /// Stream controller for broadcasting log events.
  /// Stream of log data that can be subscribed to for real-time monitoring.
  ///
  /// This stream broadcasts all log events that pass through the filter.
  /// Multiple listeners can subscribe to this stream.
  Stream<ISpectLogData> get stream => _loggerStreamController.stream;

  /// List of all log entries stored in history.
  List<ISpectLogData> get history => _history.history;

  ILogHistory get logHistory => _history;

  FileLogHistory? get fileLogHistory =>
      _history is FileLogHistory ? _history as FileLogHistory : null;

  // ======= OPTIONS METHODS =======

  /// Clears all log entries from history.
  void clearHistory() {
    if (!_ensureActive()) return;
    _history.clear();
  }

  /// Enables the inspector.
  ///
  /// When enabled, log entries will be processed and stored.
  void enable() {
    if (!_ensureActive()) return;
    _options.enabled = true;
  }

  /// Disables the inspector.
  ///
  /// When disabled, log entries will not be processed or stored.
  void disable() {
    if (!_ensureActive()) return;
    _options.enabled = false;
  }

  // ======= LOGGING METHODS =======

  /// Handles exceptions and errors.
  ///
  /// This method processes exceptions and creates appropriate log entries.
  /// The type of log created depends on the exception and the configured
  /// error handler.
  ///
  /// - `exception`: The exception or error to handle.
  /// - `stackTrace`: Optional stack trace associated with the exception.
  /// - `msg`: Optional message to include with the exception.
  void handle({
    required Object exception,
    StackTrace? stackTrace,
    Object? message,
  }) {
    if (!_ensureActive()) return;

    final data =
        _errorHandler.handle(exception, stackTrace, message?.toString());

    // Use polymorphic dispatch to notify observers
    _notifyObservers(data.notifyObserver);
    _processLog(data, skipObserverNotification: true);
  }

  /// Creates a log entry with custom parameters.
  ///
  /// This is the primary logging method that other specialized methods use.
  ///
  /// - `message`: The main log message.
  /// - `logLevel`: The severity level of the log. If not provided, will be inferred from `type` or default to `LogLevel.debug`.
  /// - `type`: The log type that may imply a specific severity level.
  /// - `exception`: Optional exception associated with the log.
  /// - `stackTrace`: Optional stack trace for the log.
  /// - `pen`: Optional styling for console output.
  /// - `additionalData`: Optional metadata attached to the log entry.
  void log(
    Object? message, {
    LogLevel? logLevel,
    ISpectLogType? type,
    Object? exception,
    StackTrace? stackTrace,
    AnsiPen? pen,
    Map<String, dynamic>? additionalData,
  }) {
    // Determine the appropriate log level
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

  /// Logs a custom `ISpectLogData` instance directly.
  ///
  /// This allows for creating fully customized log entries.
  ///
  /// - `log`: The custom log data to process.
  void logData(ISpectLogData log) {
    if (!_ensureActive()) return;
    _processLog(log);
  }

  /// Creates a critical level log entry.
  ///
  /// Critical logs indicate severe issues that require immediate attention.
  ///
  /// - `msg`: The log message.
  /// - `exception`: Optional exception associated with the log.
  /// - `stackTrace`: Optional stack trace for the log.
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

  /// Creates a debug level log entry.
  ///
  /// Debug logs are for detailed information useful during development.
  ///
  /// - `msg`: The log message.
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

  /// Creates an error level log entry.
  ///
  /// Error logs indicate failure of some operation.
  ///
  /// - `msg`: The log message.
  /// - `exception`: Optional exception associated with the log.
  /// - `stackTrace`: Optional stack trace for the log.
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

  /// Creates an info level log entry.
  ///
  /// Info logs are for general information about system operation.
  ///
  /// - `msg`: The log message.
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

  /// Creates a verbose level log entry.
  ///
  /// Verbose logs contain the most detailed information.
  ///
  /// - `msg`: The log message.
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

  /// Creates a warning level log entry.
  ///
  /// Warning logs indicate potential issues that aren't errors.
  ///
  /// - `msg`: The log message.
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

  /// Creates a "good" log entry.
  ///
  /// Good logs indicate successful operations or positive outcomes.
  ///
  /// - `message`: The log message.
  void good(String message) {
    _processLog(
      GoodLog(message),
    );
  }

  /// Creates an analytics tracking log entry.
  ///
  /// These logs are used for tracking events that might be sent to analytics services.
  ///
  /// - `message`: The log message.
  /// - `event`: Optional event name.
  /// - `analytics`: Optional analytics service identifier.
  /// - `parameters`: Optional parameters associated with the event.
  void track(
    String message, {
    String? event,
    String? analytics,
    Map<String, dynamic>? parameters,
  }) {
    _processLog(
      AnalyticsLog(
        '${event ?? 'Event'}: $message\nParameters: $parameters',
        analytics: analytics,
      ),
    );
  }

  /// Creates a basic print log entry.
  ///
  /// - `message`: The log message.
  void print(String message) {
    _processLog(PrintLog(message));
  }

  /// Creates a route log entry.
  ///
  /// These logs are used for tracking navigation events in the application.
  ///
  /// - `message`: The log message, typically a route name or path.
  void route(
    String message, {
    String? transitionId,
  }) {
    _processLog(RouteLog(message, transitionId: transitionId));
  }

  /// Creates a provider log entry.
  ///
  /// These logs are used for tracking state management or dependency injection events.
  ///
  /// - `message`: The log message.
  void provider(String message) {
    _processLog(ProviderLog(message));
  }

  /// Internal method to handle basic log creation.
  ///
  /// This method creates a standard `ISpectLogData` instance and passes it
  /// to `_handleLogData` for processing.
  void _handleLog({
    Object? message,
    Object? exception,
    StackTrace? stackTrace,
    ISpectLogType? type,
    LogLevel? logLevel,
    AnsiPen? pen,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_ensureActive()) return;

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

  /// Processes a log entry based on the provided `ISpectLogData`.
  ///
  /// This method performs the following steps:
  /// 1. Verifies that the logger is still active.
  /// 2. Uses the [_pipeline] to determine whether the log should be processed.
  /// 3. Notifies observers when the log is accepted.
  /// 4. Delegates side-effects (stream broadcast, history, console) to the pipeline.
  ///
  /// Parameters:
  /// - `data`: The log entry to process, encapsulated in an `ISpectLogData` object.
  /// - `isError`: A boolean flag indicating whether the log entry is an error. Defaults to `false`.
  void _processLog(
    ISpectLogData data, {
    bool skipObserverNotification = false,
  }) {
    if (!_ensureActive()) return;
    if (!_pipeline.shouldProcess(data)) return;

    if (!skipObserverNotification) {
      if (data.isError) {
        _notifyObservers((observer) => observer.onError(data));
      } else {
        _notifyObservers((observer) => observer.onLog(data));
      }
    }

    _pipeline.dispatch(data);
  }

  /// Releases resources held by this logger.
  ///
  /// After calling `dispose`, the logger becomes a no-op and no further
  /// events will be emitted through the stream.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _observerManager.clear();
    await _loggerStreamController.close();
  }
}

typedef ISpectObserverDisposer = void Function();
