import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';
import 'package:ispectify/ispectify.dart';

ISpectLogData _request({String? contentType, int? contentLength}) =>
    ISpectLogData(
      'request',
      additionalData: {
        TraceKeys.meta: {
          NetworkJsonKeys.requestData: {
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

void main() {
  group('transactionListUrl', () {
    test('strips scheme and host, keeping the path when compact', () {
      expect(
        transactionListUrl(
          'https://dev-klara.theklara.com/gateway-klara/api/bff/v1/chat/user/chats',
          compact: true,
        ),
        '/gateway-klara/api/bff/v1/chat/user/chats',
      );
    });

    test('keeps the query alongside the path when compact', () {
      expect(
        transactionListUrl(
          'https://api.example.com/users?page=2',
          compact: true,
        ),
        '/users?page=2',
      );
    });

    test('returns the full URL when not compact', () {
      const url = 'https://api.example.com/users?page=2';
      expect(transactionListUrl(url, compact: false), url);
    });

    test('returns relative URLs unchanged', () {
      expect(transactionListUrl('/users/42', compact: true), '/users/42');
    });

    test('falls back to the full URL when there is no path', () {
      expect(
        transactionListUrl('https://api.example.com', compact: true),
        'https://api.example.com',
      );
    });

    test('returns empty string for null or empty input', () {
      expect(transactionListUrl(null, compact: true), '');
      expect(transactionListUrl('', compact: true), '');
    });
  });

  group('transactionStatusSummary', () {
    test('shows the reason phrase without the duplicated status code', () {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(),
        response: _response(),
      );
      expect(transactionStatusSummary(tx), 'OK');
    });

    test('appends the response size when reported', () {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(),
        response: _response(contentLength: 2048),
      );
      expect(transactionStatusSummary(tx), 'OK · 2.0 KB');
    });

    test('falls back to the code when the server reports no reason', () {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(),
        response: _response(statusCode: 204, statusMessage: null),
      );
      expect(transactionStatusSummary(tx), '204');
    });

    test('is empty for a pending transaction', () {
      final tx = NetworkTransaction(requestId: 'r', request: _request());
      expect(transactionStatusSummary(tx), '');
    });
  });

  group('transactionRequestSummary', () {
    test('joins request content type and size', () {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(contentType: 'application/json', contentLength: 532),
        response: _response(),
      );
      expect(transactionRequestSummary(tx), 'application/json · 532 B');
    });

    test('is empty when the request reports neither', () {
      final tx = NetworkTransaction(
        requestId: 'r',
        request: _request(),
        response: _response(),
      );
      expect(transactionRequestSummary(tx), '');
    });
  });
}
