import 'package:ispectify/ispectify.dart' show kDefaultSensitiveKeys;

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
  })  : redactKeys = redactKeys ?? kDefaultSensitiveKeys.toList(),
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
  }) {
    return ISpectDbConfig(
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
}
