import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/interceptors/web_socket_channel_interceptor.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connects with `web_socket_channel` and logs inbound/outbound frames and the
/// closing state through ISpect.
Future<void> webSocketChannelExample(ISpectLogger logger) async {
  const url = 'wss://echo.websocket.events';

  final diagnostics =
      ISpectWebSocketChannelDiagnostics(logger: logger, url: url);
  final socket = WebSocketChannel.connect(Uri.parse(url));
  final channel = diagnostics.wrap(socket);

  await socket.ready;
  final sub = channel.stream.listen((_) {});
  channel.sink.add('hello');

  await Future<void>.delayed(const Duration(seconds: 1));
  await sub.cancel();
  await channel.sink.close();
}
