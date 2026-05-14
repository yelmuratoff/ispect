import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkLogRenderer.isNetworkLog', () {
    test('returns false for entries without additionalData', () {
      expect(NetworkLogRenderer.isNetworkLog(ISpectLogData('plain')), isFalse);
    });

    test('returns false for non-network categories', () {
      final entry = ISpectLogData(
        'msg',
        additionalData: const {TraceKeys.category: 'db'},
      );
      expect(NetworkLogRenderer.isNetworkLog(entry), isFalse);
    });

    test('returns true for network category', () {
      final entry = ISpectLogData(
        'msg',
        additionalData: const {TraceKeys.category: TraceCategoryIds.network},
      );
      expect(NetworkLogRenderer.isNetworkLog(entry), isTrue);
    });

    test('returns true for ws category', () {
      final entry = ISpectLogData(
        'msg',
        additionalData: const {TraceKeys.category: TraceCategoryIds.ws},
      );
      expect(NetworkLogRenderer.isNetworkLog(entry), isTrue);
    });
  });

  group('NetworkLogRenderer.renderBody', () {
    test('returns empty string for non-network entries', () {
      final entry = ISpectLogData(
        'msg',
        additionalData: const {TraceKeys.category: 'db'},
      );
      expect(NetworkLogRenderer.renderBody(entry), isEmpty);
    });

    test('renders request body by default; hides headers by default', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'request-data': {
            'method': 'POST',
            'url': 'https://api.example.com/auth/login',
            'data': {'username': 'alice'},
            'headers': {'authorization': '[REDACTED]'},
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);

      expect(body, contains('Data'));
      expect(body, contains('alice'));
      expect(body, isNot(contains('Headers')));
      expect(body, isNot(contains('authorization')));
    });

    test('hint printHeaders=true exposes headers', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'request-data': {
            'headers': {'x-trace': 'abc'},
          },
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintHeaders: true,
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);

      expect(body, contains('Headers'));
      expect(body, contains('x-trace'));
    });

    test('hint printBody=false hides Data block', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'request-data': {
            'data': {'username': 'alice'},
          },
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintBody: false,
          },
        },
      );

      expect(NetworkLogRenderer.renderBody(entry), isEmpty);
    });

    test('renders response Status line plus Data block', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'response-data': {
            'status-code': 200,
            'status-message': 'OK',
            'data': {'id': 1},
            'headers': {'content-type': 'application/json'},
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);

      expect(body, contains('Status: 200'));
      expect(body, contains('Data'));
      expect(body, contains('"id": 1'));
      expect(body, isNot(contains('Message: OK')));
    });

    test('printMessage hint surfaces statusMessage', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'response-data': {
            'status-code': 200,
            'status-message': 'OK',
          },
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintMessage: true,
          },
        },
      );

      expect(NetworkLogRenderer.renderBody(entry), contains('Message: OK'));
    });

    test('http error route taken when only response-data is present with 4xx',
        () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'response-data': {
            'status-code': 401,
            'status-message': 'Unauthorized',
            'body': '{"reason": "token expired"}',
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);

      expect(body, contains('Status: 401'));
      expect(body, contains('token expired'));
    });

    test('dio error nested under error-data.response', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'error-data': {
            'message': 'Unauthorized',
            'response': {
              'status-code': 401,
              'status-message': 'Unauthorized',
              'data': {'reason': 'token expired'},
            },
          },
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintMessage: true,
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);

      expect(body, contains('Status: 401'));
      expect(body, contains('Error: Unauthorized'));
      expect(body, contains('token expired'));
    });

    test('skipEmpty drops empty headers section', () {
      final entry = ISpectLogData(
        'headline',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          'request-data': {
            'data': {'k': 'v'},
            'headers': <String, dynamic>{},
          },
          NetworkLogRenderer.renderHintsKey: {
            NetworkLogRenderer.hintPrintHeaders: true,
          },
        },
      );

      expect(NetworkLogRenderer.renderBody(entry), isNot(contains('Headers')));
    });

    test('ws renders Data block from raw payload', () {
      final entry = ISpectLogData(
        'send',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.ws,
          'data': {'type': 'ping'},
        },
      );

      expect(NetworkLogRenderer.renderBody(entry), contains('"type": "ping"'));
    });

    test('ws returns empty when no data payload captured', () {
      final entry = ISpectLogData(
        'send',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.ws,
        },
      );

      expect(NetworkLogRenderer.renderBody(entry), isEmpty);
    });

    test('reads payload nested under additionalData.meta (trace pipeline)', () {
      // Mirrors what traceCategory produces: caller-supplied meta is nested
      // under additionalData['meta'], not flattened.
      final entry = ISpectLogData(
        '→ POST /login',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          TraceKeys.meta: {
            'response-data': {
              'status-code': 200,
              'data': {'id': 1},
            },
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);
      expect(body, contains('Status: 200'));
      expect(body, contains('"id": 1'));
    });

    test('private render-hints do not leak into toJson output', () {
      final entry = ISpectLogData(
        '→ POST /login',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          TraceKeys.meta: {
            'request-id': 'rid-1',
            'response-data': {'status-code': 200},
            NetworkLogRenderer.renderHintsKey: {
              NetworkLogRenderer.hintPrintBody: true,
            },
          },
        },
      );

      final json = entry.toJson();
      final ad = json['additional-data'] as Map<String, dynamic>;
      final meta = ad[TraceKeys.meta] as Map<String, dynamic>;

      expect(meta['response-data'], isNotNull);
      expect(meta['request-id'], 'rid-1');
      expect(
        meta.containsKey(NetworkLogRenderer.renderHintsKey),
        isFalse,
        reason: 'underscore-prefixed keys are an internal contract',
      );
    });

    test('hints inside meta are honored', () {
      final entry = ISpectLogData(
        '→ POST /login',
        additionalData: const {
          TraceKeys.category: TraceCategoryIds.network,
          TraceKeys.meta: {
            'request-data': {
              'headers': {'x-trace': 'abc'},
              'data': {'k': 'v'},
            },
            NetworkLogRenderer.renderHintsKey: {
              NetworkLogRenderer.hintPrintHeaders: true,
            },
          },
        },
      );

      final body = NetworkLogRenderer.renderBody(entry);
      expect(body, contains('Headers'));
      expect(body, contains('x-trace'));
    });
  });
}
