import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

ISpectLogData _request({
  String method = 'DELETE',
  String? contentType,
  int? contentLength,
}) =>
    ISpectLogData(
      'request',
      additionalData: {
        TraceKeys.category: TraceCategoryIds.network,
        TraceKeys.operation: method,
        TraceKeys.target: 'https://api.example.com/products/1',
        TraceKeys.meta: {
          NetworkJsonKeys.requestId: 'rid-1',
          NetworkJsonKeys.requestData: {
            NetworkJsonKeys.method: method,
            if (contentType != null) NetworkJsonKeys.contentType: contentType,
            if (contentLength != null)
              NetworkJsonKeys.contentLength: contentLength,
          },
        },
      },
    );

ISpectLogData _response({
  int statusCode = 200,
  String? statusMessage = 'OK',
  int? contentLength,
}) =>
    ISpectLogData(
      'response',
      additionalData: {
        TraceKeys.category: TraceCategoryIds.network,
        TraceKeys.meta: {
          NetworkJsonKeys.statusCode: statusCode,
          NetworkJsonKeys.responseData: {
            NetworkJsonKeys.statusCode: statusCode,
            if (statusMessage != null)
              NetworkJsonKeys.statusMessage: statusMessage,
            if (contentLength != null)
              NetworkJsonKeys.contentLength: contentLength,
          },
        },
      },
    );

ISpectLogData _error({
  int statusCode = 500,
  String statusMessage = 'Internal Server Error',
}) =>
    ISpectLogData(
      'error',
      additionalData: {
        TraceKeys.category: TraceCategoryIds.network,
        TraceKeys.meta: {
          NetworkJsonKeys.statusCode: statusCode,
          NetworkJsonKeys.errorData: {
            NetworkJsonKeys.response: {
              NetworkJsonKeys.statusCode: statusCode,
              NetworkJsonKeys.statusMessage: statusMessage,
            },
          },
        },
      },
    );

final class _HostileTransactionLogGetters extends ISpectLogData {
  _HostileTransactionLogGetters({
    required DateTime time,
    required Map<String, dynamic> additionalData,
  }) : super(
          'trusted-transaction-message',
          time: time,
          additionalData: additionalData,
        );

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError('FORGED_TRANSACTION_GETTER_SECRET');
  }

  @override
  DateTime get time => _forged();

  @override
  Map<String, dynamic>? get additionalData => _forged();
}

void main() {
  test('derived fields ignore hostile log getter overrides', () {
    final request = _HostileTransactionLogGetters(
      time: DateTime.utc(2026),
      additionalData: const {
        TraceKeys.operation: 'POST',
        TraceKeys.target: 'https://api.example.com/safe',
        TraceKeys.meta: {
          NetworkJsonKeys.requestData: {
            NetworkJsonKeys.contentType: 'application/json',
            NetworkJsonKeys.contentLength: 10,
          },
        },
      },
    );
    final response = _HostileTransactionLogGetters(
      time: DateTime.utc(2026).add(const Duration(seconds: 2)),
      additionalData: const {
        TraceKeys.meta: {
          NetworkJsonKeys.statusCode: 201,
          NetworkJsonKeys.responseData: {
            NetworkJsonKeys.statusMessage: 'Created',
            NetworkJsonKeys.contentLength: 20,
          },
        },
      },
    );
    final transaction = NetworkTransaction(
      requestId: 'trusted-request',
      request: request,
      response: response,
    );

    expect(transaction.duration, const Duration(seconds: 2));
    expect(transaction.method, 'POST');
    expect(transaction.url, 'https://api.example.com/safe');
    expect(transaction.statusCode, 201);
    expect(transaction.statusMessage, 'Created');
    expect(transaction.requestContentType, 'application/json');
    expect(transaction.requestContentLength, 10);
    expect(transaction.responseContentLength, 20);
    expect(request.getterCalls, 0);
    expect(response.getterCalls, 0);
  });

  group('NetworkTransaction.statusCode', () {
    test('reads the status code from the response trace meta', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(),
        response: _response(statusCode: 204),
      );
      expect(tx.statusCode, 204);
    });

    test('reads the status code from the error trace meta', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(),
        error: _error(statusCode: 503),
      );
      expect(tx.statusCode, 503);
    });

    test('is null while the request is pending', () {
      final tx = NetworkTransaction(requestId: 'rid-1', request: _request());
      expect(tx.statusCode, isNull);
    });

    test('malformed v4 metadata is ignored instead of throwing', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: ISpectLogData(
          'request',
          additionalData: const {
            'method': 42,
            'url': <String>['not', 'a', 'url'],
          },
        ),
        response: ISpectLogData(
          'response',
          additionalData: const {'statusCode': '200'},
        ),
        error: ISpectLogData(
          'error',
          additionalData: const {
            'statusCode': <String, int>{'bad': 500},
          },
        ),
      );

      expect(tx.statusCode, isNull);
      expect(tx.method, isNull);
      expect(tx.url, isNull);
    });
  });

  group('NetworkTransaction.statusMessage', () {
    test('reads the reason phrase from the response', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(),
        response: _response(statusMessage: 'No Content'),
      );
      expect(tx.statusMessage, 'No Content');
    });

    test('reads the reason phrase from the nested error response', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(),
        error: _error(statusMessage: 'Bad Gateway'),
      );
      expect(tx.statusMessage, 'Bad Gateway');
    });

    test('is null when the reason phrase is empty', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(),
        response: _response(statusMessage: ''),
      );
      expect(tx.statusMessage, isNull);
    });
  });

  group('NetworkTransaction content metadata', () {
    test('exposes request content type and length when reported', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(contentType: 'application/json', contentLength: 532),
        response: _response(),
      );
      expect(tx.requestContentType, 'application/json');
      expect(tx.requestContentLength, 532);
    });

    test('exposes response content length when reported', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(),
        response: _response(contentLength: 1234),
      );
      expect(tx.responseContentLength, 1234);
    });

    test('returns null for absent or non-positive sizes', () {
      final tx = NetworkTransaction(
        requestId: 'rid-1',
        request: _request(contentLength: -1),
        response: _response(),
      );
      expect(tx.requestContentType, isNull);
      expect(tx.requestContentLength, isNull);
      expect(tx.responseContentLength, isNull);
    });
  });
}
