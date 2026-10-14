import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogType lookups', () {
    test('fromLogLevel returns canonical type', () {
      expect(ISpectLogType.fromLogLevel(LogLevel.error), ISpectLogType.error);
      expect(
        ISpectLogType.fromLogLevel(LogLevel.warning),
        ISpectLogType.warning,
      );
    });

    test('fromKey returns matching enum', () {
      expect(ISpectLogType.fromKey('http-request'), ISpectLogType.httpRequest);
      expect(ISpectLogType.fromKey('missing'), isNull);
    });

    test('isErrorKey matches cached set', () {
      expect(ISpectLogType.isErrorKey('db-error'), isTrue);
      expect(ISpectLogType.isErrorKey('route'), isFalse);
    });
  });

  group('ISpectLogType console pens', () {
    String paint(ISpectLogType type) => type.defaultPen('x');

    setUp(() {
      final previous = ansiColorDisabled;
      ansiColorDisabled = false;
      addTearDown(() => ansiColorDisabled = previous);
    });

    test('every built-in error type paints like error', () {
      final errorTypes = ISpectLogType.keys
          .map(ISpectLogType.fromKey)
          .whereType<ISpectLogType>()
          .where((type) => type.isError);

      for (final type in errorTypes) {
        expect(paint(type), paint(ISpectLogType.error), reason: type.key);
      }
    });

    test('performance jank paints like a warning', () {
      expect(
        paint(ISpectLogType.performanceJank),
        paint(ISpectLogType.warning),
      );
    });
  });

  group('trace default level', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    test('performance jank records the warning level its type declares', () {
      logger.performanceJank(
        source: 'frame',
        buildDuration: const Duration(milliseconds: 30),
        rasterDuration: const Duration(milliseconds: 5),
        totalSpan: const Duration(milliseconds: 35),
        targetFrameTime: const Duration(milliseconds: 16),
      );

      final log = logger.history.single;
      expect(log.key, ISpectLogType.performanceJank.key);
      expect(log.logLevel, LogLevel.warning);
    });

    test('a key without a declared type still records info', () {
      logger.traceCategory(
        category: const ISpectTraceCategory(
          id: 'custom',
          successKey: 'custom-op',
          errorKey: 'custom-error',
        ),
        source: 'src',
        operation: 'op',
      );

      expect(logger.history.single.logLevel, LogLevel.info);
    });

    test('explicit logLevel wins over the type level', () {
      logger.trace(
        category: performanceCategory,
        source: 'frame',
        operation: 'jank',
        logLevel: LogLevel.debug,
      );

      expect(logger.history.single.logLevel, LogLevel.debug);
    });
  });
}
