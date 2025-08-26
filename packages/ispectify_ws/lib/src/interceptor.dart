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
    try {
      final useRedaction = settings.enableRedaction;
      final safe = useRedaction ? _redactor.redact(data) : data;
      final log = switch (type) {
        'REQUEST' => WSSentLog(
            '$safe',
            type: type,
            url: uri.toString(),
            path: uri?.path ?? '',
            body: {
              'data': safe,
              'metrics': _client?.metrics.toJson(),
            },
          ),
        'RESPONSE' => WSReceivedLog(
            '$safe',
            type: type,
            url: uri.toString(),
            path: uri?.path ?? '',
            body: {
              'data': safe,
              'metrics': _client?.metrics.toJson(),
            },
          ),
        _ => null,
      };
      if (log != null) {
        if (log is WSSentLog) {
          if (settings.sentFilter?.call(log) ?? true) {
            if (settings.printSentData) {
              logger.logCustom(log);
            }
          }
        } else if (log is WSReceivedLog) {
          if (settings.receivedFilter?.call(log) ?? true) {
            if (settings.printReceivedData) {
              logger.logCustom(log);
            }
          }
        } else if (log is WSErrorLog) {
          if (settings.errorFilter?.call(log) ?? true) {
            if (settings.printErrorData) {
              logger.logCustom(log);
            }
          }
        } else {
          logger.logCustom(log);
        }
      }
    } catch (e, s) {
      final errorLog = WSErrorLog(
        'Failed to log $type: $e',
        type: type,
        url: uri.toString(),
        path: uri?.path ?? '',
        body: {
          'data': data.toString(),
          'metrics': _client?.metrics.toJson(),
        },
        exception: e,
        stackTrace: s,
      );
      if (settings.errorFilter?.call(errorLog) ?? true) {
        if (settings.printErrorData) {
          logger.logCustom(errorLog);
        }
      }
    }
    next(data);
  }

  @override
  void onMessage(Object data, void Function(Object data) next) {
    _log(
      data: data,
      type: 'RESPONSE',
      next: next,
    );
  }

  @override
  void onSend(Object data, void Function(Object data) next) {
    _log(
      data: data,
      type: 'REQUEST',
      next: next,
    );
  }
}
