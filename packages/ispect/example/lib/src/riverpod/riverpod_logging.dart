import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect/ispect.dart';

class ISpectRiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value,
      ProviderContainer container) {
    ISpect.logger.log('riverpod add: ${provider.name ?? provider.runtimeType}',
        type: ISpectifyLogType.riverpodAdd);
    super.didAddProvider(provider, value, container);
  }

  @override
  void didUpdateProvider(ProviderBase<Object?> provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    ISpect.logger.log(
        'riverpod update: ${provider.name ?? provider.runtimeType}',
        type: ISpectifyLogType.riverpodUpdate);
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    ISpect.logger.log(
        'riverpod dispose: ${provider.name ?? provider.runtimeType}',
        type: ISpectifyLogType.riverpodDispose);
    super.didDisposeProvider(provider, container);
  }
}

final counterProvider = StateProvider<int>((ref) => 0, name: 'counterProvider');

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state = state + 1;
  void decrement() => state = state - 1;
  void set(int value) => state = value;
}

final counterNotifierProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
  name: 'counterNotifierProvider',
);

final failingFutureProvider = FutureProvider<String>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
  throw StateError('Riverpod failingFutureProvider error');
}, name: 'failingFutureProvider');

Future<void> triggerRiverpodActions(WidgetRef ref,
    {required int iterations, int delayMs = 0}) async {
  for (int i = 0; i < iterations; i++) {
    ref.read(counterProvider.notifier).state++;
    ref.read(counterNotifierProvider.notifier).increment();
    // Trigger an update
    // Read the value to cause an update notification
    // ignore: unused_local_variable
    final _ = ref.read(counterProvider);
    ref.read(counterNotifierProvider);
    // Trigger a failure log
    unawaited(ref.read(failingFutureProvider.future).catchError((e, st) {
      ISpect.logger
          .log('riverpod fail: $e', type: ISpectifyLogType.riverpodFail);
      return 'failed';
    }));
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}
