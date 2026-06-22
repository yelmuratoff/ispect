import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

class _FakeSender implements NetworkRequestSender {
  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async =>
      const NetworkReplayResult(statusCode: 200);
}

void main() {
  group('ISpect sender registration', () {
    tearDown(ISpect.dispose);

    test('exposes no senders by default', () async {
      await ISpect.dispose();

      expect(ISpect.senders, isEmpty);
    });

    test('registerSender is a no-op when ISpect is disabled', () async {
      await ISpect.dispose();

      ISpect.registerSender(_FakeSender());

      // kISpectEnabled is false in the test env: production builds must not
      // retain the client or expose request sending.
      expect(ISpect.senders, isEmpty);
    });

    test('unregisterSender on an empty registry is safe', () async {
      await ISpect.dispose();

      expect(() => ISpect.unregisterSender('missing'), returnsNormally);
    });
  });
}
