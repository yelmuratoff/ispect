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

    test(
      'lazy logger is disabled and retains no history when gated off',
      () async {
        await ISpect.dispose();

        final logger = ISpect.logger;

        expect(logger.options.enabled, isFalse);

        logger.info('diagnostic that must not be retained in production');

        expect(logger.history, isEmpty);
      },
      skip: kISpectEnabled,
    );

    test('dispose() resets state and allows a fresh lazy logger', () async {
      await ISpect.dispose();

      final original = ISpect.logger;
      await ISpect.dispose();
      final replacement = ISpect.logger;

      expect(identical(original, replacement), isFalse);
      expect(replacement.isDisposed, isFalse);
    });

    test(
      'explicit initialize() replaces and retires the lazy logger',
      () async {
        await ISpect.dispose();
        final lazy = ISpect.logger;
        final custom = ISpectLogger(
          options: ISpectLoggerOptions(useConsoleLogs: false),
        );

        expect(ISpect.initialize(custom), isTrue);

        expect(lazy.isDisposed, isTrue);
        expect(ISpect.logger, same(custom));
        expect(ISpect.loggerIfInitialized, same(custom));
      },
      skip: !kISpectEnabled,
    );

    test('forced initialization disposes the replaced logger', () async {
      await ISpect.dispose();
      final original = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final replacement = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      expect(ISpect.initialize(original), isTrue);
      expect(ISpect.initialize(replacement, force: true), isTrue);

      expect(original.isDisposed, isTrue);
      expect(replacement.isDisposed, isFalse);
      expect(ISpect.logger, same(replacement));
    }, skip: !kISpectEnabled);

    test('forced initialization keeps the same logger active', () async {
      await ISpect.dispose();
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      expect(ISpect.initialize(logger), isTrue);
      expect(ISpect.initialize(logger, force: true), isTrue);

      expect(logger.isDisposed, isFalse);
      expect(ISpect.logger, same(logger));
    }, skip: !kISpectEnabled);

    test('initialization rejects an already disposed logger', () async {
      await ISpect.dispose();
      final disposed = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      await disposed.dispose();

      expect(ISpect.initialize(disposed), isFalse);
      expect(() => ISpect.run(() {}, logger: disposed), throwsStateError);
      expect(ISpect.loggerIfInitialized, isNull);
    }, skip: !kISpectEnabled);

    test('a retired logger cannot be installed again', () async {
      await ISpect.dispose();
      final original = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final replacement = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      expect(ISpect.initialize(original), isTrue);
      expect(ISpect.initialize(replacement, force: true), isTrue);
      expect(original.isDisposed, isTrue);

      expect(ISpect.initialize(original, force: true), isFalse);
      expect(ISpect.logger, same(replacement));
    }, skip: !kISpectEnabled);
  });
}
