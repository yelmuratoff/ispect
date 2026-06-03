import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:socket_io_client/socket_io_client.dart';

/// ISpect diagnostics adapter for `socket_io_client`.
///
/// socket.io exposes no interceptor chain, so [bind] wires the lifecycle and
/// catch-all inbound callbacks while [emit] records outbound events. The
/// `record*` methods are the integration seam; [bind] and [emit] are thin
/// wrappers over the real [Socket].
///
/// ```dart
/// final diag = ISpectSocketIoDiagnostics(logger: ISpect.logger);
/// final socket = io('https://example.com');
/// diag.bind(socket);
/// diag.emit(socket, 'message', {'text': 'hi'});
/// ```
final class ISpectSocketIoDiagnostics {
  ISpectSocketIoDiagnostics({
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

  /// Source label attached to socket.io logs.
  static const source = 'socket_io';

  final WsDiagnostics _diagnostics;

  /// Connection URL used as the log target, when known.
  final String? url;

  /// Registers lifecycle and catch-all inbound handlers on [socket] and starts
  /// a fresh correlation session.
  void bind(Socket socket) {
    _diagnostics.newConnection();
    socket
      ..onConnect((_) => recordConnect())
      ..onDisconnect((reason) => recordDisconnect(reason))
      ..onError((error) => recordError(error ?? 'socket_io error'))
      ..onAny((event, data) => recordReceived(event, data));
  }

  /// Emits [event] with [data] on [socket] and records it as a sent frame.
  void emit(Socket socket, String event, [Object? data]) {
    recordSent(event, data);
    socket.emit(event, data);
  }

  /// Records an established connection.
  void recordConnect() =>
      _diagnostics.onStateChanged(WsConnectionState.open, url: url);

  /// Records a closed connection, keeping the disconnect [reason] as a hint.
  void recordDisconnect([Object? reason]) => _diagnostics.onStateChanged(
        WsConnectionState.closed,
        url: url,
        raw: reason,
      );

  /// Records a connection-level error.
  void recordError(Object error, [StackTrace? stackTrace]) =>
      _diagnostics.onError(error, stackTrace ?? StackTrace.current, url: url);

  /// Records an inbound [event] and its [data].
  void recordReceived(String event, Object? data) => _diagnostics.onReceived(
        {'event': event, if (data != null) 'data': data},
        url: url,
      );

  /// Records an outbound [event] and its [data].
  void recordSent(String event, Object? data) => _diagnostics.onSent(
        {'event': event, if (data != null) 'data': data},
        url: url,
      );
}
