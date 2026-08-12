import 'package:ispectify/ispectify.dart';

/// Utilities for normalizing and fingerprinting SQL statements.
///
/// Used to group structurally identical queries regardless of literal values.
final class DbSqlDigest {
  const DbSqlDigest._();

  static final RegExp _dollarQuoteStart = RegExp(
    r'\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$',
  );
  static final RegExp _digitRe = RegExp(r'\b\d+\b');
  static final RegExp _whitespaceRe = RegExp(r'\s+');

  /// DJB2 hash initial seed.
  static const _djb2Seed = 5381;

  /// Bitmask for DJB2 hash to keep it within 32-bit range.
  static const _hashMask = 0xffffffff;

  /// Bitmask to ensure positive hash value.
  static const _positiveHashMask = 0x7fffffff;

  /// Normalizes a SQL [statement] by replacing string literals and digits with
  /// `?`, then returns an opaque fingerprint for grouping structurally
  /// identical queries.
  ///
  /// Quoted identifiers survive normalization, so statements against different
  /// tables no longer collapse onto one fingerprint.
  ///
  /// The normalized SQL is deliberately not included in the result. SQL
  /// dialects permit unquoted secrets such as encryption keys, and a readable
  /// prefix could expose those values even after ordinary literal handling.
  ///
  /// Returns `null` when [statement] is `null` or empty.
  static String? compute(
    String? statement, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    if (statement == null || statement.isEmpty) return null;
    final prepared = LogExportOutput.utf8Length(
              statement,
              limit: resourceLimits.maxDatabaseDiagnosticsBytes,
            ) >
            resourceLimits.maxDatabaseDiagnosticsBytes
        ? LogExportOutput.truncatedMarker
        : statement;
    var s = _stripCommentsAndLiterals(prepared).toLowerCase();
    s = s.replaceAll(_digitRe, '?');
    s = s.replaceAll(_whitespaceRe, ' ').trim();

    var hash = _djb2Seed;
    for (var i = 0; i < s.length; i++) {
      hash = (((hash << 5) + hash) ^ s.codeUnitAt(i)) & _hashMask;
    }
    final hex = (hash & _positiveHashMask).toRadixString(16);
    return 'sql:$hex';
  }

  /// Returns [statement] with comments, string literals, and digit runs
  /// replaced by `?`.
  ///
  /// Identifiers quoted with `"` or `` ` `` are preserved so the statement
  /// still names its tables and columns; a quoted span that does not read as
  /// a plain identifier is masked like any other literal.
  ///
  /// Bare-word operands survive normalization, so callers must pass the result
  /// through `RedactionService` before it leaves the process — that pass is
  /// what masks an unquoted credential such as SQLCipher's `PRAGMA key = x`.
  ///
  /// Returns `null` when [statement] is `null`, empty, normalizes to nothing,
  /// already carries [LogExportOutput.truncatedMarker], or exceeds
  /// [DiagnosticResourceLimits.maxDatabaseDiagnosticsBytes]. Callers fall back
  /// to [compute] so an oversized statement never reaches a log.
  static String? normalize(
    String? statement, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    if (statement == null || statement.isEmpty) return null;
    if (LogExportOutput.utf8Length(
          statement,
          limit: resourceLimits.maxDatabaseDiagnosticsBytes,
        ) >
        resourceLimits.maxDatabaseDiagnosticsBytes) {
      return null;
    }
    final normalized = _stripCommentsAndLiterals(statement)
        .replaceAll(_digitRe, '?')
        .replaceAll(_whitespaceRe, ' ')
        .trim();
    if (normalized.isEmpty ||
        normalized.contains(LogExportOutput.truncatedMarker)) {
      return null;
    }
    return normalized;
  }

  /// Returns the primary table [statement] operates on, or `null`.
  ///
  /// Comments and literals are stripped first, so a quoted value cannot pose
  /// as a table; a quoted identifier is read without its delimiters. Returns
  /// `null` when no table is present, when the name
  /// exceeds 128 characters, and when [statement] exceeds
  /// [DiagnosticResourceLimits.maxDatabaseDiagnosticsBytes].
  static String? tableOf(
    String? statement, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    if (statement == null || statement.isEmpty) return null;
    if (LogExportOutput.utf8Length(
          statement,
          limit: resourceLimits.maxDatabaseDiagnosticsBytes,
        ) >
        resourceLimits.maxDatabaseDiagnosticsBytes) {
      return null;
    }
    final normalized = _stripCommentsAndLiterals(statement)
        .replaceAll(_whitespaceRe, ' ')
        .trim();
    final match = _tableRe.firstMatch(normalized);
    final table = match?.group(2);
    if (table == null || table.isEmpty) return null;
    return table.length > _maxTableNameLength ? null : table;
  }

  static const int _maxTableNameLength = 128;
  static const int _maxIdentifierLength = 64;

  static final RegExp _identifierRe = RegExp(r'^[A-Za-z_][A-Za-z0-9_$]*$');

  static final RegExp _tableRe = RegExp(
    r'\b(from|into|update|table|join)\s+["`]?([A-Za-z_][A-Za-z0-9_$.]*)',
    caseSensitive: false,
  );

  static String _stripCommentsAndLiterals(String statement) {
    final sanitized = StringBuffer();
    var index = 0;

    while (index < statement.length) {
      if (_startsWith(statement, index, '--')) {
        index = _skipLineComment(statement, index + 2);
        sanitized.write(' ');
        continue;
      }
      if (statement.codeUnitAt(index) == _hash) {
        index = _skipLineComment(statement, index + 1);
        sanitized.write(' ');
        continue;
      }
      if (_startsWith(statement, index, '/*')) {
        index = _skipBlockComment(statement, index + 2);
        sanitized.write(' ');
        continue;
      }

      final codeUnit = statement.codeUnitAt(index);
      if (codeUnit == _singleQuote) {
        index = _skipQuotedValue(statement, index + 1, codeUnit);
        sanitized.write('?');
        continue;
      }
      if (codeUnit == _doubleQuote || codeUnit == _backtick) {
        final end = _skipQuotedValue(statement, index + 1, codeUnit);
        sanitized.write(
          _quotedIdentifierOrMask(statement, index, end, codeUnit),
        );
        index = end;
        continue;
      }

      final dollarStart = _dollarQuoteStart.matchAsPrefix(statement, index);
      if (dollarStart != null) {
        final delimiter = dollarStart.group(0)!;
        final closingIndex = statement.indexOf(delimiter, dollarStart.end);
        index = closingIndex < 0
            ? statement.length
            : closingIndex + delimiter.length;
        sanitized.write('?');
        continue;
      }

      sanitized.writeCharCode(codeUnit);
      index++;
    }

    return sanitized.toString();
  }

  // These delimiters quote identifiers, not values, in SQLite/Postgres/MySQL.
  static String _quotedIdentifierOrMask(
    String statement,
    int start,
    int end,
    int delimiter,
  ) {
    final terminated =
        end - 1 > start && statement.codeUnitAt(end - 1) == delimiter;
    if (!terminated) return '?';
    final inner = statement.substring(start + 1, end - 1);
    if (inner.length > _maxIdentifierLength || !_identifierRe.hasMatch(inner)) {
      return '?';
    }
    return statement.substring(start, end);
  }

  static int _skipLineComment(String statement, int startIndex) {
    var cursor = startIndex;
    while (cursor < statement.length) {
      final codeUnit = statement.codeUnitAt(cursor);
      cursor++;
      if (codeUnit == _lineFeed || codeUnit == _carriageReturn) break;
    }
    return cursor;
  }

  static int _skipBlockComment(String statement, int startIndex) {
    var cursor = startIndex;
    var depth = 1;
    while (cursor < statement.length && depth > 0) {
      if (_startsWith(statement, cursor, '/*')) {
        depth++;
        cursor += 2;
      } else if (_startsWith(statement, cursor, '*/')) {
        depth--;
        cursor += 2;
      } else {
        cursor++;
      }
    }
    return cursor;
  }

  static int _skipQuotedValue(
    String statement,
    int startIndex,
    int delimiter,
  ) {
    var cursor = startIndex;
    while (cursor < statement.length) {
      final codeUnit = statement.codeUnitAt(cursor);
      if (codeUnit == _backslash) {
        cursor += cursor + 1 < statement.length ? 2 : 1;
        continue;
      }
      if (codeUnit == delimiter) {
        if (cursor + 1 < statement.length &&
            statement.codeUnitAt(cursor + 1) == delimiter) {
          cursor += 2;
          continue;
        }
        return cursor + 1;
      }
      cursor++;
    }
    return cursor;
  }

  static bool _startsWith(String value, int index, String pattern) =>
      index + pattern.length <= value.length &&
      value.startsWith(pattern, index);

  static const _singleQuote = 0x27;
  static const _doubleQuote = 0x22;
  static const _backtick = 0x60;
  static const _backslash = 0x5c;
  static const _hash = 0x23;
  static const _lineFeed = 0x0a;
  static const _carriageReturn = 0x0d;
}
