import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:stream_channel/stream_channel.dart';

/// ISpect diagnostics adapter for `web_socket_channel` and any [StreamChannel].
///
/// [wrap] returns a channel that logs inbound frames as they arrive, outbound
/// frames as they are sent, and a `closed` state when the stream completes.
/// `web_socket_channel`'s `WebSocketChannel` is a [StreamChannel], so pass it
/// directly; tests can pass an in-memory channel.
///
/// ```dart
/// final diag = ISpectWebSocketChannelDiagnostics(logger: ISpect.logger);
/// final channel = diag.wrap(WebSocketChannel.connect(uri));
/// channel.stream.listen(handleMessage);
/// channel.sink.add('hello');
/// ```
final class ISpectWebSocketChannelDiagnostics {
  ISpectWebSocketChannelDiagnostics({
    required ISpectLogger logger,
    ISpectWSInterceptorSettings settings = const ISpectWSInterceptorSettings(),
    RedactionService? redactor,
    this.url,
  }) : _diagnostics = WsDiagnostics(
          logger: logger,
          settings: settings,
          redactor: redactor,
          source: source,
        );

  /// Source label attached to web_socket_channel logs.
  static const source = 'web_socket_channel';

  final WsDiagnostics _diagnostics;

  /// Connection URL used as the log target, when known.
  final String? url;

  /// Wraps [channel] with inbound/outbound/close logging on a fresh session.
  StreamChannel<T> wrap<T>(StreamChannel<T> channel) {
    _diagnostics
      ..newConnection()
      ..onStateChanged(WsConnectionState.open, url: url);

    return channel
        .changeStream(_tapStream)
        .changeSink((sink) => _TracingSink<T>(sink, _diagnostics, url));
  }

  Stream<T> _tapStream<T>(Stream<T> source) =>
      source.transform(StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          if (data != null) _diagnostics.onReceived(data, url: url);
          sink.add(data);
        },
        handleError: (error, stackTrace, sink) {
          _diagnostics.onError(error, stackTrace, url: url);
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          _diagnostics.onStateChanged(WsConnectionState.closed, url: url);
          sink.close();
        },
      ));
}

final class _TracingSink<T> implements StreamSink<T> {
  _TracingSink(this._inner, this._diagnostics, this._url);

  final StreamSink<T> _inner;
  final WsDiagnostics _diagnostics;
  final String? _url;

  @override
  void add(T event) {
    if (event != null) _diagnostics.onSent(event, url: _url);
    _inner.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<T> stream) => _inner.addStream(
        stream.map((event) {
          if (event != null) _diagnostics.onSent(event, url: _url);
          return event;
        }),
      );

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> get done => _inner.done;
}
