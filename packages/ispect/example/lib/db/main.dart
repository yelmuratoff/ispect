import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/examples/example_app.dart';
import 'package:ispectify_db/ispectify_db.dart';

void main() {
  final logger = ISpectFlutter.init();
  final navigatorObserver = ISpectNavigatorObserver();

  ISpect.run(
    () => runApp(
      buildExampleApp(
        title: 'ISpect database example',
        observer: navigatorObserver,
        home: _DatabasePage(logger: logger),
      ),
    ),
    logger: logger,
  );
}

final class _DatabasePage extends StatelessWidget {
  const _DatabasePage({required this.logger});

  final ISpectLogger logger;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Database tracing')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await logger.dbTrace<String>(
                source: 'example',
                operation: 'query',
                statement: 'SELECT id FROM users WHERE id = ?',
                args: const [42],
                table: 'users',
                run: () async => 'user-42',
                projectResult: (value) => {'id': value},
                config: const ISpectDbConfig(redact: true),
              );
            },
            child: const Text('Trace a database operation'),
          ),
        ),
      );
}
