import 'package:ispectify/ispectify.dart';

/// Sentinel value indicating a [copyWith] parameter was not provided.
const _absent = _Absent();

class _Absent {
  const _Absent();
}

/// Global configuration for database logging.
///
/// Extends [ISpectTraceConfig] to share sampling, redaction, and slow-threshold
/// settings with the core trace pipeline.
///
/// **v5.0 breaking change:** `slowQueryThreshold` renamed to `slowThreshold`
/// (inherited from [ISpectTraceConfig]).
class ISpectDbConfig extends ISpectTraceConfig {
  const ISpectDbConfig({
    super.sampleRate,
    super.errorSampleRate,
    super.redact,
    super.redactKeys,
    super.maxValueLength,
    super.attachStackOnError,
    super.slowThreshold,
    super.resourceLimits,
    this.maxStatementLength = 2000,
    this.maxArgsLength = 500,
    this.enableTransactionMarkers = false,
    this.captureMode = DiagnosticCaptureMode.balanced,
  }) : assert(
          sampleRate == null || (sampleRate >= 0 && sampleRate <= 1),
          'sampleRate must be between 0.0 and 1.0 (inclusive)',
        );

  final int maxStatementLength;
  final int maxArgsLength;
  final bool enableTransactionMarkers;

  /// Controls whether guarded application formatters may run during capture.
  final DiagnosticCaptureMode captureMode;

  @override
  String toString() => 'ISpectDbConfig('
      'sampleRate: $sampleRate, '
      'redact: $redact, '
      'redactKeys: $redactKeys, '
      'maxValueLength: $maxValueLength, '
      'maxArgsLength: $maxArgsLength, '
      'maxStatementLength: $maxStatementLength, '
      'attachStackOnError: $attachStackOnError, '
      'captureMode: $captureMode, '
      'enableTransactionMarkers: $enableTransactionMarkers, '
      'slowThreshold: $slowThreshold)';

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields ([sampleRate], [slowThreshold]) can be explicitly
  /// reset to `null` by passing `null`. Omitting them preserves the current
  /// value. Set [inheritResourceLimits] to `true` to clear a local resource
  /// override and resume inheriting the logger policy.
  @override
  ISpectDbConfig copyWith({
    Object? sampleRate = _absent,
    double? errorSampleRate,
    bool? redact,
    Set<String>? redactKeys,
    int? maxValueLength,
    bool? attachStackOnError,
    Object? slowThreshold = _absent,
    DiagnosticResourceLimits? resourceLimits,
    bool inheritResourceLimits = false,
    int? maxStatementLength,
    int? maxArgsLength,
    bool? enableTransactionMarkers,
    DiagnosticCaptureMode? captureMode,
  }) =>
      ISpectDbConfig(
        sampleRate:
            sampleRate == _absent ? this.sampleRate : sampleRate as double?,
        errorSampleRate: errorSampleRate ?? this.errorSampleRate,
        redact: redact ?? this.redact,
        redactKeys: redactKeys ?? this.redactKeys,
        maxValueLength: maxValueLength ?? this.maxValueLength,
        attachStackOnError: attachStackOnError ?? this.attachStackOnError,
        slowThreshold: slowThreshold == _absent
            ? this.slowThreshold
            : slowThreshold as Duration?,
        resourceLimits: inheritResourceLimits
            ? null
            : resourceLimits ?? this.resourceLimits,
        maxStatementLength: maxStatementLength ?? this.maxStatementLength,
        maxArgsLength: maxArgsLength ?? this.maxArgsLength,
        enableTransactionMarkers:
            enableTransactionMarkers ?? this.enableTransactionMarkers,
        captureMode: captureMode ?? this.captureMode,
      );
}
