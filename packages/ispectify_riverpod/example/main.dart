import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:riverpod/riverpod.dart';

final counterProvider = StateProvider<int>((_) => 0, name: 'counter');

Future<void> main() async {
  final logger = ISpectLogger();
  final container = ProviderContainer(
    observers: [ISpectRiverpodObserver(logger: logger)],
  );

  container.read(counterProvider.notifier).state++;
  container.dispose();
}
