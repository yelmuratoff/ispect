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
      if (codeUnit == _singleQuote ||
          codeUnit == _doubleQuote ||
          codeUnit == _backtick) {
        index = _skipQuotedValue(statement, index + 1, codeUnit);
        sanitized.write('?');
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
