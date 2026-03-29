import 'package:ispectify/src/redaction/constants/key_defaults.dart';
import 'package:ispectify/src/utils/common_utils.dart';
import 'package:meta/meta.dart';

/// Base configuration for trace operations.
///
/// Subclasses (e.g. `ISpectDbConfig`) must override [copyWith] to preserve
/// their additional fields.
@immutable
class ISpectTraceConfig {
  const ISpectTraceConfig({
    this.sampleRate,
    this.errorSampleRate = 1.0,
    this.redact = true,
    this.redactKeys = defaultSensitiveKeys,
    this.maxValueLength = 500,
    this.attachStackOnError = false,
    this.slowThreshold,
  });

  /// Sampling rate for successful operations.
  /// - `null` (default) → log ALL successful operations (no sampling)
  /// - `1.0` → log all (same as null)
  /// - `0.5` → log ~50%
  /// - `0.0` → log none
  final double? sampleRate;

  /// Sampling rate for error operations (default: 1.0 = log all errors).
  final double errorSampleRate;

  /// Whether to auto-redact sensitive data.
  final bool redact;

  /// Keys to redact in meta maps and URL query params.
  final Set<String> redactKeys;

  /// Maximum length for string values before truncation.
  final int maxValueLength;

  /// Whether to attach stack traces on error.
  final bool attachStackOnError;

  /// Duration threshold for "slow" operations.
  final Duration? slowThreshold;

  /// Sampling precedence: error → localSample → sampleRate → null (log all).
  bool shouldLog({required bool isError, double? localSample}) {
    final rate = isError ? errorSampleRate : (localSample ?? sampleRate);
    return rate == null || samplePass(rate);
  }

  @mustBeOverridden
  ISpectTraceConfig copyWith({
    double? sampleRate,
    double? errorSampleRate,
    bool? redact,
    Set<String>? redactKeys,
    int? maxValueLength,
    bool? attachStackOnError,
    Duration? slowThreshold,
  }) =>
      ISpectTraceConfig(
        sampleRate: sampleRate ?? this.sampleRate,
        errorSampleRate: errorSampleRate ?? this.errorSampleRate,
        redact: redact ?? this.redact,
        redactKeys: redactKeys ?? this.redactKeys,
        maxValueLength: maxValueLength ?? this.maxValueLength,
        attachStackOnError: attachStackOnError ?? this.attachStackOnError,
        slowThreshold: slowThreshold ?? this.slowThreshold,
      );
}
