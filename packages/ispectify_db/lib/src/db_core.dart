import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/config.dart';
import 'package:ispectify_db/src/constants.dart';

/// Internal utilities for DB logging: SQL fingerprinting,
/// value redaction/truncation, and message formatting.
///
/// Not intended for direct use — prefer the [ISpectLoggerDb] extension methods
/// ([db], [dbTrace], [dbStart]/[dbEnd], [dbTransaction]).
final class ISpectDbCore {
  const ISpectDbCore._();

  /// Current configuration applied to all DB log calls.
  static ISpectDbConfig config = const ISpectDbConfig();

  static final RegExp _singleQuoteRe = RegExp("'[^']*'");
  static final RegExp _doubleQuoteRe = RegExp(r'\"[^\"]*\"');
  static final RegExp _digitRe = RegExp(r'\b\d+\b');
  static final RegExp _whitespaceRe = RegExp(r'\s+');

  /// Maximum length of the normalized SQL prefix in [sqlDigest] output.
  static const _maxDigestPrefixLen = 80;

  /// DJB2 hash initial seed.
  static const _djb2Seed = 5381;

  /// Bitmask for DJB2 hash to keep it within 32-bit range.
  static const _hashMask = 0xffffffff;

  /// Bitmask to ensure positive hash value.
  static const _positiveHashMask = 0x7fffffff;

  /// Whether the given [localSample] (or global config) passes sampling.
  static bool shouldLog(double? localSample) =>
      samplePass(localSample ?? config.sampleRate);

  /// Generates a 16-character hex trace ID.
  ///
  /// Delegates to [generateTraceId] from `ispectify`.
  static String genId() => generateTraceId();

  /// Normalizes a SQL [statement] by replacing literals and digits with `?`,
  /// then appends a DJB2 hash for grouping structurally identical queries.
  ///
  /// Returns `null` when [statement] is `null` or empty.
  static String? sqlDigest(String? statement) {
    if (statement == null || statement.isEmpty) return null;
    var s = statement.toLowerCase();
    s = s.replaceAll(_singleQuoteRe, '?');
    s = s.replaceAll(_doubleQuoteRe, '?');
    s = s.replaceAll(_digitRe, '?');
    s = s.replaceAll(_whitespaceRe, ' ').trim();

    var hash = _djb2Seed;
    for (var i = 0; i < s.length; i++) {
      hash = (((hash << 5) + hash) ^ s.codeUnitAt(i)) & _hashMask;
    }
    final hex = (hash & _positiveHashMask).toRadixString(16);
    final prefixEnd =
        s.length > _maxDigestPrefixLen ? _maxDigestPrefixLen : s.length;
    return '${s.substring(0, prefixEnd)}|$hex';
  }

  /// Truncates [value] to [maxLen] characters if it is a [String].
  /// Non-string values are returned as-is.
  static Object? truncateValue(Object? value, int maxLen) {
    if (value == null) return null;
    if (value is String) return truncateString(value, maxLength: maxLen);
    return value;
  }

  /// Redacts values in [data] whose keys match any of the provided [keys].
  ///
  /// Delegates to [RedactionService.redactByKeys] — the shared implementation
  /// in the `ispectify` package.
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

  /// Redacts positional arguments in a [List] when the SQL [statement]
  /// references columns that match any of the [keys].
  ///
  /// Because positional parameters (`?`) cannot be reliably mapped to specific
  /// column names in all SQL dialects, this method redacts **all** list values
  /// when the statement mentions at least one sensitive column name.
  /// If [statement] is `null`, all values are redacted as a precaution.
  static List<Object?> redactPositionalArgs(
    List<Object?> args,
    Iterable<String> keys,
    String? statement,
  ) {
    if (args.isEmpty) return args;
    final stmtLower = statement?.toLowerCase();
    final sensitive = stmtLower == null ||
        keys.any((k) => stmtLower.contains(k.toLowerCase()));
    if (!sensitive) return args;
    return args.map((e) => e == null ? null : redactedMask).toList();
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

  /// Builds a human-readable log message from the provided fields.
  static String buildMessage({
    required String source,
    required String operation,
    String? table,
    String? target,
    String? key,
    int? items,
    int? affected,
    int? sizeBytes,
    bool? cacheHit,
    Duration? duration,
    bool? success,
    Object? value,
  }) {
    final buffer = StringBuffer('[$source] $operation');

    if (table != null && target != null) {
      buffer.write(' $table → $target');
    } else if (table != null) {
      buffer.write(' $table');
    } else if (target != null) {
      buffer.write(' $target');
    }

    final details = <String>[];
    if (key != null) details.add('${DbMessageLabels.keyPrefix}$key');
    if (value != null) details.add('${DbMessageLabels.valuePrefix}$value');
    if (items != null) details.add('${DbMessageLabels.itemsPrefix}$items');
    if (affected != null) {
      details.add('${DbMessageLabels.affectedPrefix}$affected');
    }
    if (sizeBytes != null) {
      details.add(
        '${DbMessageLabels.sizePrefix}${formatBytes(sizeBytes)}',
      );
    }
    if (cacheHit != null) {
      details.add(
        cacheHit ? DbMessageLabels.cacheHit : DbMessageLabels.cacheMiss,
      );
    }
    if (duration != null) {
      details.add(
        '${DbMessageLabels.durationPrefix}'
        '${duration.inMilliseconds}'
        '${DbMessageLabels.durationSuffix}',
      );
    }
    if (success != null) {
      details.add('${DbMessageLabels.successPrefix}$success');
    }

    if (details.isNotEmpty) {
      buffer.write('\n${details.join('\n')}');
    }

    return buffer.toString();
  }
}
