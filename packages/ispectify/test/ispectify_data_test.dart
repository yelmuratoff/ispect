import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogData Extensions', () {
    test('copy() creates exact duplicate preserving additionalData', () {
      final originalData = ISpectLogData(
        'Test message',
        logLevel: LogLevel.info,
        title: 'Test Title',
        key: 'test-key',
        additionalData: {
          'key1': 'value1',
          'key2': {'nested': 'value2'},
        },
      );

      final copiedData = originalData.copy();

      expect(copiedData.message, equals(originalData.message));
      expect(copiedData.logLevel, equals(originalData.logLevel));
      expect(copiedData.title, equals(originalData.title));
      expect(copiedData.key, equals(originalData.key));
      expect(copiedData.additionalData, equals(originalData.additionalData));
      expect(copiedData.time, equals(originalData.time));
      expect(copiedData.exception, equals(originalData.exception));
      expect(copiedData.error, equals(originalData.error));
      expect(copiedData.stackTrace, equals(originalData.stackTrace));
      expect(copiedData.pen, equals(originalData.pen));
    });

    test('copyWith() preserves additionalData when no parameters provided', () {
      final originalData = ISpectLogData(
        'Test message',
        additionalData: {
          'key1': 'value1',
          'key2': {'nested': 'value2'},
        },
      );

      final copiedData = originalData.copyWith();

      expect(copiedData.additionalData, equals(originalData.additionalData));
    });

    test('copyWith() allows overriding additionalData', () {
      final originalData = ISpectLogData(
        'Test message',
        additionalData: {'original': 'data'},
      );

      final newAdditionalData = {'new': 'data'};
      final copiedData = originalData.copyWith(
        additionalData: newAdditionalData,
      );

      expect(copiedData.additionalData, equals(newAdditionalData));
      expect(
        copiedData.additionalData,
        isNot(equals(originalData.additionalData)),
      );
    });

    test('copyWith() preserves additionalData when other fields are changed',
        () {
      final originalData = ISpectLogData(
        'Original message',
        title: 'Original Title',
        additionalData: {'important': 'metadata'},
      );

      final copiedData = originalData.copyWith(
        message: 'New message',
        title: 'New Title',
      );

      expect(copiedData.message, equals('New message'));
      expect(copiedData.title, equals('New Title'));
      expect(copiedData.additionalData, equals(originalData.additionalData));
    });

    test('curlCommand returns null for non-HTTP logs', () {
      final data = ISpectLogData('Test message');
      expect(data.curlCommand, isNull);
    });

    test('curlCommand generates cURL for HTTP request logs', () {
      final data = ISpectLogData(
        'Test request',
        key: 'http-request',
        additionalData: {
          'method': 'POST',
          'uri': 'https://example.com/api',
          'headers': {'Content-Type': 'application/json'},
          'data': '{"key": "value"}',
        },
      );

      final curl = data.curlCommand;
      expect(curl, isNotNull);
      expect(curl, contains('curl -X POST "https://example.com/api"'));
      expect(curl, contains('-H "Content-Type: application/json"'));
      expect(curl, contains("-d '{\"key\": \"value\"}'"));
    });

    test('curlCommand generates cURL for HTTP response logs', () {
      final data = ISpectLogData(
        'Response received',
        key: 'http-response',
        additionalData: {
          'request-options': {
            'method': 'POST',
            'uri': 'https://example.com/api',
            'headers': {'Content-Type': 'application/json'},
            'data': '{"key": "value"}',
          },
        },
      );

      final curl = data.curlCommand;
      expect(curl, isNotNull);
      expect(curl, contains('curl -X POST "https://example.com/api"'));
      expect(curl, contains('-H "Content-Type: application/json"'));
      expect(curl, contains("-d '{\"key\": \"value\"}'"));
    });

    test('curlCommand generates cURL for HTTP error logs', () {
      final data = ISpectLogData(
        'Request failed',
        key: 'http-error',
        additionalData: {
          'request-options': {
            'method': 'GET',
            'uri': 'https://example.com/fail',
            'headers': {'Authorization': 'Bearer token'},
          },
        },
      );

      final curl = data.curlCommand;
      expect(
        curl,
        equals(
          'curl -X GET "https://example.com/fail" -H "Authorization: Bearer token"',
        ),
      );
    });
  });
}
