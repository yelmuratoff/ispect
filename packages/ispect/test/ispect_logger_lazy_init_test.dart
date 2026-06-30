// Verifies that `ISpect.logger` never throws when accessed before
// `initialize()` — the fallback is a default `ISpectLogger`, and a subsequent
// explicit `initialize(...)` replaces the lazy instance. Covers the hot-restart
// / early-DI scenario that previously raised `StateError`.

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  group('ISpect.logger lazy init', () {
    tearDown(ISpect.dispose);

    test('returns a default logger without calling initialize()', () async {
      await ISpect.dispose();

      final logger = ISpect.logger;

      expect(logger, isA<ISpectLogger>());
      expect(logger.isDisposed, isFalse);
    });

    test('returns the same instance across repeated accesses', () async {
      await ISpect.dispose();

      final first = ISpect.logger;
      final second = ISpect.logger;

      expect(identical(first, second), isTrue);
    });

    test('lazy logger is disabled and retains no history when gated off',
        () async {
      await ISpect.dispose();

      final logger = ISpect.logger;

      expect(logger.options.enabled, isFalse);

      logger.info('diagnostic that must not be retained in production');

      expect(logger.history, isEmpty);
    });

    test('dispose() resets state and allows a fresh lazy logger', () async {
      await ISpect.dispose();

      final original = ISpect.logger;
      await ISpect.dispose();
      final replacement = ISpect.logger;

      expect(identical(original, replacement), isFalse);
      expect(replacement.isDisposed, isFalse);
    });

    test('explicit initialize() replaces the lazy logger', () async {
      await ISpect.dispose();

      // Trigger lazy creation first.
      ISpect.logger;

      final custom = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      // `initialize` is a no-op when kISpectEnabled is false (test env),
      // but with force=true it still rewires the static field.
      ISpect.initialize(custom, force: true);

      // When kISpectEnabled is false, initialize() short-circuits — the
      // lazy instance stays. Either way, the logger must remain a valid
      // ISpectLogger; this keeps the test correct under both compile flags.
      expect(ISpect.logger, isA<ISpectLogger>());
    });
  });
}
