import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectLogger.dispose', () {
    test('stops emitting logs and reports disposed state', () async {
      final logger = ISpectLogger();
      final received = <ISpectLogData>[];

      final subscription = logger.stream.listen(received.add);

      logger.info('before dispose');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));

      await logger.dispose();
      expect(logger.isDisposed, isTrue);

      // Any further logging should be ignored.
      logger.info('after dispose');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));

      await subscription.cancel();
    });
  });
}
