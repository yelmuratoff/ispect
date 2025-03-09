import 'dart:async';

import 'package:ispectify/ispectify.dart';

/// A customizable logging and inspection utility for mobile applications.
///
/// [ISpectify] provides a comprehensive logging system with features such as:
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
/// final inspector = ISpectify();
/// inspector.info('Application started');
/// inspector.error('Failed to connect', NetworkException(), StackTrace.current);
///
/// // Listen to logs
/// inspector.stream.listen((log) {
///   // Handle log data
/// });
/// ```
class ISpectify {
  /// Creates an instance of [ISpectify] with optional components.
  ///
  /// All parameters are optional and will be initialized with defaults if not provided.
  ///
  /// - [logger]: Custom implementation of the logging mechanism.
  /// - [observer]: For observing and reacting to log events.
  /// - [options]: Configuration options for the inspector.
  /// - [filter]: For filtering which logs should be processed.
  /// - [errorHandler]: Custom error handling logic.
  /// - [history]: Custom implementation for storing log history.
  ISpectify({
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyOptions? options,
    ISpectifyFilter? filter,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  }) {
    _init(filter, options, logger, observer, errorHandler, history);
  }

  /// Initializes all components of the inspector.
  ///
  /// This method is called from the constructor to set up the instance
  /// with provided or default components.
  void _init(
    ISpectifyFilter? filter,
    ISpectifyOptions? settings,
    ISpectifyLogger? logger,
    ISpectifyObserver? observer,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  ) {
    _filter = filter;
    _observer = observer;
    _options = settings ?? ISpectifyOptions();
    _logger = logger ?? ISpectifyLogger();
    _errorHandler = errorHandler ?? ISpectifyErrorHandler(_options);
    _history = history ?? DefaultISpectifyHistory(_options);
  }

  late ISpectifyOptions _options;

  /// Current configuration options for this inspector instance.
  ISpectifyOptions get options => _options;

  late ISpectifyLogger _logger;
  late ISpectifyErrorHandler _errorHandler;
  late ISpectifyFilter? _filter;
  late ISpectifyObserver? _observer;
  late LogHistory _history;

  /// Reconfigures the inspector with new components.
  ///
  /// This method allows updating the configuration of an existing inspector
  /// instance. Only the provided parameters will be updated; others will
  /// retain their current values.
  ///
  /// - [logger]: New logger implementation.
  /// - [options]: New configuration options.
  /// - [observer]: New observer for log events.
  /// - [filter]: New filter for log processing.
  /// - [errorHandler]: New error handler implementation.
  /// - [history]: New history storage implementation.
  void configure({
    ISpectifyLogger? logger,
    ISpectifyOptions? options,
    ISpectifyObserver? observer,
    ISpectifyFilter? filter,
    ISpectifyErrorHandler? errorHandler,
    LogHistory? history,
  }) {
    _filter = filter ?? _filter; // Fixed null-aware assignment
    _options = options ?? _options;
    _observer = observer ?? _observer;
    _logger = logger ?? _logger;
    _errorHandler = errorHandler ?? ISpectifyErrorHandler(_options);
    _history =
        history ?? DefaultISpectifyHistory(_options, history: _history.history);
  }

  /// Stream controller for broadcasting log events.
  final _iSpectifyStreamController =
      StreamController<ISpectifyData>.broadcast();

  /// Stream of log data that can be subscribed to for real-time monitoring.
  ///
  /// This stream broadcasts all log events that pass through the filter.
  /// Multiple listeners can subscribe to this stream.
  Stream<ISpectifyData> get stream => _iSpectifyStreamController
      .stream; // Removed redundant .asBroadcastStream()

  /// List of all log entries stored in history.
  List<ISpectifyData> get history => _history.history;

  // ======= OPTIONS METHODS =======

  /// Clears all log entries from history.
  void clearHistory() => _history.clear();

  /// Enables the inspector.
  ///
  /// When enabled, log entries will be processed and stored.
  void enable() => _options.enabled = true;

  /// Disables the inspector.
  ///
  /// When disabled, log entries will not be processed or stored.
  void disable() => _options.enabled = false;

  /// Checks if a log entry is approved by the filter.
  ///
  /// Returns true if there is no filter or if the filter approves the log.
  bool _isApprovedByFilter(ISpectifyData data) => _filter?.apply(data) ?? true;

  // ======= LOGGING METHODS =======

  /// Handles exceptions and errors.
  ///
  /// This method processes exceptions and creates appropriate log entries.
  /// The type of log created depends on the exception and the configured
  /// error handler.
  ///
  /// - [exception]: The exception or error to handle.
  /// - [stackTrace]: Optional stack trace associated with the exception.
  /// - [msg]: Optional message to include with the exception.
  void handle({
    required Object exception,
    StackTrace? stackTrace,
    Object? message,
  }) {
    final data =
        _errorHandler.handle(exception, stackTrace, message?.toString());
    if (data is ISpectifyError) {
      _observer?.onError(data);
      _handleErrorData(data);
      return;
    }
    if (data is ISpectifyException) {
      _observer?.onException(data);
      _handleErrorData(data);
      return;
    }
    _handleLogData(data);
  }

  /// Creates a log entry with custom parameters.
  ///
  /// This is the primary logging method that other specialized methods use.
  ///
  /// - [message]: The main log message.
  /// - [logLevel]: The severity level of the log.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  /// - [pen]: Optional styling for console output.
  void log(
    Object? message, {
    LogLevel logLevel = LogLevel.debug,
    Object? exception,
    StackTrace? stackTrace,
    AnsiPen? pen,
  }) {
    _handleLog(
      message: message,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: logLevel,
      pen: pen,
    );
  }

  /// Logs a custom [ISpectifyData] instance directly.
  ///
  /// This allows for creating fully customized log entries.
  ///
  /// - [log]: The custom log data to process.
  void logCustom(ISpectifyData log) => _handleLogData(log);

  /// Creates a critical level log entry.
  ///
  /// Critical logs indicate severe issues that require immediate attention.
  ///
  /// - [msg]: The log message.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  void critical(
    Object? msg, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.critical,
    );
  }

  /// Creates a debug level log entry.
  ///
  /// Debug logs are for detailed information useful during development.
  ///
  /// - [msg]: The log message.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  void debug(
    Object? msg,
  ) {
    _handleLog(
      message: msg,
    );
  }

  /// Creates an error level log entry.
  ///
  /// Error logs indicate failure of some operation.
  ///
  /// - [msg]: The log message.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  void error(
    Object? msg, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _handleLog(
      message: msg,
      exception: exception,
      stackTrace: stackTrace,
      logLevel: LogLevel.error,
    );
  }

  /// Creates an info level log entry.
  ///
  /// Info logs are for general information about system operation.
  ///
  /// - [msg]: The log message.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  void info(
    Object? msg,
  ) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.info,
    );
  }

  /// Creates a verbose level log entry.
  ///
  /// Verbose logs contain the most detailed information.
  ///
  /// - [msg]: The log message.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  void verbose(
    Object? msg,
  ) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.verbose,
    );
  }

  /// Creates a warning level log entry.
  ///
  /// Warning logs indicate potential issues that aren't errors.
  ///
  /// - [msg]: The log message.
  /// - [exception]: Optional exception associated with the log.
  /// - [stackTrace]: Optional stack trace for the log.
  void warning(
    Object? msg,
  ) {
    _handleLog(
      message: msg,
      logLevel: LogLevel.warning,
    );
  }

  /// Creates a "good" log entry.
  ///
  /// Good logs indicate successful operations or positive outcomes.
  ///
  /// - [message]: The log message.
  void good(String message) {
    _handleLogData(
      GoodLog(message),
    );
  }

  /// Creates an analytics tracking log entry.
  ///
  /// These logs are used for tracking events that might be sent to analytics services.
  ///
  /// - [message]: The log message.
  /// - [event]: Optional event name.
  /// - [analytics]: Optional analytics service identifier.
  /// - [parameters]: Optional parameters associated with the event.
  void track(
    String message, {
    String? event,
    String? analytics,
    Map<String, dynamic>? parameters,
  }) {
    _handleLogData(
      AnalyticsLog(
        analytics: analytics,
        '${event ?? 'Event'}: $message\nParameters: ${prettyJson(parameters)}',
      ),
    );
  }

  /// Creates a basic print log entry.
  ///
  /// - [message]: The log message.
  void print(String message) {
    _handleLogData(PrintLog(message));
  }

  /// Creates a route log entry.
  ///
  /// These logs are used for tracking navigation events in the application.
  ///
  /// - [message]: The log message, typically a route name or path.
  void route(String message) {
    _handleLogData(RouteLog(message));
  }

  /// Creates a provider log entry.
  ///
  /// These logs are used for tracking state management or dependency injection events.
  ///
  /// - [message]: The log message.
  void provider(String message) {
    _handleLogData(ProviderLog(message));
  }

  /// Internal method to handle basic log creation.
  ///
  /// This method creates a standard [ISpectifyData] instance and passes it
  /// to [_handleLogData] for processing.
  void _handleLog({
    Object? message,
    Object? exception,
    StackTrace? stackTrace,
    LogLevel? logLevel,
    AnsiPen? pen,
  }) {
    final type = ISpectifyLogType.fromLogLevel(logLevel);
    final data = ISpectifyData(
      key: type.key,
      message?.toString() ?? '',
      title: _options.titleByKey(type.key),
      exception: exception,
      stackTrace: stackTrace,
      pen: pen ?? _options.penByKey(type.key),
      logLevel: logLevel,
    );
    _handleLogData(data);
  }

  /// Handles error-specific log data.
  ///
  /// This method processes error logs, checking if logging is enabled and
  /// if the log passes the filter before adding it to the stream and outputs.
  void _handleErrorData(ISpectifyData data) {
    if (!_options.enabled) {
      return;
    }

    final isApproved = _isApprovedByFilter(data);
    if (!isApproved) {
      return;
    }

    _iSpectifyStreamController.add(data);
    _handleForOutputs(data);

    if (_options.useConsoleLogs) {
      _logger.log(
        '${data.header}${data.textMessage}',
        level: data.logLevel ?? LogLevel.error,
      );
    }
  }

  /// Handles standard log data.
  ///
  /// This is the main processing pipeline for log entries. It checks if
  /// logging is enabled and if the log passes the filter before notifying
  /// observers, adding to the stream, and sending to outputs.
  void _handleLogData(
    ISpectifyData data, {
    LogLevel? logLevel,
  }) {
    if (!_options.enabled) {
      return;
    }

    final isApproved = _isApprovedByFilter(data);
    if (!isApproved) {
      return;
    }

    _observer?.onLog(data);
    _iSpectifyStreamController.add(data);
    _handleForOutputs(data);

    if (_options.useConsoleLogs) {
      _logger.log(
        '${data.header}${data.textMessage}',
        level: logLevel ?? data.logLevel,
        pen: data.pen ?? _options.penByKey(data.key),
      );
    }
  }

  /// Handles log data for output destinations.
  ///
  /// Currently, this only adds the log to history, but could be extended
  /// to handle other output destinations.
  void _handleForOutputs(ISpectifyData data) {
    _history.add(data);
  }
}
