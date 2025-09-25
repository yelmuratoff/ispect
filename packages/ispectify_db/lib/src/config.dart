class ISpectDbConfig {
  const ISpectDbConfig({
    this.sampleRate,
    this.redact = true,
    this.redactKeys = const ['password', 'token', 'secret', 'apiKey'],
    this.maxValueLength = 500,
    this.maxArgsLength = 500,
    this.maxStatementLength = 2000,
    this.attachStackOnError = false,
    this.enableTransactionMarkers = false,
    this.slowQueryThreshold,
  });

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
