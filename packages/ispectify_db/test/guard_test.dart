import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:test/test.dart';

const _invalidConfig = ISpectDbConfig(
  resourceLimits: DiagnosticResourceLimits(maxCapturedValueBytes: -1),
);

void main() {
  group('logging failures never break the host repository', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    tearDown(() => logger.dispose());

    List<String?> warnings() => logger.history
        .where((log) => log.logLevel == LogLevel.warning)
        .map((log) => log.message)
        .toList();

    test('db() returns normally when capture throws', () {
      expect(
        () => logger.db(
          source: 'sqlite',
          operation: 'query',
          statement: 'SELECT 1',
          config: _invalidConfig,
        ),
        returnsNormally,
      );

      expect(
        warnings(),
        ['Database trace capture failed safely: ArgumentError'],
      );
    });

    test('dbTrace still returns the run result when capture throws', () async {
      final result = await logger.dbTrace<int>(
        source: 'sqlite',
        operation: 'query',
        statement: 'SELECT 1',
        config: _invalidConfig,
        run: () async => 42,
      );

      expect(result, 42);
      expect(
        warnings(),
        ['Database trace capture failed safely: ArgumentError'],
      );
    });
  });
}
