import 'package:flutter_test/flutter_test.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/shared_preferences_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ISpectLogger logger;
  late ISpectSharedPreferences traced;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();
    final prefs = await SharedPreferences.getInstance();
    traced = ISpectSharedPreferences(delegate: prefs, logger: logger);
  });

  tearDown(() => ISpectDbCore.config = ISpectDbConfig());

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('reads', () {
    test('getString logs read with cache hit', () {
      final value = traced.getString('theme');

      expect(value, 'dark');
      expect(lastAdditional()['source'], 'shared_prefs');
      expect(lastAdditional()['operation'], 'read');
      expect(lastAdditional()['key'], 'theme');
      expect(lastAdditional()['cacheHit'], isTrue);
    });

    test('getString logs miss for absent key', () {
      expect(traced.getString('missing'), isNull);
      expect(lastAdditional()['cacheHit'], isFalse);
    });

    test('getBool logs read', () async {
      await traced.setBool('flag', true);
      expect(traced.getBool('flag'), isTrue);
    });

    test('getInt logs read', () async {
      await traced.setInt('count', 42);
      expect(traced.getInt('count'), 42);
    });

    test('getDouble logs read', () async {
      await traced.setDouble('ratio', 3.14);
      expect(traced.getDouble('ratio'), 3.14);
    });

    test('getStringList logs read', () async {
      await traced.setStringList('tags', ['a', 'b']);
      expect(traced.getStringList('tags'), ['a', 'b']);
    });
  });

  group('writes', () {
    test('setString stores and logs', () async {
      final ok = await traced.setString('lang', 'en');

      expect(ok, isTrue);
      expect(traced.getString('lang'), 'en');

      final writeLog = logger.history.firstWhere(
        (e) =>
            e.additionalData?['operation'] == 'write' &&
            e.additionalData?['key'] == 'lang',
      );
      expect(writeLog.additionalData?['source'], 'shared_prefs');
    });
  });

  group('containsKey', () {
    test('logs lookup', () {
      expect(traced.containsKey('theme'), isTrue);
      expect(lastAdditional()['operation'], 'lookup');
      expect(lastAdditional()['cacheHit'], isTrue);
    });
  });

  group('getKeys', () {
    test('logs list with count', () {
      final keys = traced.getKeys();

      expect(keys, contains('theme'));
      expect(lastAdditional()['operation'], 'list');
      expect(lastAdditional()['items'], isPositive);
    });
  });

  group('remove / clear', () {
    test('remove logs delete', () async {
      await traced.remove('theme');

      expect(lastAdditional()['operation'], 'delete');
      expect(lastAdditional()['key'], 'theme');
    });

    test('clear logs', () async {
      await traced.clear();

      expect(lastAdditional()['operation'], 'clear');
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final prefs = await SharedPreferences.getInstance();
      ISpectSharedPreferences(
        delegate: prefs,
        logger: logger,
        source: 'prefs-v2',
      ).getString('theme');

      expect(lastAdditional()['source'], 'prefs-v2');
    });
  });
}
