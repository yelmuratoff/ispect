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
  })  : _logger = logger,
        _redactor = redactor ?? RedactionService();

  final ISpectLogger _logger;
  final RedactionService _redactor;
  final ISpectWSInterceptorSettings settings;
  final void Function(WebSocketClient)? onClientReady;
  WebSocketClient? _client;

  /// Auto-generated connection ID for correlating all events of one WS session.
  String? _connectionId;

  @override
  ISpectLogger get logger => _logger;

  @override
  RedactionService get redactor => _redactor;

  @override
  bool get enableRedaction => settings.enableRedaction;

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
      final operation = type == wsTypeRequest ? 'send' : 'receive';
      const isError = false;
      final logKey = wsCategory.pickLogKey(
        isError: isError,
        operation: operation,
      );

      // Lightweight preview for filter check — no expensive redaction/metrics.
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
        },
      );

      if (!_shouldLog(previewLog)) {
        next(data);
        return;
      }

      // Expensive operations only after filter passes.
      final safeData = _safeRedact(data, useRedaction);
      final metricsMap = _processMetrics(useRedaction);
      final includeData = type == wsTypeRequest
          ? settings.printSentData
          : settings.printReceivedData;

      final traceMeta = <String, Object?>{
        if (includeData) 'data': safeData,
        if (metricsMap != null) 'metrics': metricsMap,
        'url': url,
        'path': path,
      };

      final consoleMsg = buildNetworkConsoleMessage(
        source: 'ws',
        operation: operation,
        target: url,
        body: includeData ? safeData : null,
        printBody: includeData,
      );

      if (type == wsTypeRequest) {
        _logger.wsSend(
          source: 'ws',
          operation: operation,
          target: url,
          correlationId: _connectionId,
          config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
          meta: traceMeta,
          consoleMessage: consoleMsg,
        );
      } else {
        _logger.wsReceive(
          source: 'ws',
          operation: operation,
          target: url,
          correlationId: _connectionId,
          config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
          meta: traceMeta,
          consoleMessage: consoleMsg,
        );
      }
    } catch (e, s) {
      final errMeta = <String, Object?>{'url': url, 'path': path};
      if (type == wsTypeRequest) {
        _logger.wsSend(
          source: 'ws',
          operation: 'send',
          target: url,
          error: e,
          errorStackTrace: s,
          correlationId: _connectionId,
          config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
          meta: errMeta,
        );
      } else {
        _logger.wsReceive(
          source: 'ws',
          operation: 'receive',
          target: url,
          error: e,
          errorStackTrace: s,
          correlationId: _connectionId,
          config: useRedaction ? null : BaseNetworkInterceptor.noRedactConfig,
          meta: errMeta,
        );
      }
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
