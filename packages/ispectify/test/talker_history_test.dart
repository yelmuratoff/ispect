import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('Talker_History', () {
    late ISpectiy iSpectify;

    setUp(() {
      iSpectify = ISpectiy(settings: ISpectifyOptions(useConsoleLogs: false));
      iSpectify.clearHistory();
    });

    test('ON', () {
      _configureTalker(useHistory: true, iSpectify: iSpectify);
      _makeLogs(iSpectify);

      final history = iSpectify.history;

      expect(history, isNotEmpty);
      expect(history.length, equals(5));
    });

    test('OFF', () {
      _configureTalker(useHistory: false, iSpectify: iSpectify);
      _makeLogs(iSpectify);

      final history = iSpectify.history;

      expect(history, isEmpty);
    });

    test('HostoryOverflow', () {
      _configureTalker(useHistory: true, iSpectify: iSpectify, maxHistoryItems: 4);
      _makeLogs(iSpectify);
      final history = iSpectify.history;
      expect(history, isNotEmpty);
      expect(history.length, 4);
      expect(history.last.logLevel, LogLevel.debug);
    });
  });
}

void _makeLogs(ISpectiy iSpectify) {
  iSpectify.error('log');
  iSpectify.info('log');
  iSpectify.verbose('log');
  iSpectify.warning('log');
  iSpectify.debug('log');
}

void _configureTalker({
  required bool useHistory,
  required ISpectiy iSpectify,
  int maxHistoryItems = 1000,
}) {
  iSpectify.configure(
    settings: ISpectifyOptions(
      useHistory: useHistory,
      useConsoleLogs: false,
      maxHistoryItems: maxHistoryItems,
    ),
  );
}
