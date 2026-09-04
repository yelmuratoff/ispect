import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

final class _ThrowingPattern implements Pattern {
  const _ThrowingPattern();

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      throw StateError('tenantSecret=PATTERN_SECRET');

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      throw StateError('tenantSecret=PATTERN_SECRET');
}

final _counter = StateProvider<int>((ref) => 0, name: 'counter');

void main() {
  test('a throwing filter pattern never propagates into the provider update',
      () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final container = ProviderContainer(
      observers: [
        ISpectRiverpodObserver(
          logger: logger,
          filters: const [_ThrowingPattern()],
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(_counter.notifier).state = 1,
      returnsNormally,
    );

    final operations = logger.history
        .map((log) => log.additionalData?[TraceKeys.operation])
        .toList();
    expect(operations, contains('update'));
    expect(
      logger.history.map((log) => log.message).join(),
      isNot(contains('PATTERN_SECRET')),
    );
  });
}
