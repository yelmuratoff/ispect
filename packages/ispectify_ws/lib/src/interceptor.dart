import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

final class ISpectWSInterceptor
    with BaseNetworkInterceptor
    implements WSInterceptor {
  ISpectWSInterceptor({
    required ISpectify logger,
    this.settings = const ISpectWSInterceptorSettings(),
    this.onClientReady,
    RedactionService? redactor,
  }) {
    initializeInterceptor(logger: logger, redactor: redactor);
  }

  final ISpectWSInterceptorSettings settings;
  final void Function(WebSocketClient)? onClientReady;
  WebSocketClient? _client;

  @override
  bool get enableRedaction => settings.enableRedaction;

  void setClient(WebSocketClient client) {
    _client = client;
    onClientReady?.call(client);
  }

  Object _safeRedact(Object data, bool useRedaction) {
    try {
      final sanitized = maybeRedact(data, useRedaction: useRedaction);
      return sanitized ?? data;
    } catch (_) {
      return data;
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

    final uri = Uri.tryParse(_client?.metrics.lastUrl ?? '');
    final useRedaction = settings.enableRedaction;

    try {
      final safeData = _safeRedact(data, useRedaction);
      final log = _createLog(type, safeData, uri, useRedaction);
      if (log != null && _shouldLog(log)) {
        logger.logCustom(log);
      }
    } catch (e, s) {
      final errorLog = _createErrorLog(type, data, uri, e, s, useRedaction);
      if (_shouldLog(errorLog)) {
        logger.logCustom(errorLog);
      }
    }

    next(data);
  }

  ISpectifyData? _createLog(
    String type,
    Object safeData,
    Uri? uri,
    bool useRedaction,
  ) {
    final metrics = _client?.metrics.toJson();
    final url = uri.toString();
    final path = uri?.path ?? '';
    final metricsMap = switch (metrics) {
      final Map<dynamic, dynamic> map => payload.stringKeyMap(map),
      _ => null,
    };

    return switch (type) {
      'REQUEST' => WSSentLog(
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
      'RESPONSE' => WSReceivedLog(
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
    final metrics = _client?.metrics.toJson();
    final metricsMap = switch (metrics) {
      final Map<dynamic, dynamic> map => payload.stringKeyMap(map),
      _ => null,
    };

    return WSErrorLog(
      settings.printErrorMessage
          ? 'Failed to log $type: $e'
          : 'Failed to log $type',
      type: type,
      url: uri.toString(),
      path: uri?.path ?? '',
      payload: _createBodyPayload(
        safeData,
        metrics,
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

    final sanitized = payload.body(
      basePayload,
      enableRedaction: useRedaction,
      normalizer: (value) => value,
    );

    final map = payload.ensureMap(sanitized)
      ..removeWhere((_, value) => value == null);
    return map;
  }

  bool _shouldLog(ISpectifyData log) => switch (log) {
        WSSentLog() => settings.sentFilter?.call(log) ?? true,
        WSReceivedLog() => settings.receivedFilter?.call(log) ?? true,
        WSErrorLog() => settings.errorFilter?.call(log) ?? true,
        _ => true,
      };

  @override
  void onMessage(Object data, void Function(Object data) next) {
    _log(data: data, type: 'RESPONSE', next: next);
  }

  @override
  void onSend(Object data, void Function(Object data) next) {
    _log(data: data, type: 'REQUEST', next: next);
  }
}
