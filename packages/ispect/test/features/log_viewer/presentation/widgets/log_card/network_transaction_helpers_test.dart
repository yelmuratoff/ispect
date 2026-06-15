import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';

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
}
