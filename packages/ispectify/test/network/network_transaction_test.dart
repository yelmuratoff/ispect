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

void main() {
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
