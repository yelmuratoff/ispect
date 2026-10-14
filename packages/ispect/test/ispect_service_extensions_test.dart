import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  group('ISpect VM service extensions', () {
    tearDown(ISpect.dispose);

    test('initialize registers the ext.ispect extensions', () async {
      await ISpect.dispose();

      final initialized = ISpect.initialize(
        ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false)),
      );

      expect(initialized, isTrue);
      expect(
        () => registerExtension(
          ISpectServiceExtensions.getSummary,
          (_, __) async => ServiceExtensionResponse.result('{}'),
        ),
        throwsArgumentError,
      );
    }, skip: !kISpectEnabled);
  });
}
