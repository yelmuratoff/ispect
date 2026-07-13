import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/examples/example_app.dart';
import 'package:ispectify_ws/ispectify_ws.dart';

void main() {
  final logger = ISpectFlutter.init();
  final navigatorObserver = ISpectNavigatorObserver();
  final diagnostics = WsDiagnostics(logger: logger);

  ISpect.run(
    () => runApp(
      buildExampleApp(
        title: 'ISpect WebSocket example',
        observer: navigatorObserver,
        home: _WebSocketPage(diagnostics: diagnostics),
      ),
    ),
    logger: logger,
  );
}

final class _WebSocketPage extends StatelessWidget {
  const _WebSocketPage({required this.diagnostics});

  final WsDiagnostics diagnostics;
  static final Uri _url = Uri.parse('wss://example.com/socket');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('WebSocket diagnostics')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              diagnostics
                ..newConnection()
                ..onStateChanged(WsConnectionState.open, url: _url.toString())
                ..onSent('{"event":"ping"}', url: _url.toString())
                ..onReceived('{"event":"pong"}', url: _url.toString());
            },
            child: const Text('Emit a sample WebSocket exchange'),
          ),
        ),
      );
}
