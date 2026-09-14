import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

final _productionProvider = Provider<int>(
  (ref) => 1,
  name: 'production-safety',
);

void main() {
  test(
    'debug override cannot bypass the omitted compile-time flag',
    () {
      expect(kISpectEnabled, isFalse);

      final logger = FakeISpectLogger();
      final container = ProviderContainer();
      var callbackInvoked = false;
      ISpectRiverpodObserver.debugEnabledOverride = true;
      addTearDown(() {
        ISpectRiverpodObserver.debugEnabledOverride = null;
      });
      addTearDown(container.dispose);

      ISpectRiverpodObserver(
        logger: logger,
        onProviderAdd: (_, __, ___) => callbackInvoked = true,
      ).didAddProvider(_productionProvider, 1, container);

      expect(callbackInvoked, isFalse);
      expect(logger.traces, isEmpty);
    },
    skip: kISpectEnabled,
  );
}
