import 'dart:async';
import 'dart:io' as io show exit;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';

void main([List<String>? args]) {
  // Using a non-existent WebSocket URL to trigger a connection error.
  const url = String.fromEnvironment(
    'URL',
    defaultValue: 'wss://echo.plugfox.dev:443/non-existent-path',
  );
  final logger = ISpectify();

  final interceptor = ISpectWSInterceptor(logger: logger);

  final client = WebSocketClient(
    WebSocketOptions.common(
      connectionRetryInterval: (
        min: const Duration(milliseconds: 500),
        max: const Duration(seconds: 15),
      ),
      interceptors: [interceptor],
    ),
  );

  interceptor.setClient(client);

  client
    ..connect(url)
    ..add('Hello')
    ..add('world!');

  // Adding a client-side error by trying to send data after closing the connection.
  Timer(const Duration(seconds: 1), () async {
    await client.close();
    try {
      unawaited(client.add('This will fail'));
    } catch (e) {
      // This error will be caught by the interceptor.
    }
    // ignore: avoid_print
    print('Metrics:\n${client.metrics}');
    io.exit(0);
  });
}
