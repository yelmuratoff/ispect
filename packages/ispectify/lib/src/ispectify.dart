import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_pipeline.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_factory.dart';
import 'package:ispectify/src/observer/observer_registry.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart'
    as placeholders;
import 'package:ispectify/src/redaction/egress_provenance.dart';
import 'package:ispectify/src/utils/safe_object_description.dart';
import 'package:meta/meta.dart';

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
  }) : this._(
          logger: logger,
          observer: observer,
          options: options,
          filter: filter,
          errorHandler: errorHandler,
          history: history,
        );

  /// Creates a logger with injectable test dependencies.
  ///
  /// Tests must still run with `-DISPECT_ENABLED=true`; this constructor never
  /// bypasses the same compile-time gate used by production entry points.
  @visibleForTesting
  ISpectLogger.testing({
    ISpectBaseLogger? logger,
    ISpectObserver? observer,
    ISpectLoggerOptions? options,
    ISpectFilter? filter,
    ISpectErrorHandler? errorHandler,
    ILogHistory? history,
  }) : this._(
          logger: logger,
          observer: observer,
          options: options,
          filter: filter,
          errorHandler: errorHandler,
          history: history,
        );

  ISpectLogger._({
    ISpectBaseLogger? logger,
    ISpectObserver? observer,
    ISpectLoggerOptions? options,
    ISpectFilter? filter,
    ISpectErrorHandler? errorHandler,
    ILogHistory? history,
  })  : _hasCustomErrorHandler = errorHandler != null,
        _loggerStreamController = StreamController<ISpectLogData>.broadcast() {
    final resolvedOptions = _guardOptions(options ?? ISpectLoggerOptions());
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
    _replaceObserver(observer);
  }

  ISpectLoggerOptions _guardOptions(ISpectLoggerOptions options) {
    if (_compileGateEnabled) return options;
    return options.copyWith(enabled: false);
  }

  bool get _compileGateEnabled => kISpectEnabled;

  final StreamController<ISpectLogData> _loggerStreamController;

  bool _hasCustomErrorHandler;

  bool _isDisposed = false;
  Future<void>? _disposeFuture;

  /// Whether this logger has been disposed and can no longer emit logs.
  bool get isDisposed => _isDisposed;

  /// Whether this logger can currently capture diagnostics.
  bool get isEnabled => _compileGateEnabled && !_isDisposed && _options.enabled;

  /// Whether an emitted entry currently has at least one destination.
  ///
  /// This is a read-time snapshot: configuration, observers, and stream
  /// subscriptions can change before the next logging call. Custom history
  /// implementations count as consumers because their acceptance policy is
  /// intentionally opaque to the logger.
  bool get hasActiveConsumers =>
      isEnabled && (hasObservers || _pipeline.hasDispatchTarget);

  late ISpectLoggerOptions _options;

  ISpectLoggerOptions get options => _options;

  late ISpectBaseLogger _logger;
  late ISpectErrorHandler _errorHandler;
  ISpectFilter? _filter;
  late LogPipeline _pipeline;

  final ObserverRegistry _observers = ObserverRegistry();

  void _replaceObserver(ISpectObserver? observer) {
    if (_isDisposed || !_compileGateEnabled) return;
    _observers.replace(observer);
  }

  late ILogHistory _history;

  bool get _isActive => !_isDisposed;

  /// Registers an observer. Remains active until [removeObserver] or
  /// [clearObservers] is called. Prefer [observe] when you want automatic
  /// cleanup via a disposer callback.
  ///
  /// Observers are notified synchronously on the same call stack that emitted
  /// the log. A re-entrant `log(...)` call from inside an observer is dropped
  /// to prevent recursion (see [stream] for the same guard on listeners).
  void addObserver(ISpectObserver observer) {
    if (!_isActive || !_compileGateEnabled) return;
    _observers.add(observer);
  }

  /// Registers an observer and returns a disposer to remove it later — useful
  /// for scoped subscriptions (e.g. widget lifecycle).
  ISpectObserverDisposer observe(ISpectObserver observer) {
    if (!_isActive || !_compileGateEnabled) return () {};
    return _observers.observe(observer);
  }

  void removeObserver(ISpectObserver observer) {
    if (!_isActive || !_compileGateEnabled) return;
    _observers.remove(observer);
  }

  void clearObservers() {
    if (!_isActive || !_compileGateEnabled) return;
    _observers.clear();
  }

  bool get hasObservers => _compileGateEnabled && _observers.hasObservers;

  /// Wraps each observer call in a try-catch so a single failing observer
  /// cannot break notification for the rest.
  void _notifyObservers(void Function(ISpectObserver) notify) {
    if (!_isActive || !_compileGateEnabled) return;
    _observers.notify(notify, _logger);
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
      _options = _guardOptions(options);
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
    } else if (options != null && _history is DefaultISpectLoggerHistory) {
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
  /// fresh stack. Stream and history values are sanitized outbound snapshots
  /// by default. Setting [ISpectRedaction.enabled] to `false` opts out of
  /// content masking, while non-executing traversal and output bounds remain
  /// enforced.
  Stream<ISpectLogData> get stream => _loggerStreamController.stream;

  List<ISpectLogData> get history => _history.history;

  ILogHistory get logHistory => _history;

  FileLogHistory? get fileLogHistory =>
      _history is FileLogHistory ? _history as FileLogHistory : null;

  void clearHistory() {
    if (!_isActive) return;
    _history.clear();
  }

  void enable() {
    if (!_isActive) return;
    configure(options: _options.copyWith(enabled: true));
  }

  void disable() {
    if (!_isActive) return;
    configure(options: _options.copyWith(enabled: false));
  }

  /// Routes [exception] through the configured [ISpectErrorHandler] to produce
  /// a typed log entry.
  void handle({
    required Object exception,
    StackTrace? stackTrace,
    Object? message,
  }) {
    if (!hasActiveConsumers) return;

    final data = _errorHandler.handle(exception, stackTrace, message);

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

  /// Emits a pre-built [ISpectLogData] entry.
  ///
  /// [redact] defaults to true. Set it to false only when the caller has made
  /// an explicit local-debugging opt-out and already bounded every field.
  /// Non-executing snapshotting and output budgets still apply.
  void logData(ISpectLogData log, {bool redact = true}) {
    if (!_isActive) return;
    _processLog(log, redact: redact);
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
    if (!hasActiveConsumers) return;
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
    if (!hasActiveConsumers) return;
    final componentBudget = _options.resourceLimits.maxCapturedValueBytes ~/ 2;
    final safeEvent = LogExportOutput.truncateUtf8(
      event ?? 'Event',
      maxBytes: componentBudget,
    );
    final capturedMessage = LogExportOutput.boundJsonValue(
      message,
      maxBytes: componentBudget,
      resourceLimits: _options.resourceLimits,
      allowCustomStringification:
          _options.captureMode == DiagnosticCaptureMode.balanced,
    );
    final safeMessage = safeScalarText(capturedMessage) ?? '';
    _processLog(
      LogFactory.fromType(
        type: ISpectLogType.analytics,
        message: '$safeEvent: $safeMessage',
        options: _options,
        additionalData: analytics == null && parameters == null
            ? null
            : {
                if (analytics != null) 'analytics': analytics,
                if (parameters != null) 'parameters': parameters,
              },
      ),
    );
  }

  void print(Object? message) {
    if (!hasActiveConsumers) return;
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
    if (!hasActiveConsumers) return;
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
    if (!hasActiveConsumers) return;
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
    if (!hasActiveConsumers) return;

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

  void _processLog(ISpectLogData data, {bool redact = true}) {
    if (!_isActive || !_options.enabled) return;
    if (_isProcessing) return;
    if (!hasActiveConsumers) return;
    if (_pipeline.vetoesKey(captureISpectLogWithoutPayload(data).key)) return;

    _isProcessing = true;
    try {
      final egressData = _prepareEgressData(data, redact: redact);
      if (!_pipeline.shouldProcess(egressData)) return;
      if (hasObservers) {
        _notifyObservers((observer) {
          data.notifyObserver(_RedactedObserverProxy(observer, egressData));
        });
      }
      _pipeline.dispatch(
        data,
        historyData: egressData,
        streamData: egressData,
        consoleData: egressData,
      );
    } finally {
      _isProcessing = false;
    }
  }

  ISpectLogData _prepareEgressData(
    ISpectLogData data, {
    required bool redact,
  }) {
    final captured = captureISpectLogDataForEgress(data);
    final resourceLimits = captured.resourceLimits;
    final redactor =
        ISpectRedaction.enabled && redact ? ISpectRedaction.service : null;
    final safeMessage = _prepareEgressText(
      redactor,
      captured.message,
      resourceLimits,
    );
    final safeException = _prepareEgressText(
          redactor,
          captured.exceptionText,
          resourceLimits,
        ) ??
        defaultPlaceholder;
    final safeError = captured.error == null
        ? null
        : capturedDiagnosticError(
            _prepareEgressText(
                  redactor,
                  captured.errorText,
                  resourceLimits,
                ) ??
                defaultPlaceholder,
          );
    final safeStack = captured.stackTrace == null
        ? null
        : capturedDiagnosticStackTrace(
            _prepareEgressText(
                  redactor,
                  captured.stackTraceText,
                  resourceLimits,
                ) ??
                defaultPlaceholder,
          );
    final additionalData = captured.additionalData;
    final masker = _egressMasker(redactor);

    final safeKey = _prepareEgressText(redactor, captured.key, resourceLimits);
    final egress = _buildEgressData(
      captured: captured,
      resourceLimits: resourceLimits,
      safeError: safeError,
      safeException: safeException,
      safeMessage: safeMessage,
      safeStack: safeStack,
      safeKey: safeKey,
      additionalData: additionalData,
      masker: masker,
    );
    if (redactor != null) {
      markExportRedacted(egress, redactor, resourceLimits);
    }
    return egress;
  }

  DiagnosticMasker? _egressMasker(RedactionService? redactor) {
    if (redactor == null) return null;
    return (value, limits) {
      final safe = _prepareEgressValue(redactor, value, limits);
      return safe is Map ? Map<String, dynamic>.from(safe) : null;
    };
  }

  ISpectLogData _buildEgressData({
    required ({
      String id,
      DiagnosticCaptureMode captureMode,
      DiagnosticResourceLimits resourceLimits,
      DateTime time,
      String? key,
      Object? message,
      LogLevel? logLevel,
      AnsiPen? pen,
      Map<String, dynamic>? additionalData,
      Object? exception,
      String? exceptionText,
      Error? error,
      String? errorText,
      StackTrace? stackTrace,
      String? stackTraceText,
    }) captured,
    required DiagnosticResourceLimits resourceLimits,
    required Error? safeError,
    required String safeException,
    required String? safeMessage,
    required StackTrace? safeStack,
    required String? safeKey,
    required Map<String, dynamic>? additionalData,
    required DiagnosticMasker? masker,
  }) {
    if (safeError != null) {
      return ISpectLogError(
        safeError,
        message: safeMessage,
        stackTrace: safeStack,
        time: captured.time,
        logLevel: captured.logLevel,
        pen: captured.pen,
        key: safeKey,
        additionalData: additionalData,
        id: captured.id,
        captureMode: DiagnosticCaptureMode.strict,
        resourceLimits: resourceLimits,
        maskAdditionalData: masker,
      );
    }
    if (captured.exception != null) {
      return ISpectLogException(
        capturedDiagnosticException(safeException),
        message: safeMessage,
        stackTrace: safeStack,
        time: captured.time,
        logLevel: captured.logLevel,
        pen: captured.pen,
        key: safeKey,
        additionalData: additionalData,
        id: captured.id,
        captureMode: DiagnosticCaptureMode.strict,
        resourceLimits: resourceLimits,
        maskAdditionalData: masker,
      );
    }
    return ISpectLogData(
      safeMessage,
      time: captured.time,
      logLevel: captured.logLevel,
      stackTrace: safeStack,
      pen: captured.pen,
      key: safeKey,
      additionalData: additionalData,
      id: captured.id,
      captureMode: DiagnosticCaptureMode.strict,
      resourceLimits: resourceLimits,
      maskAdditionalData: masker,
    );
  }

  /// Closes the stream, drops observers, releases history resources. After
  /// this call the logger becomes a no-op.
  Future<void> dispose() {
    final pending = _disposeFuture;
    if (pending != null) return pending;

    final completer = Completer<void>();
    final operation = completer.future;
    _disposeFuture = operation;
    final redactionEnabled = ISpectRedaction.enabled;
    final redactionService = ISpectRedaction.service;
    _isDisposed = true;
    late final Future<void> resources;
    try {
      resources = ISpectRedaction.runWithPolicy(
        enabled: redactionEnabled,
        service: redactionService,
        body: _disposeResources,
      );
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      return operation;
    }
    unawaited(
      resources.then<void>(
        (_) => completer.complete(),
        onError: (Object error, StackTrace stackTrace) {
          completer.completeError(error, stackTrace);
        },
      ),
    );
    return operation;
  }

  Future<void> _disposeResources() async {
    _observers.clear();
    (Object, StackTrace)? firstFailure;
    try {
      if (_history case final FileLogHistory fileHistory) {
        await fileHistory.saveToDailyFile();
      }
    } catch (error, stackTrace) {
      firstFailure = (error, stackTrace);
    }

    try {
      _history.dispose();
    } catch (error, stackTrace) {
      firstFailure ??= (error, stackTrace);
    }

    try {
      await _loggerStreamController.close();
    } catch (error, stackTrace) {
      firstFailure ??= (error, stackTrace);
    }

    final failure = firstFailure;
    if (failure != null) {
      Error.throwWithStackTrace(failure.$1, failure.$2);
    }
  }
}

String? _prepareEgressText(
  RedactionService? redactor,
  Object? value,
  DiagnosticResourceLimits resourceLimits,
) {
  final safe = _prepareEgressValue(redactor, value, resourceLimits);
  if (safe == null) return null;
  if (safe is String) return safe;
  if (safe is bool || safe is num) return safe.toString();
  try {
    return LogExportOutput.truncateUtf8(
      jsonEncode(safe),
      maxBytes: resourceLimits.maxCapturedValueBytes,
    );
  } catch (_) {
    return defaultPlaceholder;
  }
}

Object? _prepareEgressValue(
  RedactionService? redactor,
  Object? value,
  DiagnosticResourceLimits resourceLimits,
) {
  final byteLength = switch (value) {
    final ByteBuffer buffer => buffer.lengthInBytes,
    final TypedData data => data.lengthInBytes,
    _ => null,
  };
  if (byteLength != null) return placeholders.binaryPlaceholder(byteLength);
  try {
    if (redactor != null) {
      return redactor.redactForExport(
        value,
        resourceLimits: resourceLimits,
      );
    }
    return LogExportOutput.boundJsonValue(
      value,
      resourceLimits: resourceLimits,
      preserveTypes: true,
    );
  } catch (_) {
    return defaultPlaceholder;
  }
}

typedef ISpectObserverDisposer = void Function();

final class _RedactedObserverProxy implements ISpectObserver {
  const _RedactedObserverProxy(this._observer, this._data);

  final ISpectObserver _observer;
  final ISpectLogData _data;

  @override
  void onError(ISpectLogData _) => _observer.onError(_data);

  @override
  void onException(ISpectLogData _) => _observer.onException(_data);

  @override
  void onLog(ISpectLogData _) => _observer.onLog(_data);
}
