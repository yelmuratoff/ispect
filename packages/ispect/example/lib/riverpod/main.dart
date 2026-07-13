import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/examples/example_app.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';

final _counterProvider = StateProvider<int>((_) => 0, name: 'counter');

void main() {
  final logger = ISpectFlutter.init();
  final navigatorObserver = ISpectNavigatorObserver();
  ISpect.run(
    () => runApp(
      ProviderScope(
        observers: [ISpectRiverpodObserver(logger: logger)],
        child: buildExampleApp(
          title: 'ISpect Riverpod example',
          observer: navigatorObserver,
          home: const _RiverpodPage(),
        ),
      ),
    ),
    logger: logger,
  );
}

final class _RiverpodPage extends ConsumerWidget {
  const _RiverpodPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_counterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod diagnostics')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref.read(_counterProvider.notifier).state++,
          child: Text('Increment: $count'),
        ),
      ),
    );
  }
}
