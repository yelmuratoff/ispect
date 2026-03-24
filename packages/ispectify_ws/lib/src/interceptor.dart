import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

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

  @override
  ISpectLogger get logger => _logger;

  @override
  bool get enableRedaction => settings.enableRedaction;

  void setClient(WebSocketClient client) {
    _client = client;
    onClientReady?.call(client);
  }

  Object _safeRedact(Object data, bool useRedaction) {
    try {
      final sanitized = redactBody(data, useRedaction: useRedaction);
      return sanitized ?? data;
    } catch (e, s) {
      logger.logData(
        ISpectLogData(
          'Redaction failed, data omitted: $e',
          logLevel: LogLevel.warning,
          stackTrace: s,
        ),
      );
      return redactionFailedPlaceholder;
    }
  }

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

    try {
      final safeData = _safeRedact(data, useRedaction);
      final log = _createLog(type, safeData, uri, useRedaction);
      if (log != null && _shouldLog(log)) {
        logger.logData(log);
      }
    } catch (e, s) {
      final errorLog =
          _createErrorLog(type, data, uri, e, s, useRedaction);
      if (_shouldLog(errorLog)) {
        logger.logData(errorLog);
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

  ISpectLogData? _createLog(
    String type,
    Object safeData,
    Uri? uri,
    bool useRedaction,
  ) {
    final metrics = _client?.metrics.toJson();
    final url = uri?.toString() ?? '';
    final path = uri?.path ?? '';
    final metricsMap = _processMetrics(useRedaction);

    return switch (type) {
      wsTypeRequest => WSSentLog(
          settings.printSentData ? '$safeData' : '',
          type: type,
          url: url,
          path: path,
          payload: _createBodyPayload(
            safeData,
            metrics,
            settings.printSentData,
            useRedaction,
          ),
          settings: settings,
          metrics: metricsMap,
        ),
      wsTypeResponse => WSReceivedLog(
          settings.printReceivedData ? '$safeData' : '',
          type: type,
          url: url,
          path: path,
          payload: _createBodyPayload(
            safeData,
            metrics,
            settings.printReceivedData,
            useRedaction,
          ),
          settings: settings,
          metrics: metricsMap,
        ),
      _ => null,
    };
  }

  WSErrorLog _createErrorLog(
    String type,
    Object data,
    Uri? uri,
    Object e,
    StackTrace s,
    bool useRedaction,
  ) {
    final safeData = _safeRedact(data, useRedaction);
    final metricsMap = _processMetrics(useRedaction);

    return WSErrorLog(
      settings.printErrorMessage
          ? 'Failed to log $type: $e'
          : 'Failed to log $type',
      type: type,
      url: uri?.toString() ?? '',
      path: uri?.path ?? '',
      payload: _createBodyPayload(
        safeData,
        _client?.metrics.toJson(),
        settings.printErrorData,
        useRedaction,
      ),
      exception: e,
      stackTrace: s,
      settings: settings,
      metrics: metricsMap,
    );
  }

  Map<String, dynamic> _createBodyPayload(
    Object data,
    Object? metrics,
    bool includeData,
    bool useRedaction,
  ) {
    final basePayload = <String, dynamic>{'metrics': metrics};
    if (includeData) {
      basePayload['data'] = data;
    }

    try {
      final sanitized = payload.body(
        basePayload,
        enableRedaction: useRedaction,
        normalizer: (value) => value,
      );

      final map = payload.ensureMap(sanitized)
        ..removeWhere((_, value) => value == null);
      return map;
    } catch (e, s) {
      // If redaction fails, log the error and omit sensitive data
      logger.logData(
        ISpectLogData(
          'Payload redaction failed, sensitive data omitted: $e',
          logLevel: LogLevel.warning,
          stackTrace: s,
        ),
      );
      return <String, dynamic>{'metrics': basePayload['metrics']};
    }
  }

  bool _shouldLog(ISpectLogData log) => switch (log) {
        WSSentLog() => settings.sentFilter?.call(log) ?? true,
        WSReceivedLog() => settings.receivedFilter?.call(log) ?? true,
        WSErrorLog() => settings.errorFilter?.call(log) ?? true,
        _ => true,
      };

  @override
  void onMessage(Object data, void Function(Object data) next) {
    _log(data: data, type: wsTypeResponse, next: next);
  }

  @override
  void onSend(Object data, void Function(Object data) next) {
    _log(data: data, type: wsTypeRequest, next: next);
  }
}
