import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/default_curl_redactor.dart';
import 'package:ispect/src/common/utils/safe_diagnostic_snapshot.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  tearDown(ISpectRedaction.reset);

  test('UI helpers observe policy reconfiguration after first use', () {
    final firstService = RedactionService(
      sensitiveKeys: const {'first_field'},
      placeholder: '<first>',
    );
    final secondService = RedactionService(
      sensitiveKeys: const {'second_field'},
      placeholder: '<second>',
    );
    ISpectRedaction.configure(service: firstService);
    expect(defaultCurlRedactor, same(firstService));

    ISpectRedaction.configure(service: secondService);

    expect(defaultCurlRedactor, same(secondService));
    final snapshot = ISpectSafeDiagnosticSnapshot.text(
      const {'second_field': 'SECOND_RAW'},
    );
    expect(snapshot, contains('<second>'));
    expect(snapshot, isNot(contains('SECOND_RAW')));
  });
}
