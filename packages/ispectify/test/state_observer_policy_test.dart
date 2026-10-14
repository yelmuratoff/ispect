import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _CountingPattern implements Pattern {
  _CountingPattern(this.onMatch);

  final void Function() onMatch;
  int calls = 0;

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    calls++;
    onMatch();
    return const <Match>[];
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    calls++;
    onMatch();
    return null;
  }
}

final class _ThrowingPattern implements Pattern {
  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      throw StateError('pattern failed');

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      throw StateError('pattern failed');
}

void main() {
  group('StateObserverPolicy.matchesAnyPattern', () {
    test('matches when any pattern is contained in the candidate', () {
      expect(
        StateObserverPolicy.matchesAnyPattern(
          'CounterBloc',
          const ['Auth', 'Counter'],
          isEnabled: () => true,
        ),
        isTrue,
      );
    });

    test('does not match when no pattern is contained', () {
      expect(
        StateObserverPolicy.matchesAnyPattern(
          'CounterBloc',
          [RegExp('^Auth')],
          isEnabled: () => true,
        ),
        isFalse,
      );
    });

    test('treats a throwing pattern as no match', () {
      expect(
        StateObserverPolicy.matchesAnyPattern(
          'CounterBloc',
          [_ThrowingPattern()],
          isEnabled: () => true,
        ),
        isFalse,
      );
    });

    test('stops and reports a match once the gate closes mid-scan', () {
      var enabled = true;
      final closing = _CountingPattern(() => enabled = false);
      final later = _CountingPattern(() {});

      final matched = StateObserverPolicy.matchesAnyPattern(
        'CounterBloc',
        [closing, later],
        isEnabled: () => enabled,
      );

      expect(matched, isTrue);
      expect(closing.calls, greaterThan(0));
      expect(later.calls, 0);
    });
  });

  group('StateObserverPolicy gates', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    test('logging follows the compile gate and settings flag', () {
      expect(
        StateObserverPolicy.loggingEnabled(
          logger: logger,
          settingsEnabled: true,
        ),
        kISpectEnabled,
      );
      expect(
        StateObserverPolicy.loggingEnabled(
          logger: logger,
          settingsEnabled: false,
        ),
        isFalse,
      );
    });

    test('the debug override can only narrow the gate', () {
      expect(
        StateObserverPolicy.loggingEnabled(
          logger: logger,
          settingsEnabled: true,
          debugEnabledOverride: false,
        ),
        isFalse,
      );
      expect(
        StateObserverPolicy.captureEnabled(
          logger: logger,
          settingsEnabled: true,
          debugEnabledOverride: true,
        ),
        kISpectEnabled,
      );
    });

    test('capture is off when the logger is disabled', () {
      logger.configure(options: ISpectLoggerOptions(enabled: false));

      expect(
        StateObserverPolicy.captureEnabled(
          logger: logger,
          settingsEnabled: true,
        ),
        isFalse,
      );
    });
  });

  group('StateTracePreparer.resolve', () {
    final redactor = RedactionService();

    StateTracePreparer resolve({
      bool redactionActive = true,
      DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
      DiagnosticResourceLimits resourceLimits =
          DiagnosticResourceLimits.balanced,
      StateTracePreparer? cached,
    }) =>
        StateTracePreparer.resolve(
          redactionActive: redactionActive,
          redactor: redactor,
          captureMode: captureMode,
          resourceLimits: resourceLimits,
          cached: cached,
        );

    test('uses the explicit redactor when redaction is active', () {
      expect(resolve().redactor, same(redactor));
    });

    test('drops the redactor when redaction is inactive', () {
      expect(resolve(redactionActive: false).redactor, isNull);
    });

    test('reuses a cached preparer with the same policy', () {
      final cached = resolve();

      expect(resolve(cached: cached), same(cached));
    });

    test('replaces the cache when the policy changes', () {
      final cached = resolve();

      expect(
        resolve(cached: cached, captureMode: DiagnosticCaptureMode.strict),
        isNot(same(cached)),
      );
      expect(
        resolve(
          cached: cached,
          resourceLimits: DiagnosticResourceLimits.constrained,
        ),
        isNot(same(cached)),
      );
      expect(
        resolve(cached: cached, redactionActive: false),
        isNot(same(cached)),
      );
    });

    test('trace config disables trace redaction and attaches stacks', () {
      final config = resolve(
        resourceLimits: DiagnosticResourceLimits.constrained,
      ).traceConfig;

      expect(config.redact, isFalse);
      expect(config.attachStackOnError, isTrue);
      expect(config.resourceLimits, same(DiagnosticResourceLimits.constrained));
    });
  });
}
