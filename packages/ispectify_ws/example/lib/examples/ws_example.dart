import 'dart:async';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/interceptors/ws_interceptor.dart';
import 'package:ws/ws.dart';

/// Connects with the `ws` client and logs frames, metrics, and state changes.
Future<void> wsExample(ISpectLogger logger) async {
  const url = 'wss://echo.plugfox.dev:443/connect';

  final interceptor = ISpectWSInterceptor(logger: logger);
  final client = WebSocketClient(
    WebSocketOptions.common(interceptors: [interceptor]),
  );
  interceptor.setClient(client);

  await client.connect(url);
  client
    ..add('Hello')
    ..add('world!');

  await Future<void>.delayed(const Duration(seconds: 1));
  await client.close();
  await interceptor.dispose();
}
