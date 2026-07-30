import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/settings.dart';
import 'package:ispectify_ws/src/ws_event.dart';

/// Provider-agnostic WebSocket diagnostics emitter.
///
/// Owns the orchestration shared by every WebSocket client: a per-session
/// correlation id, settings-driven filtering, redaction, metrics
/// normalization, and emission via the `ws-*` trace keys. Concrete clients
/// bind by pushing events through the [WsDiagnosticsSink] contract; the two
/// `ws`-specific reads of the old interceptor (`metrics.lastUrl`,
/// `metrics.toJson()`) become the optional [url] and [metrics] arguments.
///
/// Depends only on `ispectify` — no WebSocket package is required.
final class WsDiagnostics
    with NetworkLoggerMixin, NetworkRedactionMixin
    implements WsDiagnosticsSink {
  WsDiagnostics({
    required ISpectLogger logger,
    this.settings = const ISpectWSInterceptorSettings(),
    this.source = defaultSource,
    RedactionService? redactor,
  })  : _logger = logger,
        _explicitRedactor = redactor {
    settings.resourceLimits?.validate();
  }

  /// Default source label used when no adapter-specific label is given.
  static const defaultSource = 'ws';
  static const _frameCaptureFailure =
      'ISpect WebSocket frame capture failed safely.';

  final ISpectLogger _logger;
  final RedactionService? _explicitRedactor;

  /// Filtering, redaction toggle, and print toggles for emitted logs.
  final ISpectWSInterceptorSettings settings;

  /// Source label attached to every emitted log (e.g. `ws`, `socket_io`).
  final String source;

  String? _connectionId;

  @override
  ISpectLogger get logger => _logger;

  @override
  RedactionService get redactor =>
      ISpectRedaction.resolveService(service: _explicitRedactor);

  bool get _captureEnabled => _logger.hasActiveConsumers && settings.enabled;
  String get _correlationId => _connectionId ??= generateTraceId();

  @override
  bool get enableRedaction => settings.enableRedaction;

  @override
  DiagnosticCaptureMode get captureMode => settings.captureMode;

  @override
  DiagnosticResourceLimits get resourceLimits =>
      settings.resourceLimits ?? _logger.options.resourceLimits;

  ISpectTraceConfig get _traceConfig => ISpectTraceConfig(
        redact: false,
        resourceLimits: resourceLimits,
      );

  @override
  void newConnection() {
    _connectionId = null;
  }

  @override
  void onSent(Object data, {String? url, Map<String, Object?>? metrics}) =>
      _emitFrame(data: data, isSend: true, rawUrl: url, metrics: metrics);

  @override
  void onReceived(Object data, {String? url, Map<String, Object?>? metrics}) =>
      _emitFrame(data: data, isSend: false, rawUrl: url, metrics: metrics);

  @override
  void onStateChanged(WsConnectionState state, {String? url, Object? raw}) {
    if (!_captureEnabled) return;
    if (!settings.logRequests && !settings.logResponses) return;

    final correlationId = _correlationId;
    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final safeSource = redactDiagnosticText(
      source,
      useRedaction: redactionActive,
    );
    final normalizedUrl = _normalizeUrl(url, redactionActive).url;
    final safeRaw = raw == null || !settings.printStateData
        ? null
        : _safeDiagnosticText(raw, useRedaction: redactionActive);

    _logger.wsState(
      source: safeSource,
      state: state.name,
      target: normalizedUrl,
      correlationId: correlationId,
      config: _traceConfig,
      consoleMessage: '→ state:${state.name} $normalizedUrl',
      meta: {
        'url': normalizedUrl,
        if (safeRaw != null) 'raw': safeRaw,
      },
    );
  }

  @override
  void onError(Object error, StackTrace stackTrace, {String? url}) {
    if (!_captureEnabled) return;

    final correlationId = _correlationId;
    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final safeSource = redactDiagnosticText(
      source,
      useRedaction: redactionActive,
    );
    final (url: normalizedUrl, path: path) =
        _normalizeUrl(url, redactionActive);

    final preview = ISpectLogData(
      'error $normalizedUrl',
      key: ISpectLogType.wsError.key,
      additionalData: {
        TraceKeys.category: wsCategory.id,
        TraceKeys.source: safeSource,
        TraceKeys.operation: 'error',
        TraceKeys.target: normalizedUrl,
        TraceKeys.success: false,
        TraceKeys.correlationId: correlationId,
      },
      resourceLimits: resourceLimits,
    );

    if (!settings.shouldProcessError(preview)) return;
    if (!_captureEnabled) return;

    final safeError = settings.printErrorMessage
        ? _safeDiagnosticText(error, useRedaction: redactionActive)
        : null;
    final safeStackTrace = settings.printErrorData
        ? StackTrace.fromString(
            _safeDiagnosticText(stackTrace, useRedaction: redactionActive),
          )
        : null;

    _logger.traceCategory(
      category: wsCategory,
      source: safeSource,
      operation: 'error',
      target: normalizedUrl,
      logKey: ISpectLogType.wsError.key,
      success: false,
      error: safeError,
      errorStackTrace: safeStackTrace,
      correlationId: correlationId,
      config: _traceConfig,
      meta: {'url': normalizedUrl, 'path': path},
    );
  }

  void _emitFrame({
    required Object data,
    required bool isSend,
    required String? rawUrl,
    required Map<String, Object?>? metrics,
  }) {
    if (!_captureEnabled) return;
    if (isSend && !settings.logRequests) return;
    if (!isSend && !settings.logResponses) return;

    final correlationId = _correlationId;
    final redactionActive = settings.enableRedaction && ISpectRedaction.enabled;
    final safeSource = redactDiagnosticText(
      source,
      useRedaction: redactionActive,
    );
    final (url: url, path: path) = _normalizeUrl(rawUrl, redactionActive);
    final operation = isSend ? 'send' : 'receive';
    final logKey = wsCategory.pickLogKey(isError: false, operation: operation);

    final previewLog = ISpectLogData(
      '$operation $url',
      key: logKey,
      additionalData: {
        TraceKeys.category: wsCategory.id,
        TraceKeys.source: safeSource,
        TraceKeys.operation: operation,
        TraceKeys.target: url,
        TraceKeys.success: true,
        TraceKeys.correlationId: correlationId,
      },
    );

    if (!_shouldLog(previewLog)) return;
    if (!_captureEnabled) return;

    try {
      final includeData =
          isSend ? settings.printSentData : settings.printReceivedData;
      final safeData =
          includeData ? safeRedact(data, useRedaction: redactionActive) : null;
      final metricsMap = _processMetrics(metrics, redactionActive);

      final traceMeta = <String, Object?>{
        if (includeData) 'data': safeData,
        if (metricsMap != null) 'metrics': metricsMap,
        'url': url,
        'path': path,
        NetworkLogRenderer.renderHintsKey: {
          NetworkLogRenderer.hintPrintBody: includeData,
        },
      };

      final emit = isSend ? _logger.wsSend : _logger.wsReceive;
      if (!_captureEnabled) return;
      emit(
        source: safeSource,
        operation: operation,
        target: url,
        correlationId: correlationId,
        config: _traceConfig,
        meta: traceMeta,
      );
    } on Object {
      if (!_captureEnabled) return;
      _logger.traceCategory(
        category: wsCategory,
        source: safeSource,
        operation: operation,
        target: url,
        logKey: ISpectLogType.wsError.key,
        success: false,
        error: settings.printErrorMessage ? _frameCaptureFailure : null,
        correlationId: correlationId,
        config: _traceConfig,
        meta: {'url': url, 'path': path},
      );
    }
  }

  ({String url, String path}) _normalizeUrl(String? rawUrl, bool useRedaction) {
    final redactedUrl = redactUrl(rawUrl ?? '', useRedaction: useRedaction);
    final uri = Uri.tryParse(redactedUrl);
    return (url: uri?.toString() ?? '', path: uri?.path ?? '');
  }

  Map<String, dynamic>? _processMetrics(
    Map<String, Object?>? metrics,
    bool useRedaction,
  ) {
    if (metrics == null) return null;
    return processMapData(metrics, useRedaction: useRedaction);
  }

  bool _shouldLog(ISpectLogData log) {
    final logKey = log.key;
    if (logKey == ISpectLogType.wsSent.key) {
      return settings.shouldProcessSent(log);
    }
    if (logKey == ISpectLogType.wsReceived.key) {
      return settings.shouldProcessReceived(log);
    }
    if (logKey == ISpectLogType.wsError.key) {
      return settings.shouldProcessError(log);
    }
    return true;
  }

  String _safeDiagnosticText(
    Object value, {
    required bool useRedaction,
  }) {
    try {
      final prepared = LogExportOutput.boundJsonValue(
        value,
        maxBytes: resourceLimits.maxNetworkBodyBytes,
        resourceLimits: resourceLimits,
        preserveTypes: useRedaction,
        replaceOversizedStrings: useRedaction,
        allowCustomSerialization:
            settings.captureMode == DiagnosticCaptureMode.balanced,
        allowCustomStringification:
            settings.captureMode == DiagnosticCaptureMode.balanced,
      );
      final redacted = useRedaction && prepared != null
          ? NetworkMapRedactor.redactFreeTextValue(
              prepared,
              redactor,
              resourceLimits: resourceLimits,
            )
          : prepared;
      final bounded = LogExportOutput.boundJsonValue(
        redacted,
        maxBytes: resourceLimits.maxNetworkBodyBytes,
        resourceLimits: resourceLimits,
        replaceOversizedStrings: useRedaction,
      );
      if (bounded is String) return bounded;
      if (bounded is bool || bounded is num) return bounded.toString();
      return LogExportOutput.truncateUtf8(
        jsonEncode(bounded),
        maxBytes: resourceLimits.maxNetworkBodyBytes,
      );
    } on Object {
      return redactionFailedPlaceholder;
    }
  }
}
