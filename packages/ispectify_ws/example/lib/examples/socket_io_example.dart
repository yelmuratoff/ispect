import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/interceptors/socket_io_interceptor.dart';
import 'package:socket_io_client/socket_io_client.dart';

/// Connects with `socket_io_client` and logs lifecycle, inbound, and outbound
/// events through ISpect.
Future<void> socketIoExample(ISpectLogger logger) async {
  const url = 'https://example.com';

  final diagnostics = ISpectSocketIoDiagnostics(logger: logger, url: url);
  final socket = io(
    url,
    OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
  );

  diagnostics.bind(socket);
  socket.connect();
  diagnostics.emit(socket, 'message', {'text': 'hi'});

  await Future<void>.delayed(const Duration(seconds: 1));
  socket.dispose();
}
