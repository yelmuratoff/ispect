import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  test('formatted history honors a local resource policy', () {
    final limits = DiagnosticResourceLimits.balanced.copyWith(
      maxCapturedValueBytes: 64 * 1024,
      maxUiDiagnosticBytes: 32 * 1024,
    );
    final payload = '${'x' * 12000}TAIL';
    final log = ISpectLogData(
      'message',
      additionalData: {'payload': payload},
      resourceLimits: limits,
    );

    final output = [log].formattedTextWith(resourceLimits: limits);

    expect(output, contains('TAIL'));
  });

  test('formatted history bounds the final document', () {
    const limits = DiagnosticResourceLimits(
      maxCapturedValueBytes: 32,
      maxLogRecordBytes: 64,
      maxExportDocumentBytes: 128,
      maxUiDiagnosticBytes: 32,
    );
    final logs = List.generate(
      10,
      (index) =>
          ISpectLogData('message-$index-${'x' * 100}', resourceLimits: limits),
    );

    final output = logs.formattedTextWith(resourceLimits: limits);

    expect(
      LogExportOutput.utf8Length(output),
      lessThanOrEqualTo(limits.maxExportDocumentBytes),
    );
    expect(output, endsWith(LogExportOutput.truncatedMarker));
  });
}
