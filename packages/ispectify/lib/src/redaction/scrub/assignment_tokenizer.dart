import 'dart:convert';

import 'package:ispectify/src/redaction/scrub/code_units.dart';
import 'package:ispectify/src/redaction/scrub/url_component_codec.dart';

/// Masks `key=value` / `"key": value` assignments and query parameters inside
/// free-form text without parsing it as a whole document.
abstract final class AssignmentTokenizer {
  static String maskSensitiveAssignments(
    String value,
    bool Function(String key) isSensitive,
    String placeholder,
  ) {
    final output = StringBuffer();
    var copiedThrough = 0;
    var index = 0;
    while (index < value.length) {
      final assignment = _assignmentAt(value, index);
      if (assignment == null) {
        index++;
        continue;
      }

      var valueStart = assignment.separator + 1;
      while (valueStart < value.length &&
          (assignment.quotedKey
              ? _isJsonWhitespace(value.codeUnitAt(valueStart))
              : _isInlineWhitespace(value.codeUnitAt(valueStart)))) {
        valueStart++;
      }
      final key = assignment.key;
      if (key != null && !isSensitive(key)) {
        index = assignment.keyEnd;
        continue;
      }

      final valueEnd = _assignmentValueEnd(
        value,
        valueStart,
        quotedKey: assignment.quotedKey,
      );
      final replacement =
          assignment.quotedKey ? jsonEncode(placeholder) : placeholder;
      output
        ..write(value.substring(copiedThrough, valueStart))
        ..write(replacement);
      copiedThrough = valueEnd;
      index = valueEnd > valueStart ? valueEnd : valueStart + 1;
    }
    output.write(value.substring(copiedThrough));
    return output.toString();
  }

  static ({
    String? key,
    int keyEnd,
    int separator,
    bool quotedKey,
  })? _assignmentAt(String value, int start) {
    final codeUnit = value.codeUnitAt(start);
    if (!_isAssignmentBoundary(value, start)) return null;

    if (codeUnit == CodeUnits.doubleQuote ||
        codeUnit == CodeUnits.singleQuote) {
      final keyEnd = _quotedAssignmentKeyEnd(value, start, codeUnit);
      if (keyEnd == null) return null;
      var separator = keyEnd;
      while (separator < value.length &&
          _isJsonWhitespace(value.codeUnitAt(separator))) {
        separator++;
      }
      if (separator >= value.length ||
          value.codeUnitAt(separator) != CodeUnits.colon) {
        return null;
      }

      return (
        key: _decodeQuotedAssignmentKey(value, start, keyEnd, codeUnit),
        keyEnd: keyEnd,
        separator: separator,
        quotedKey: true,
      );
    }

    if (!_isAssignmentKeyStart(codeUnit)) return null;
    var keyEnd = start + 1;
    while (keyEnd < value.length &&
        _isAssignmentKeyCharacter(value.codeUnitAt(keyEnd))) {
      keyEnd++;
    }
    var separator = keyEnd;
    while (separator < value.length &&
        _isInlineWhitespace(value.codeUnitAt(separator))) {
      separator++;
    }
    if (separator >= value.length ||
        (value.codeUnitAt(separator) != CodeUnits.equals &&
            value.codeUnitAt(separator) != CodeUnits.colon)) {
      return null;
    }
    final encodedKey = value.substring(start, keyEnd);
    return (
      key: UrlComponentCodec.decodeKey(encodedKey),
      keyEnd: keyEnd,
      separator: separator,
      quotedKey: false,
    );
  }

  static bool _isAssignmentBoundary(String value, int start) {
    if (start == 0) return true;
    final previous = value.codeUnitAt(start - 1);
    return _isJsonWhitespace(previous) ||
        previous == CodeUnits.questionMark ||
        previous == CodeUnits.ampersand ||
        previous == CodeUnits.comma ||
        previous == CodeUnits.semicolon ||
        previous == CodeUnits.openParenthesis ||
        previous == CodeUnits.openBracket ||
        previous == CodeUnits.openBrace;
  }

  static int? _quotedAssignmentKeyEnd(
    String value,
    int start,
    int quote,
  ) {
    var escaped = false;
    for (var index = start + 1; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (escaped) {
        escaped = false;
        continue;
      }
      if (codeUnit == CodeUnits.backslash) {
        escaped = true;
        continue;
      }
      if (codeUnit == quote) return index + 1;
      if (codeUnit == CodeUnits.lineFeed ||
          codeUnit == CodeUnits.carriageReturn) {
        return null;
      }
    }
    return null;
  }

  static String? _decodeQuotedAssignmentKey(
    String value,
    int start,
    int end,
    int quote,
  ) {
    if (quote == CodeUnits.doubleQuote) {
      try {
        final decoded = jsonDecode(value.substring(start, end));
        return decoded is String ? decoded : null;
      } on FormatException {
        return null;
      }
    }

    final output = StringBuffer();
    for (var index = start + 1; index < end - 1; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit != CodeUnits.backslash) {
        output.writeCharCode(codeUnit);
        continue;
      }
      index++;
      if (index >= end - 1) return null;
      final escaped = value.codeUnitAt(index);
      if (escaped == CodeUnits.lowercaseU && index + 4 < end - 1) {
        final decoded = int.tryParse(
          value.substring(index + 1, index + 5),
          radix: 16,
        );
        if (decoded == null) return null;
        output.writeCharCode(decoded);
        index += 4;
      } else {
        output.writeCharCode(escaped);
      }
    }
    return output.toString();
  }

  static int _assignmentValueEnd(
    String value,
    int start, {
    required bool quotedKey,
  }) {
    if (start >= value.length) return start;
    final openingQuote = value.codeUnitAt(start);
    if (openingQuote == CodeUnits.openBrace ||
        openingQuote == CodeUnits.openBracket) {
      return _balancedJsonValueEnd(value, start);
    }
    if (openingQuote == CodeUnits.singleQuote ||
        openingQuote == CodeUnits.doubleQuote) {
      var escaped = false;
      for (var index = start + 1; index < value.length; index++) {
        final codeUnit = value.codeUnitAt(index);
        if (escaped) {
          escaped = false;
          continue;
        }
        if (codeUnit == CodeUnits.backslash) {
          escaped = true;
          continue;
        }
        if (codeUnit == openingQuote) return index + 1;
      }
      return value.length;
    }

    if (quotedKey) {
      for (var index = start; index < value.length; index++) {
        final codeUnit = value.codeUnitAt(index);
        if (codeUnit == CodeUnits.comma ||
            codeUnit == CodeUnits.closeBrace ||
            codeUnit == CodeUnits.closeBracket) {
          return index;
        }
      }
      return value.length;
    }

    for (var index = start; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (_isHardAssignmentBoundary(codeUnit)) {
        var next = index + 1;
        while (next < value.length &&
            _isInlineWhitespace(value.codeUnitAt(next))) {
          next++;
        }
        if (AssignmentTokenizer.startsAssignmentAt(value, next)) return index;
        continue;
      }
      if (!_isInlineWhitespace(codeUnit)) continue;

      var next = index;
      while (
          next < value.length && _isInlineWhitespace(value.codeUnitAt(next))) {
        next++;
      }
      if (AssignmentTokenizer.startsAssignmentAt(value, next)) return index;
    }
    return value.length;
  }

  static int _balancedJsonValueEnd(String value, int start) {
    final expectedClosings = <int>[
      if (value.codeUnitAt(start) == CodeUnits.openBrace)
        CodeUnits.closeBrace
      else
        CodeUnits.closeBracket,
    ];
    int? stringQuote;
    var escaped = false;
    for (var index = start + 1; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (stringQuote != null) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == CodeUnits.backslash) {
          escaped = true;
        } else if (codeUnit == stringQuote) {
          stringQuote = null;
        }
        continue;
      }
      if (codeUnit == CodeUnits.doubleQuote ||
          codeUnit == CodeUnits.singleQuote) {
        stringQuote = codeUnit;
        continue;
      }
      if (codeUnit == CodeUnits.openBrace) {
        expectedClosings.add(CodeUnits.closeBrace);
        continue;
      }
      if (codeUnit == CodeUnits.openBracket) {
        expectedClosings.add(CodeUnits.closeBracket);
        continue;
      }
      if (codeUnit == CodeUnits.closeBrace ||
          codeUnit == CodeUnits.closeBracket) {
        if (codeUnit != expectedClosings.last) return value.length;
        expectedClosings.removeLast();
        if (expectedClosings.isEmpty) return index + 1;
      }
    }
    return value.length;
  }

  static bool startsAssignmentAt(String value, int start) =>
      start < value.length && _assignmentAt(value, start) != null;

  static String maskQueryParameters(
    String value,
    bool Function(String key) isSensitive,
    String placeholder,
  ) =>
      value.replaceAllMapped(_queryParameterPattern, (match) {
        final separator = match.group(1)!;
        final encodedKey = match.group(2)!;
        final decodedKey = UrlComponentCodec.decodeKey(encodedKey);
        if (decodedKey == null || isSensitive(decodedKey)) {
          return '$separator$encodedKey=$placeholder';
        }
        return match.group(0)!;
      });

  static bool _isAssignmentKeyStart(int codeUnit) =>
      (codeUnit >= CodeUnits.uppercaseA && codeUnit <= CodeUnits.uppercaseZ) ||
      (codeUnit >= CodeUnits.lowercaseA && codeUnit <= CodeUnits.lowercaseZ) ||
      (codeUnit >= CodeUnits.zero && codeUnit <= CodeUnits.nine) ||
      codeUnit == CodeUnits.underscore ||
      codeUnit == CodeUnits.percent;

  static bool _isAssignmentKeyCharacter(int codeUnit) =>
      _isAssignmentKeyStart(codeUnit) ||
      (codeUnit >= CodeUnits.zero && codeUnit <= CodeUnits.nine) ||
      codeUnit == CodeUnits.underscore ||
      codeUnit == CodeUnits.dot ||
      codeUnit == CodeUnits.hyphen ||
      codeUnit == CodeUnits.percent ||
      codeUnit == CodeUnits.openBracket ||
      codeUnit == CodeUnits.closeBracket;

  static bool _isInlineWhitespace(int codeUnit) =>
      codeUnit == CodeUnits.space || codeUnit == CodeUnits.tab;

  static bool _isJsonWhitespace(int codeUnit) =>
      _isInlineWhitespace(codeUnit) ||
      codeUnit == CodeUnits.lineFeed ||
      codeUnit == CodeUnits.carriageReturn;

  static bool _isHardAssignmentBoundary(int codeUnit) =>
      codeUnit == CodeUnits.comma ||
      codeUnit == CodeUnits.semicolon ||
      codeUnit == CodeUnits.ampersand ||
      codeUnit == CodeUnits.closeParenthesis ||
      codeUnit == CodeUnits.closeBracket ||
      codeUnit == CodeUnits.closeBrace ||
      codeUnit == CodeUnits.carriageReturn ||
      codeUnit == CodeUnits.lineFeed;

  static final RegExp _queryParameterPattern = RegExp(
    r'(^|[?&#])([^?&#=\s]+)=([^?&#\s]*)',
    multiLine: true,
  );

  static bool isInlineWhitespace(int codeUnit) => _isInlineWhitespace(codeUnit);
}
