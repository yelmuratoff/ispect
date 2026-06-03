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
        _redactor = redactor ?? RedactionService(),
        _connectionId = generateTraceId();

  /// Default source label used when no adapter-specific label is given.
  static const defaultSource = 'ws';

  final ISpectLogger _logger;
  final RedactionService _redactor;

  /// Filtering, redaction toggle, and print toggles for emitted logs.
  final ISpectWSInterceptorSettings settings;

  /// Source label attached to every emitted log (e.g. `ws`, `socket_io`).
  final String source;

  String _connectionId;

  @override
  ISpectLogger get logger => _logger;

  @override
  RedactionService get redactor => _redactor;

  @override
  bool get enableRedaction => settings.enableRedaction;

  @override
  void newConnection() => _connectionId = generateTraceId();

  @override
  void onSent(Object data, {String? url, Map<String, Object?>? metrics}) =>
      _emitFrame(data: data, isSend: true, rawUrl: url, metrics: metrics);

  @override
  void onReceived(Object data, {String? url, Map<String, Object?>? metrics}) =>
      _emitFrame(data: data, isSend: false, rawUrl: url, metrics: metrics);

  @override
  void onStateChanged(WsConnectionState state, {String? url, Object? raw}) {
    if (!settings.enabled) return;

    final useRedaction = settings.enableRedaction;
    final normalizedUrl = _normalizeUrl(url, useRedaction).url;

    _logger.wsState(
      source: source,
      state: state.name,
      target: normalizedUrl,
      correlationId: _connectionId,
      config: useRedaction ? null : NetworkRedactionMixin.noRedactConfig,
      meta: {
        'url': normalizedUrl,
        if (raw != null) 'raw': '$raw',
      },
    );
  }

  @override
  void onError(Object error, StackTrace stackTrace, {String? url}) {
    if (!settings.enabled) return;

    final useRedaction = settings.enableRedaction;
    final (url: normalizedUrl, path: path) = _normalizeUrl(url, useRedaction);

    final preview = ISpectLogData(
      'error $normalizedUrl',
      key: ISpectLogType.wsError.key,
      additionalData: {
        TraceKeys.category: wsCategory.id,
        TraceKeys.source: source,
        TraceKeys.operation: 'error',
        TraceKeys.target: normalizedUrl,
        TraceKeys.success: false,
        TraceKeys.correlationId: _connectionId,
      },
    );

    if (!settings.shouldProcessError(preview)) return;

    _logger.wsReceive(
      source: source,
      operation: 'error',
      target: normalizedUrl,
      error: error,
      errorStackTrace: stackTrace,
      correlationId: _connectionId,
      config: useRedaction ? null : NetworkRedactionMixin.noRedactConfig,
      meta: {'url': normalizedUrl, 'path': path},
    );
  }

  void _emitFrame({
    required Object data,
    required bool isSend,
    required String? rawUrl,
    required Map<String, Object?>? metrics,
  }) {
    if (!settings.enabled) return;

    final useRedaction = settings.enableRedaction;
    final (url: url, path: path) = _normalizeUrl(rawUrl, useRedaction);
    final operation = isSend ? 'send' : 'receive';
    final logKey = wsCategory.pickLogKey(isError: false, operation: operation);

    final previewLog = ISpectLogData(
      '$operation $url',
      key: logKey,
      additionalData: {
        TraceKeys.category: wsCategory.id,
        TraceKeys.source: source,
        TraceKeys.operation: operation,
        TraceKeys.target: url,
        TraceKeys.success: true,
        TraceKeys.correlationId: _connectionId,
      },
    );

    if (!_shouldLog(previewLog)) return;

    try {
      final safeData = safeRedact(data, useRedaction: useRedaction);
      final metricsMap = _processMetrics(metrics, useRedaction);
      final includeData =
          isSend ? settings.printSentData : settings.printReceivedData;

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
      emit(
        source: source,
        operation: operation,
        target: url,
        correlationId: _connectionId,
        config: useRedaction ? null : NetworkRedactionMixin.noRedactConfig,
        meta: traceMeta,
      );
    } catch (e, s) {
      final emit = isSend ? _logger.wsSend : _logger.wsReceive;
      emit(
        source: source,
        operation: operation,
        target: url,
        error: e,
        errorStackTrace: s,
        correlationId: _connectionId,
        config: useRedaction ? null : NetworkRedactionMixin.noRedactConfig,
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
}
