import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_ws_example/examples/socket_io_example.dart';
import 'package:ispectify_ws_example/examples/web_socket_channel_example.dart';
import 'package:ispectify_ws_example/examples/ws_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISpect WS Examples',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ExamplesPage(),
    );
  }
}

class ExamplesPage extends StatefulWidget {
  const ExamplesPage({super.key});

  @override
  State<ExamplesPage> createState() => _ExamplesPageState();
}

class _ExamplesPageState extends State<ExamplesPage> {
  final ISpectLogger _logger = ISpectLogger();
  late final Map<String, Future<void> Function(ISpectLogger)> _examples = {
    'ws (plugfox)': wsExample,
    'socket_io_client': socketIoExample,
    'web_socket_channel': webSocketChannelExample,
  };

  String _status = 'Ready';
  bool _isRunning = false;

  Future<void> _run(
    String name,
    Future<void> Function(ISpectLogger) runner,
  ) async {
    setState(() {
      _isRunning = true;
      _status = 'Running $name...';
    });
    try {
      await runner(_logger);
      setState(() => _status = 'Success: $name');
    } catch (e, st) {
      _logger.handle(exception: e, stackTrace: st, message: '$name failed');
      setState(() => _status = 'Error in $name: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISpect WS Adapters')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blueGrey.shade900,
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isRunning) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              children: [
                for (final entry in _examples.entries)
                  ListTile(
                    title: Text(entry.key),
                    trailing: const Icon(Icons.play_arrow),
                    onTap:
                        _isRunning ? null : () => _run(entry.key, entry.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
