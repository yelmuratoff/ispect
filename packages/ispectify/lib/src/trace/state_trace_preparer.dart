import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/redaction/redaction_toggle.dart';

/// Bounds and redacts state-management payloads before they enter a trace.
///
/// BLoC and Riverpod observers share one policy: every caller-controlled value
/// is bounded to [DiagnosticResourceLimits.maxStateTraceBytes] under
/// [captureMode], then redacted by [redactor] when one is active. A redaction
/// failure yields [defaultPlaceholder], never the raw value.
final class StateTracePreparer {
  const StateTracePreparer({
    required this.redactor,
    required this.captureMode,
    required this.resourceLimits,
  });

  /// Active redaction service, or `null` when redaction is off.
  final RedactionService? redactor;

  final DiagnosticCaptureMode captureMode;

  final DiagnosticResourceLimits resourceLimits;

  bool get redactionActive => redactor != null;

  /// Returns a bounded, redacted snapshot of [value].
  Object? prepareValue(Object? value) {
    final active = redactionActive;
    final balanced = captureMode == DiagnosticCaptureMode.balanced;
    final prepared = LogExportOutput.boundJsonValue(
      value,
      maxBytes: resourceLimits.maxStateTraceBytes,
      resourceLimits: resourceLimits,
      preserveTypes: active,
      replaceOversizedStrings: active,
      allowCustomSerialization: balanced,
      allowCustomStringification: balanced,
    );
    if (!active) return prepared;
    try {
      final redacted = redactor!.redactForExport(
        LogExportOutput.replaceTruncatedPrefixes(
          prepared,
          resourceLimits: resourceLimits,
        ),
        resourceLimits: resourceLimits,
      );
      return LogExportOutput.boundJsonValue(
        redacted,
        maxBytes: resourceLimits.maxStateTraceBytes,
        resourceLimits: resourceLimits,
        replaceOversizedStrings: true,
      );
    } catch (_) {
      return defaultPlaceholder;
    }
  }

  /// Returns [value] as bounded text; structured values collapse to the
  /// placeholder.
  String prepareText(Object? value) => switch (prepareValue(value)) {
        final String text => text,
        final num number => number.toString(),
        final bool flag => flag.toString(),
        _ => defaultPlaceholder,
      };

  String? prepareError(Object? error) =>
      error == null ? null : prepareText(error);

  StackTrace? prepareStack(StackTrace? stackTrace) => stackTrace == null
      ? null
      : StackTrace.fromString(prepareText(stackTrace));

  /// Returns a string-keyed copy of [data]; a non-map result becomes empty.
  Map<String, Object?> prepareMeta(Map<String, dynamic> data) {
    final prepared = prepareValue(data);
    if (prepared is! Map) return <String, Object?>{};
    return <String, Object?>{
      for (final entry in prepared.entries)
        if (entry.key case final String key) key: entry.value,
    };
  }

  /// Reads the already-prepared string at [key] from [meta], or prepares
  /// [fallback] when redaction is off.
  String target(Map<String, Object?> meta, String key, String fallback) {
    final value = meta[key];
    if (value is String) return value;
    return redactionActive ? defaultPlaceholder : prepareText(fallback);
  }

  /// Bounds and redacts a caller-supplied `additionalData` map.
  ///
  /// Values stay unmasked when redaction is disabled but still cannot bypass
  /// the outbound byte and traversal limits. A failure yields an empty map.
  static Map<String, dynamic> prepareAdditionalData(
    Map<String, dynamic> data, {
    required bool enableRedaction,
    required RedactionService? redactor,
    required DiagnosticCaptureMode captureMode,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final active = enableRedaction && ISpectRedaction.enabled;
    final balanced = captureMode == DiagnosticCaptureMode.balanced;
    try {
      final prepared = LogExportOutput.boundJsonValue(
        data,
        preserveTypes: active,
        replaceOversizedStrings: active,
        allowCustomSerialization: balanced,
        allowCustomStringification: balanced,
        resourceLimits: resourceLimits,
      );
      final output = active
          ? ISpectRedaction.resolveService(service: redactor).redactForExport(
              LogExportOutput.replaceTruncatedPrefixes(
                prepared,
                resourceLimits: resourceLimits,
              ),
              resourceLimits: resourceLimits,
            )
          : prepared;
      final bounded = LogExportOutput.boundJsonValue(
        output,
        replaceOversizedStrings: active,
        resourceLimits: resourceLimits,
      );
      if (bounded is Map) {
        return <String, dynamic>{
          for (final entry in bounded.entries)
            if (entry.key case final String key) key: entry.value,
        };
      }
    } catch (_) {}
    return <String, dynamic>{};
  }
}
