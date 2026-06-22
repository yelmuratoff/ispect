/// Normalized WebSocket connection lifecycle states.
///
/// Clients report whichever states they can observe; states a client cannot
/// distinguish are simply never emitted. [reconnecting] exists for clients
/// (e.g. `ws`) that surface automatic reconnection — most clients never use it.
enum WsConnectionState { connecting, open, closing, closed, reconnecting }

/// Provider-agnostic sink for WebSocket diagnostics.
///
/// Any WebSocket client binds to ISpect by pushing events through this
/// contract; the orchestration ([WsDiagnostics]) owns redaction, filtering,
/// correlation, and emission. Metrics and connection state are optional —
/// clients that cannot report them omit the arguments.
abstract interface class WsDiagnosticsSink {
  /// Records an outbound frame. [url] and [metrics] are optional context.
  void onSent(Object data, {String? url, Map<String, Object?>? metrics});

  /// Records an inbound frame. [url] and [metrics] are optional context.
  void onReceived(Object data, {String? url, Map<String, Object?>? metrics});

  /// Records a connection-state transition. [raw] is the client's own state
  /// object, retained as a stringified hint when present.
  void onStateChanged(WsConnectionState state, {String? url, Object? raw});

  /// Records a connection-level error not tied to a single frame.
  void onError(Object error, StackTrace stackTrace, {String? url});

  /// Resets the correlation id, starting a new connection session.
  void newConnection();
}
