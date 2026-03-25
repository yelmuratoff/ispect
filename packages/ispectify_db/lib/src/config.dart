import 'package:ispectify/ispectify.dart' show defaultSensitiveKeys;

/// Global configuration for database logging.
///
/// Controls redaction, truncation limits, sampling, slow-query detection,
/// and transaction marker behavior. Assign via [ISpectDbCore.config].
class ISpectDbConfig {
  ISpectDbConfig({
    this.sampleRate,
    this.redact = true,
    List<String>? redactKeys,
    this.maxValueLength = 500,
    this.maxArgsLength = 500,
    this.maxStatementLength = 2000,
    this.attachStackOnError = false,
    this.enableTransactionMarkers = false,
    this.slowQueryThreshold,
  })  : redactKeys = List.unmodifiable(redactKeys ?? defaultSensitiveKeys),
        assert(
          sampleRate == null || (sampleRate >= 0 && sampleRate <= 1),
          'sampleRate must be between 0.0 and 1.0 (inclusive)',
        );

  final double? sampleRate;
  final bool redact;
  final List<String> redactKeys;
  final int maxValueLength;
  final int maxArgsLength;
  final int maxStatementLength;
  final bool attachStackOnError;
  final bool enableTransactionMarkers;
  final Duration? slowQueryThreshold;

  @override
  String toString() => 'ISpectDbConfig('
      'sampleRate: $sampleRate, '
      'redact: $redact, '
      'redactKeys: $redactKeys, '
      'maxValueLength: $maxValueLength, '
      'maxArgsLength: $maxArgsLength, '
      'maxStatementLength: $maxStatementLength, '
      'attachStackOnError: $attachStackOnError, '
      'enableTransactionMarkers: $enableTransactionMarkers, '
      'slowQueryThreshold: $slowQueryThreshold)';

  ISpectDbConfig copyWith({
    double? sampleRate,
    bool? redact,
    List<String>? redactKeys,
    int? maxValueLength,
    int? maxArgsLength,
    int? maxStatementLength,
    bool? attachStackOnError,
    bool? enableTransactionMarkers,
    Duration? slowQueryThreshold,
  }) =>
      ISpectDbConfig(
        sampleRate: sampleRate ?? this.sampleRate,
        redact: redact ?? this.redact,
        redactKeys: redactKeys ?? this.redactKeys,
        maxValueLength: maxValueLength ?? this.maxValueLength,
        maxArgsLength: maxArgsLength ?? this.maxArgsLength,
        maxStatementLength: maxStatementLength ?? this.maxStatementLength,
        attachStackOnError: attachStackOnError ?? this.attachStackOnError,
        enableTransactionMarkers:
            enableTransactionMarkers ?? this.enableTransactionMarkers,
        slowQueryThreshold: slowQueryThreshold ?? this.slowQueryThreshold,
      );
}
