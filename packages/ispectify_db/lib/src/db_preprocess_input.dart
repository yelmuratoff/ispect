import 'package:ispectify_db/src/config.dart';

/// Bundles all parameters for DB meta preprocessing.
///
/// Groups the 18 named parameters of `_preprocessDb` into a single object.
class DbPreprocessInput {
  const DbPreprocessInput({
    required this.cfg,
    this.statement,
    this.args,
    this.namedArgs,
    this.table,
    this.key,
    this.value,
    this.affected,
    this.items,
    this.sizeBytes,
    this.cacheHit,
    this.meta,
    this.error,
    this.redact,
    this.redactKeys,
    this.maxValueLength,
    this.maxArgsLength,
    this.maxStatementLength,
  });

  /// Resolved DB configuration (provides defaults for redaction overrides).
  final ISpectDbConfig cfg;

  // ── Operation data ────────────────────────────────────────────────────

  final String? statement;
  final List<Object?>? args;
  final Map<String, Object?>? namedArgs;
  final String? table;
  final String? key;
  final Object? value;
  final int? affected;
  final int? items;
  final int? sizeBytes;
  final bool? cacheHit;
  final Map<String, Object?>? meta;
  final Object? error;

  // ── Redaction / truncation overrides (fall back to cfg) ───────────────

  final bool? redact;
  final List<String>? redactKeys;
  final int? maxValueLength;
  final int? maxArgsLength;
  final int? maxStatementLength;

  /// Whether redaction is enabled (override or cfg default).
  bool get shouldRedact => redact ?? cfg.redact;

  /// Sensitive keys to redact (override or cfg default).
  Iterable<String> get sensitiveKeys => redactKeys ?? cfg.redactKeys;

  /// Resolved max length for positional/named args.
  int get resolvedMaxArgsLength => maxArgsLength ?? cfg.maxArgsLength;

  /// Resolved max length for SQL statements.
  int get resolvedMaxStatementLength =>
      maxStatementLength ?? cfg.maxStatementLength;

  /// Resolved max length for values.
  int get resolvedMaxValueLength => maxValueLength ?? cfg.maxValueLength;
}
