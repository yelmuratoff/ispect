import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

class _FakeSender implements NetworkRequestSender {
  _FakeSender(this.id, this.label);

  @override
  final String id;

  @override
  final String label;

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async =>
      const NetworkReplayResult(statusCode: 200);
}

void main() {
  group('NetworkSenderRegistry', () {
    test('starts empty', () {
      final registry = NetworkSenderRegistry();
      expect(registry.hasSenders, isFalse);
      expect(registry.senders, isEmpty);
    });

    test('registers and looks up senders by id', () {
      final registry = NetworkSenderRegistry()
        ..register(_FakeSender('dio', 'API'));

      expect(registry.hasSenders, isTrue);
      expect(registry.byId('dio')?.label, 'API');
      expect(registry.byId('missing'), isNull);
    });

    test('replaces a sender registered with the same id', () {
      final registry = NetworkSenderRegistry()
        ..register(_FakeSender('dio', 'old'))
        ..register(_FakeSender('dio', 'new'));

      expect(registry.senders, hasLength(1));
      expect(registry.byId('dio')?.label, 'new');
    });

    test('unregisters and clears', () {
      final registry = NetworkSenderRegistry()
        ..register(_FakeSender('dio', 'API'))
        ..register(_FakeSender('http', 'Http'))
        ..unregister('dio');

      expect(registry.byId('dio'), isNull);
      expect(registry.senders, hasLength(1));

      registry.clear();
      expect(registry.hasSenders, isFalse);
    });
  });
}
