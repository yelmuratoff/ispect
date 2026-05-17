import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

ISpectLogData _data({
  Object? message = 'Hello',
  String? key,
  LogLevel? level,
  DateTime? time,
  Map<String, dynamic>? additionalData,
}) =>
    ISpectLogData(
      message,
      key: key,
      logLevel: level,
      time: time ?? DateTime.utc(2026, 4, 21, 1, 17, 7, 259),
      additionalData: additionalData,
    );

void main() {
  group('HumanLogEntryFormatter', () {
    const formatter = HumanLogEntryFormatter();
    final settings = ConsoleSettings(enableColors: false);

    test('pads level to the column width', () {
      final data = _data(level: LogLevel.info);
      final line = formatter.format(data, settings);
      expect(line, startsWith('INFO   '));
    });

    test('omits [key] when it is redundant with level name', () {
      final data = _data(level: LogLevel.info, key: 'info');
      final line = formatter.format(data, settings);
      expect(line, isNot(contains('[info]')));
      expect(line, contains('INFO   '));
    });

    test('shows [category] when it differs from level', () {
      final data = _data(level: LogLevel.info, key: 'route');
      final line = formatter.format(data, settings);
      expect(line, contains('INFO    [route] |'));
    });

    test('surfaces source from additionalData before category', () {
      final data = _data(
        level: LogLevel.info,
        key: 'route',
        additionalData: const {TraceKeys.source: 'NavObserver'},
      );
      final line = formatter.format(data, settings);
      expect(line, contains('[NavObserver] [route]'));
    });

    test('surfaces transactionId/correlationId/durationMs after timestamp', () {
      final data = _data(
        level: LogLevel.info,
        additionalData: const {
          TraceKeys.transactionId: 'tx-1',
          TraceKeys.correlationId: 'cid-2',
          TraceKeys.durationMs: 42,
        },
      );
      final line = formatter.format(data, settings);
      expect(line, contains('| tid=tx-1 cid=cid-2 dur=42ms |'));
    });

    test('shortens 16-char hex IDs to 8-char prefix', () {
      final data = _data(
        level: LogLevel.info,
        additionalData: const {
          TraceKeys.transactionId: '1579f34f3e3c5521',
          TraceKeys.correlationId: 'abcdef0123456789',
        },
      );
      final line = formatter.format(data, settings);
      expect(line, contains('tid=1579f34f'));
      expect(line, contains('cid=abcdef01'));
      expect(line, isNot(contains('1579f34f3e3c5521')));
    });

    test('keeps non-hex IDs intact', () {
      final data = _data(
        level: LogLevel.info,
        additionalData: const {
          TraceKeys.correlationId: 'order-batch-12345',
        },
      );
      final line = formatter.format(data, settings);
      expect(line, contains('cid=order-batch-12345'));
    });

    test('omits metadata section when no correlation fields present', () {
      final data = _data(level: LogLevel.info);
      final line = formatter.format(data, settings);
      expect(line, isNot(contains('tid=')));
      expect(line, isNot(contains('dur=')));
      // Only a single `|` separator between timestamp and message.
      final separators = '|'.allMatches(line).length;
      expect(separators, 2);
    });

    test('uses full ISO-8601 timestamp when fullTimestamp=true', () {
      final data = _data(level: LogLevel.info);
      final line =
          formatter.format(data, settings.copyWith(fullTimestamp: true));
      expect(line, contains('2026-04-'));
      expect(
        line,
        matches(RegExp(r'T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2}')),
      );
    });

    test('renders multi-line messages with indented continuation', () {
      final data = _data(message: 'Request:\ncurl -X GET ...');
      final line = formatter.format(data, settings);
      expect(line, contains('Request:\n  curl -X GET ...'));
    });

    test('uses "(empty log message)" for blank body', () {
      final data = _data(message: '');
      final line = formatter.format(data, settings);
      expect(line, endsWith(' | (empty log message)'));
    });
  });
}
