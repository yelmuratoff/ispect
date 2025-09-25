import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

final class ISpectWSInterceptor implements WSInterceptor {
  ISpectWSInterceptor({
    required this.logger,
    this.settings = const ISpectWSInterceptorSettings(),
    this.onClientReady,
    RedactionService? redactor,
  }) : _redactor = redactor ?? RedactionService();

  final ISpectify logger;
  final ISpectWSInterceptorSettings settings;
  final void Function(WebSocketClient)? onClientReady;
  final RedactionService _redactor;
  WebSocketClient? _client;

  void setClient(WebSocketClient client) {
    _client = client;
    onClientReady?.call(client);
  }

  Object _safeRedact(Object data, bool useRedaction) {
    try {
      return useRedaction ? _redactor.redact(data) ?? data : data;
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
      final safeData = useRedaction ? _redactor.redact(data) ?? data : data;
      final log = _createLog(type, safeData, uri);
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

  ISpectifyData? _createLog(String type, Object safeData, Uri? uri) {
    final metrics = _client?.metrics.toJson();
    final url = uri.toString();
    final path = uri?.path ?? '';

    return switch (type) {
      'REQUEST' => WSSentLog(
          settings.printSentData ? '$safeData' : '',
          type: type,
          url: url,
          path: path,
          body: _createBodyPayload(safeData, metrics, settings.printSentData),
          settings: settings,
        ),
      'RESPONSE' => WSReceivedLog(
          settings.printReceivedData ? '$safeData' : '',
          type: type,
          url: url,
          path: path,
          body:
              _createBodyPayload(safeData, metrics, settings.printReceivedData),
          settings: settings,
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

    return WSErrorLog(
      settings.printErrorMessage
          ? 'Failed to log $type: $e'
          : 'Failed to log $type',
      type: type,
      url: uri.toString(),
      path: uri?.path ?? '',
      body: _createBodyPayload(safeData, metrics, settings.printErrorData),
      exception: e,
      stackTrace: s,
      settings: settings,
    );
  }

  Object _createBodyPayload(Object data, Object? metrics, bool includeData) =>
      includeData ? {'data': data, 'metrics': metrics} : {'metrics': metrics};

  bool _shouldLog(ISpectifyData log) {
    if (log is WSSentLog) {
      return settings.sentFilter?.call(log) ?? true;
    }
    if (log is WSReceivedLog) {
      return settings.receivedFilter?.call(log) ?? true;
    }
    if (log is WSErrorLog) {
      return settings.errorFilter?.call(log) ?? true;
    }
    return true;
  }

  @override
  void onMessage(Object data, void Function(Object data) next) {
    _log(data: data, type: 'RESPONSE', next: next);
  }

  @override
  void onSend(Object data, void Function(Object data) next) {
    _log(data: data, type: 'REQUEST', next: next);
  }
}
