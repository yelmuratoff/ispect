import 'package:ispectify/ispectify.dart' show defaultSensitiveKeys;

/// Sentinel value indicating a [copyWith] parameter was not provided.
const _absent = _Absent();

class _Absent {
  const _Absent();
}

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

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields ([sampleRate], [slowQueryThreshold]) can be explicitly
  /// reset to `null` by passing `null`. Omitting them preserves the current
  /// value.
  ISpectDbConfig copyWith({
    Object? sampleRate = _absent,
    bool? redact,
    List<String>? redactKeys,
    int? maxValueLength,
    int? maxArgsLength,
    int? maxStatementLength,
    bool? attachStackOnError,
    bool? enableTransactionMarkers,
    Object? slowQueryThreshold = _absent,
  }) =>
      ISpectDbConfig(
        sampleRate: sampleRate == _absent
            ? this.sampleRate
            : sampleRate as double?,
        redact: redact ?? this.redact,
        redactKeys: redactKeys ?? this.redactKeys,
        maxValueLength: maxValueLength ?? this.maxValueLength,
        maxArgsLength: maxArgsLength ?? this.maxArgsLength,
        maxStatementLength: maxStatementLength ?? this.maxStatementLength,
        attachStackOnError: attachStackOnError ?? this.attachStackOnError,
        enableTransactionMarkers:
            enableTransactionMarkers ?? this.enableTransactionMarkers,
        slowQueryThreshold: slowQueryThreshold == _absent
            ? this.slowQueryThreshold
            : slowQueryThreshold as Duration?,
      );
}
