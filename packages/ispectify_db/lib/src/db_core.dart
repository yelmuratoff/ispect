import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/constants.dart';

/// Internal utilities for DB logging: redaction, truncation, and classification.
///
/// Not intended for direct use — prefer the [ISpectLoggerDb] extension methods
/// ([db], [dbTrace], [dbStart]/[dbEnd], [dbTransaction]).
///
/// For SQL fingerprinting see [DbSqlDigest].
/// For human-readable message building see [DbMessageFormatter].
final class ISpectDbCore {
  const ISpectDbCore._();

  /// Whether the given [localSample] (or [config] sample rate) passes sampling.
  static bool shouldLog(double? localSample, ISpectDbConfig config) =>
      samplePass(localSample ?? config.sampleRate);

  /// Generates a 16-character hex trace ID.
  ///
  /// Delegates to [generateTraceId] from `ispectify`.
  static String genId() => generateTraceId();

  /// Truncates [value] to [maxLen] characters if it is a [String].
  /// Non-string values are returned as-is.
  static Object? truncateValue(Object? value, int maxLen) {
    if (value == null) return null;
    if (value is String) return truncateString(value, maxLength: maxLen);
    return value;
  }

  /// Redacts values in [data] whose keys match any of the provided [keys].
  ///
  /// Delegates to [RedactionService.redactByKeys].
  static Object? redact(Object? data, Iterable<String> keys) =>
      RedactionService.redactByKeys(data, keys);

  /// Conditionally redacts [data] if [shouldRedact] is `true`, otherwise
  /// returns [data] unchanged. Returns `null` when [data] is `null`.
  static Object? redactIfNeeded(
    Object? data, {
    required bool shouldRedact,
    required Iterable<String> keys,
  }) {
    if (data == null) return null;
    return shouldRedact ? redact(data, keys) : data;
  }

  /// Redacts every positional argument in [args].
  ///
  /// Positional parameters cannot be reliably mapped to columns across SQL
  /// dialects, so selective redaction is unsafe. [keys] and [statement] remain
  /// accepted for source compatibility but do not narrow masking.
  static List<Object?> redactPositionalArgs(
    List<Object?> args,
    Iterable<String> keys,
    String? statement,
  ) {
    if (args.isEmpty) return args;
    return args.map((e) => e == null ? null : defaultPlaceholder).toList();
  }

  /// Removes entries with `null` values or empty-string values.
  ///
  /// Delegates to [cleanMap] from `ispectify`.
  static Map<String, Object?> clean(Map<String, Object?> m) => cleanMap(m);

  /// Returns the log key based on [operation] type: [DbLogCategory.error],
  /// [DbLogCategory.query], or [DbLogCategory.result].
  static String pickLogKey({
    required bool isError,
    required String operation,
  }) {
    if (isError) return DbLogCategory.error;
    if (dbReadOperations.contains(operation.toLowerCase())) {
      return DbLogCategory.query;
    }
    return DbLogCategory.result;
  }
}
