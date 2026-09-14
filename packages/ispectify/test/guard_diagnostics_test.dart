import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('guardDiagnostics', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger.testing(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    tearDown(() => logger.dispose());

    test('runs the action when it succeeds', () {
      var ran = false;

      guardDiagnostics(logger, () => ran = true, what: 'Probe');

      expect(ran, isTrue);
      expect(logger.history, isEmpty);
    });

    test('converts a thrown failure into a type-only warning', () {
      expect(
        () => guardDiagnostics(
          logger,
          () => throw StateError('tenantSecret=GUARD_SECRET'),
          what: 'Probe capture',
        ),
        returnsNormally,
      );

      final warning = logger.history.single;
      expect(warning.message, 'Probe capture failed safely: StateError');
      expect(warning.logLevel, LogLevel.warning);
      expect(warning.message, isNot(contains('GUARD_SECRET')));
    });

    test('reports an opaque type under strict capture', () {
      final strict = ISpectLogger.testing(
        options: ISpectLoggerOptions(
          useConsoleLogs: false,
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );
      addTearDown(strict.dispose);

      guardDiagnostics(strict, () => throw StateError('x'), what: 'Probe');

      expect(
        strict.history.single.message,
        'Probe failed safely: unknown error',
      );
    });
  });
}
