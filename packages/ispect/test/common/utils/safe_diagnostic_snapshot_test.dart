import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/utils/safe_diagnostic_snapshot.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  group('ISpectSafeDiagnosticSnapshot.text', () {
    tearDown(ISpectRedaction.reset);

    const limits = DiagnosticResourceLimits.balanced;
    final longLine = 'a' * (limits.maxUiDiagnosticBytes * 2);

    test('replaces a value larger than the UI budget while redacting', () {
      final snapshot = ISpectSafeDiagnosticSnapshot.text(longLine);

      expect(snapshot, LogExportOutput.truncatedMarker);
    });

    test('keeps a UI-bounded prefix when the snapshot budget is larger', () {
      final snapshot = ISpectSafeDiagnosticSnapshot.text(
        longLine,
        maxBytes: limits.maxCapturedValueBytes,
      );

      expect(snapshot, startsWith('a' * 64));
      expect(snapshot, endsWith(LogExportOutput.truncatedMarker));
      expect(LogExportOutput.utf8Length(snapshot), limits.maxUiDiagnosticBytes);
    });

    test('truncates instead of replacing after a global opt-out', () {
      ISpectRedaction.enabled = false;

      final snapshot = ISpectSafeDiagnosticSnapshot.text(longLine);

      expect(snapshot, startsWith('a' * 64));
      expect(snapshot, endsWith(LogExportOutput.truncatedMarker));
    });

    test('renders null as an empty string', () {
      expect(ISpectSafeDiagnosticSnapshot.text(null), isEmpty);
    });
  });

  group('ISpectSafeDiagnosticSnapshot.boundedValue', () {
    final redactor = RedactionService(
      sensitiveKeys: const {'token'},
      placeholder: '<hidden>',
    );

    test('redacts sensitive fields with the given redactor', () {
      final value = ISpectSafeDiagnosticSnapshot.boundedValue(const {
        'token': 'RAW_SECRET',
        'path': '/home',
      }, redactor: redactor);

      expect(value, {'token': '<hidden>', 'path': '/home'});
    });

    test('keeps values raw without a redactor', () {
      final value = ISpectSafeDiagnosticSnapshot.boundedValue(const {
        'token': 'RAW_SECRET',
      }, redactor: null);

      expect(value, {'token': 'RAW_SECRET'});
    });

    test('replaces an oversized string only while redacting', () {
      final oversized = 'b' * 256;

      final redacted = ISpectSafeDiagnosticSnapshot.boundedValue(
        oversized,
        redactor: redactor,
        maxBytes: 64,
      );
      final raw = ISpectSafeDiagnosticSnapshot.boundedValue(
        oversized,
        redactor: null,
        maxBytes: 64,
      );

      expect(redacted, LogExportOutput.truncatedMarker);
      expect(raw, startsWith('b' * 16));
      expect(raw, endsWith(LogExportOutput.truncatedMarker));
    });

    test('propagates a redactor failure to the caller', () {
      expect(
        () => ISpectSafeDiagnosticSnapshot.boundedValue(
          'value',
          redactor: _ThrowingRedactionService(),
        ),
        throwsStateError,
      );
    });
  });
}

final class _ThrowingRedactionService extends RedactionService {
  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) => throw StateError('redaction failed');
}
