import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/src/constants.dart';
import 'package:ispectify_ws/src/settings.dart';
import 'package:ws/ws.dart';

/// WebSocket interceptor that logs events via the trace API.
final class ISpectWSInterceptor
    with BaseNetworkInterceptor
    implements WSInterceptor {
  ISpectWSInterceptor({
    required ISpectLogger logger,
    this.settings = const ISpectWSInterceptorSettings(),
    this.onClientReady,
    RedactionService? redactor,
  }) : _logger = logger {
    if (redactor != null) this.redactor = redactor;
  }

  final ISpectLogger _logger;
  final ISpectWSInterceptorSettings settings;
  final void Function(WebSocketClient)? onClientReady;
  WebSocketClient? _client;

  /// Auto-generated connection ID for correlating all events of one WS session.
  String? _connectionId;

  @override
  ISpectLogger get logger => _logger;

  @override
  bool get enableRedaction => settings.enableRedaction;

  static const _noRedactConfig = ISpectTraceConfig(redact: false);

  void setClient(WebSocketClient client) {
    _client = client;
    _connectionId = generateTraceId();
    onClientReady?.call(client);
  }

  Object _safeRedact(Object data, bool useRedaction) =>
      safeRedact(data, useRedaction: useRedaction);

  void _log({
    required Object data,
    required String type,
    required void Function(Object data) next,
  }) {
    if (!settings.enabled) {
      next(data);
      return;
    }

    if (_client == null) {
      logger.logData(
        ISpectLogData(
          'WS interceptor: _client is null during $type logging. '
          'Call setClient() before sending or receiving messages.',
          logLevel: LogLevel.warning,
        ),
      );
    }

    final rawUrl = _client?.metrics.lastUrl ?? '';
    final useRedaction = settings.enableRedaction;
    final redactedUrl = redactUrl(rawUrl, useRedaction: useRedaction);
    final uri = Uri.tryParse(redactedUrl);
    final url = uri?.toString() ?? '';
    final path = uri?.path ?? '';

    try {
      final safeData = _safeRedact(data, useRedaction);
      final operation = type == wsTypeRequest ? 'send' : 'receive';
      const isError = false;
      final logKey = wsCategory.pickLogKey(
        isError: isError,
        operation: operation,
      );

      final metricsMap = _processMetrics(useRedaction);
      final includeData = type == wsTypeRequest
          ? settings.printSentData
          : settings.printReceivedData;

      final meta = <String, Object?>{
        if (includeData) 'data': safeData,
        if (metricsMap != null) 'metrics': metricsMap,
        'url': url,
        'path': path,
      };

      // Build preview log data for filter check
      final previewLog = ISpectLogData(
        '$operation $url',
        key: logKey,
        additionalData: {
          TraceKeys.category: wsCategory.id,
          TraceKeys.source: 'ws',
          TraceKeys.operation: operation,
          TraceKeys.target: url,
          TraceKeys.success: true,
          if (_connectionId != null) TraceKeys.correlationId: _connectionId,
          TraceKeys.meta: meta,
        },
      );

      if (!_shouldLog(previewLog)) {
        next(data);
        return;
      }

      _logger.trace(
        category: wsCategory,
        source: 'ws',
        operation: operation,
        target: url,
        success: true,
        correlationId: _connectionId,
        config: useRedaction ? null : _noRedactConfig,
        meta: meta,
      );
    } catch (e, s) {
      _logger.trace(
        category: wsCategory,
        source: 'ws',
        operation: type == wsTypeRequest ? 'send' : 'receive',
        target: url,
        success: false,
        error: e,
        errorStackTrace: s,
        correlationId: _connectionId,
        config: useRedaction ? null : _noRedactConfig,
        meta: {
          'url': url,
          'path': path,
        },
      );
    }

    next(data);
  }

  Map<String, dynamic>? _processMetrics(bool useRedaction) {
    final metrics = _client?.metrics.toJson();
    return switch (metrics) {
      final Map<dynamic, dynamic> map => processMapData(
          map,
          useRedaction: useRedaction,
        ),
      _ => null,
    };
  }

  bool _shouldLog(ISpectLogData log) {
    final logKey = log.key;
    if (logKey == ISpectLogType.wsSent.key) {
      return settings.sentFilter?.call(log) ?? true;
    }
    if (logKey == ISpectLogType.wsReceived.key) {
      return settings.receivedFilter?.call(log) ?? true;
    }
    if (logKey == ISpectLogType.wsError.key) {
      return settings.errorFilter?.call(log) ?? true;
    }
    return true;
  }

  @override
  void onMessage(Object data, void Function(Object data) next) {
    _log(data: data, type: wsTypeResponse, next: next);
  }

  @override
  void onSend(Object data, void Function(Object data) next) {
    _log(data: data, type: wsTypeRequest, next: next);
  }
}
