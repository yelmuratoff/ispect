@TestOn('vm')
library;

import 'dart:isolate';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  test('deferred masking still applies after an isolate transfer', () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false, maxHistoryItems: 10),
    )..info(
        'checkout',
        additionalData: <String, dynamic>{
          'password': 'hunter2-plaintext',
          'order': 'A-1001',
        },
      );
    addTearDown(logger.dispose);

    final logs = logger.history;
    final exported = await Isolate.run(() => LogExporter.toJsonLines(logs));

    expect(exported, isNot(contains('hunter2-plaintext')));
    expect(exported, contains('A-1001'));
  });
}
