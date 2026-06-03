import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

/// Local `ws` (plugfox) adapter bridging the client to [WsDiagnostics].
///
/// `ispectify_ws` no longer ships a `ws`-bound interceptor; apps copy this thin
/// adapter and depend on `ws` themselves. See
/// `packages/ispectify_ws/example/lib/interceptors/ws_interceptor.dart`.
final class ISpectWSInterceptor implements WSInterceptor {
  ISpectWSInterceptor({
    required ISpectLogger logger,
    ISpectWSInterceptorSettings settings = const ISpectWSInterceptorSettings(),
    RedactionService? redactor,
    this.onClientReady,
  }) : _diagnostics = WsDiagnostics(
         logger: logger,
         settings: settings,
         redactor: redactor,
       );

  final WsDiagnostics _diagnostics;

  /// Invoked once a client is bound via [setClient].
  final void Function(WebSocketClient client)? onClientReady;

  WebSocketClient? _client;
  StreamSubscription<WebSocketClientState>? _stateSub;

  /// Binds [client] so frames carry its URL and metrics and state transitions
  /// are logged. Starts a fresh correlation session.
  void setClient(WebSocketClient client) {
    unawaited(_stateSub?.cancel());
    _client = client;
    _diagnostics.newConnection();
    _stateSub = client.stateChanges.listen(_onState);
    onClientReady?.call(client);
  }

  @override
  void onSend(Object data, void Function(Object data) next) {
    _diagnostics.onSent(data, url: _url, metrics: _metrics);
    next(data);
  }

  @override
  void onMessage(Object data, void Function(Object data) next) {
    _diagnostics.onReceived(data, url: _url, metrics: _metrics);
    next(data);
  }

  /// Cancels the state subscription. Call when discarding the interceptor.
  Future<void> dispose() => _stateSub?.cancel() ?? Future<void>.value();

  void _onState(WebSocketClientState state) {
    final normalized = switch (state) {
      WebSocketClientState$Connecting() => WsConnectionState.connecting,
      WebSocketClientState$Open() => WsConnectionState.open,
      WebSocketClientState$Disconnecting() => WsConnectionState.closing,
      WebSocketClientState$Closed() => WsConnectionState.closed,
    };
    _diagnostics.onStateChanged(normalized, url: _url, raw: state);
  }

  String? get _url => _client?.metrics.lastUrl;

  Map<String, Object?>? get _metrics => _client?.metrics.toJson();
}
