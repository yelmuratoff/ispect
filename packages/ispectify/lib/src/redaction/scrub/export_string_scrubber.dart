import 'package:ispectify/src/redaction/constants/credential_markers.dart';
import 'package:ispectify/src/redaction/constants/key_defaults.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/key_canonicalizer.dart';
import 'package:ispectify/src/redaction/scrub/assignment_tokenizer.dart';
import 'package:ispectify/src/redaction/scrub/code_units.dart';
import 'package:ispectify/src/redaction/secret_metadata.dart';

/// Regex- and scan-based redaction of free-form export text: URL
/// credentials, authentication schemes, embedded tokens, filesystem paths,
/// and key-based assignments, query parameters, and JSON fields.
abstract final class ExportStringScrubber {
  /// Masks JWTs and known provider tokens embedded in [value].
  static String maskEmbeddedTokens(String value, String mask) => value
      .replaceAllMapped(_embeddedJwtPattern, (m) => '${m[1]}$mask')
      .replaceAllMapped(_embeddedKnownTokenPattern, (m) => '${m[1]}$mask');

  // Shared patterns

  static final _urlCredentialPattern =
      RegExp(r'((?::)?//)([^:/@\s]+)(?::([^/@\s]*))?@');

  static final _emailPathSegmentPattern = RegExp(
    r'''(?<![/:])/[^/\s?#"'@():;,]+(?:@|%40)[A-Za-z][A-Za-z0-9-]*'''
    r'(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}(?![A-Za-z0-9-])(?!\.[A-Za-z0-9])',
    caseSensitive: false,
  );

  static String scrub(
    String value,
    ExportKeyPatterns? patterns, {
    String mask = ph.defaultPlaceholder,
  }) {
    final scrubbed = _redactUnquotedAbsolutePaths(
      _redactQuotedAbsolutePaths(value, mask),
      mask,
    )
        .replaceAllMapped(
          _urlCredentialPattern,
          (m) => '${m[1]}${ph.userInfoRedactedPlaceholder}@',
        )
        .replaceAllMapped(
          _authorizationHeaderPattern,
          (m) => '${m[1]}${m[2]}$mask',
        )
        .replaceAllMapped(
          _embeddedJwtPattern,
          (m) => '${m[1]}$mask',
        )
        .replaceAllMapped(
          _embeddedKnownTokenPattern,
          (m) => '${m[1]}$mask',
        )
        .replaceAllMapped(
          _parameterAuthenticationPattern,
          (m) => '${m[1]} $mask',
        )
        .replaceAllMapped(
          _exportTokenPattern,
          (m) => '${m[1]} $mask',
        )
        .replaceAll(_emailPathSegmentPattern, '/$mask');

    if (patterns == null) return scrubbed;

    final assignmentRedacted = AssignmentTokenizer.maskSensitiveAssignments(
      scrubbed,
      patterns.matchesKey,
      mask,
    );
    final queryRedacted = AssignmentTokenizer.maskQueryParameters(
      assignmentRedacted,
      patterns.matchesKey,
      mask,
    );
    final redacted = queryRedacted
        .replaceAllMapped(
          patterns.jsonString,
          (m) => '"${m[1]}": "$mask"',
        )
        .replaceAllMapped(
          patterns.jsonScalar,
          (m) => '"${m[1]}": "$mask"',
        );

    return AssignmentTokenizer.maskSensitiveAssignments(
      redacted,
      patterns.matchesKey,
      mask,
    );
  }

  static bool requiresScrub(String value) {
    var mayContainTokenMarker = false;
    for (var index = 0; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit < CodeUnits.space || codeUnit > CodeUnits.tilde) return true;
      switch (codeUnit) {
        case CodeUnits.hash:
        case CodeUnits.ampersand:
        case CodeUnits.dot:
        case CodeUnits.slash:
        case CodeUnits.colon:
        case CodeUnits.equals:
        case CodeUnits.questionMark:
        case CodeUnits.backslash:
          return true;
        case CodeUnits.space:
        case CodeUnits.hyphen:
        case CodeUnits.underscore:
          mayContainTokenMarker = true;
      }
    }
    if (!mayContainTokenMarker) {
      return _containsUnseparatedTokenMarker(value);
    }
    final lower = value.toLowerCase();
    for (final marker in _exportTokenMarkers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  static bool _containsUnseparatedTokenMarker(String value) {
    for (final marker in _unseparatedTokenMarkers) {
      if (_containsIgnoringAsciiCase(value, marker)) return true;
    }
    return false;
  }

  static bool _containsIgnoringAsciiCase(String value, String lowerMarker) {
    final lastStart = value.length - lowerMarker.length;
    for (var start = 0; start <= lastStart; start++) {
      var offset = 0;
      while (offset < lowerMarker.length &&
          (value.codeUnitAt(start + offset) | 0x20) ==
              lowerMarker.codeUnitAt(offset)) {
        offset++;
      }
      if (offset == lowerMarker.length) return true;
    }
    return false;
  }

  static final List<String> _exportTokenMarkers = <String>[
    for (final scheme in httpAuthSchemes) '${scheme.toLowerCase()} ',
    scramAuthSchemePrefix.toLowerCase(),
    for (final prefix in knownTokenPrefixes) prefix.toLowerCase(),
    awsAccessKeyIdPrefix.toLowerCase(),
  ];

  static final List<String> _unseparatedTokenMarkers = _exportTokenMarkers
      .where((marker) => !marker.contains(_tokenMarkerSeparator))
      .toList(growable: false);

  static final _tokenMarkerSeparator = RegExp('[ _-]');

  static String _redactQuotedAbsolutePaths(String value, String mask) {
    final output = StringBuffer();
    var copiedThrough = 0;
    var index = 0;
    while (index < value.length) {
      final quote = value.codeUnitAt(index);
      if (quote != CodeUnits.singleQuote && quote != CodeUnits.doubleQuote) {
        index++;
        continue;
      }

      final contentStart = index + 1;
      final replacement = _quotedPathReplacement(
        value,
        contentStart,
        mask,
      );
      if (replacement == null) {
        index++;
        continue;
      }

      final contentEnd = _quotedPathEnd(value, contentStart, quote);
      output
        ..write(value.substring(copiedThrough, contentStart))
        ..write(replacement);
      copiedThrough = contentEnd;
      index = contentEnd > contentStart ? contentEnd : contentStart;
    }
    output.write(value.substring(copiedThrough));
    return output.toString();
  }

  static String? _quotedPathReplacement(
    String value,
    int start,
    String mask,
  ) {
    if (_quotedFileUriStartPattern.matchAsPrefix(value, start) != null) {
      return 'file://$mask';
    }
    if (_quotedPosixPathStartPattern.matchAsPrefix(value, start) != null ||
        _quotedWindowsPathStartPattern.matchAsPrefix(value, start) != null ||
        _quotedUncPathStartPattern.matchAsPrefix(value, start) != null) {
      return mask;
    }
    return null;
  }

  static int _quotedPathEnd(String value, int start, int quote) {
    var escaped = false;
    for (var index = start; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == CodeUnits.lineFeed ||
          codeUnit == CodeUnits.carriageReturn) {
        return index;
      }
      if (escaped) {
        escaped = false;
        continue;
      }
      if (codeUnit == CodeUnits.backslash) {
        escaped = true;
        continue;
      }
      if (codeUnit == quote) return index;
    }
    return value.length;
  }

  static String _redactUnquotedAbsolutePaths(String value, String mask) {
    final output = StringBuffer();
    var copiedThrough = 0;
    for (final match in _unquotedAbsolutePathStartPattern.allMatches(value)) {
      if (match.start < copiedThrough) continue;

      final prefix = match.group(1)!;
      final pathStart = match.start + prefix.length;
      final pathEnd = _unquotedPathEnd(value, pathStart, match.end);
      final pathPrefix = match.group(2)!;
      final replacement =
          pathPrefix.toLowerCase().startsWith('file:') ? 'file://$mask' : mask;
      output
        ..write(value.substring(copiedThrough, pathStart))
        ..write(replacement);
      copiedThrough = pathEnd;
    }
    if (copiedThrough == 0) return value;
    output.write(value.substring(copiedThrough));
    return output.toString();
  }

  static int _unquotedPathEnd(
    String value,
    int pathStart,
    int scanStart,
  ) {
    for (var index = scanStart; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == CodeUnits.lineFeed ||
          codeUnit == CodeUnits.carriageReturn ||
          codeUnit == CodeUnits.doubleQuote ||
          codeUnit == CodeUnits.singleQuote ||
          codeUnit == CodeUnits.closeParenthesis ||
          codeUnit == CodeUnits.closeBracket ||
          codeUnit == CodeUnits.closeBrace ||
          codeUnit == CodeUnits.comma ||
          codeUnit == CodeUnits.semicolon) {
        return index;
      }
      if (!AssignmentTokenizer.isInlineWhitespace(codeUnit)) continue;

      var next = index + 1;
      while (next < value.length &&
          AssignmentTokenizer.isInlineWhitespace(value.codeUnitAt(next))) {
        next++;
      }
      if (next >= value.length ||
          AssignmentTokenizer.startsAssignmentAt(value, next) ||
          _stackLocationSuffixPattern
              .hasMatch(value.substring(pathStart, index))) {
        return index;
      }
    }
    return value.length;
  }

  /// Key patterns for [keys], reusing the compiled default set when [keys] is
  /// the default sensitive-key set.
  static ExportKeyPatterns? patternsFor(Set<String>? keys) {
    if (keys == null || keys.isEmpty) return null;
    if (identical(keys, defaultSensitiveKeys) ||
        identical(keys, defaultSensitiveKeysLower)) {
      return _defaultExportKeyPatterns;
    }
    return ExportKeyPatterns(keys);
  }

  static final ExportKeyPatterns _defaultExportKeyPatterns =
      ExportKeyPatterns(defaultSensitiveKeysLower);

  static final _exportTokenPattern = RegExp(
    '\\b($httpAuthSchemeAlternation)\\s+[^\\s,;]+',
    caseSensitive: false,
  );

  static final _authorizationHeaderPattern = RegExp(
    r'\b((?:Proxy-)?Authorization)(\s*[:=]\s*)[^\r\n]*',
    caseSensitive: false,
  );

  static final _embeddedJwtPattern = RegExp(
    '(^|[^A-Za-z0-9_-])'
    r'[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    r'(?=$|[^A-Za-z0-9_-])',
  );

  static final _embeddedKnownTokenPattern = RegExp(
    '(^|[^A-Za-z0-9_-])'
    '(?:(?:$knownTokenPrefixAlternation)'
    '[A-Za-z0-9._=-]{8,}|$awsAccessKeyIdPrefix[A-Z0-9]{12,})',
  );

  static final _parameterAuthenticationPattern = RegExp(
    r'''\b(Digest|OAuth)\s+(?:[A-Za-z][A-Za-z0-9_-]*\s*=\s*(?:"(?:\\.|[^"\\])*"|"(?:\\.|[^"\\\r\n])*(?=[\r\n]|$)|'(?:\\.|[^'\\])*'|'(?:\\.|[^'\\\r\n])*(?=[\r\n]|$)|[^"'\s,]+)(?:\s*,\s*)?)+''',
    caseSensitive: false,
  );

  static final _quotedFileUriStartPattern = RegExp(
    r'''file:(?://[^/\s]*)?/''',
    caseSensitive: false,
  );

  static const _posixPathRoots = '/(?:Users/|'
      r'''home/[^/\s"']+/|'''
      'private/(?:var|tmp)/|'
      'var/(?:mobile|folders|containers|db|lib|log|root|tmp|'
      'www|run|cache|spool|backups)/|'
      'data/(?:app|data|local|media|misc|system|user|user_de)/|'
      'tmp/|storage/|sdcard/|mnt/|opt/|srv/|etc/|root/|'
      r'''app/[^/\s"']+/|'''
      'workspace/)';

  static final _quotedPosixPathStartPattern = RegExp(_posixPathRoots);

  static final _quotedWindowsPathStartPattern = RegExp(r'[A-Za-z]:[\\/]');

  static final _quotedUncPathStartPattern = RegExp(
    r'''\\\\[^\\/\s]+[\\/]''',
  );

  static final _unquotedAbsolutePathStartPattern = RegExp(
    r'(^|[\s(=\[])('
    r'''[Ff][Ii][Ll][Ee]:(?://[^/\s]*)?/|'''
    '$_posixPathRoots|'
    r'''[A-Za-z]:[\\/]|'''
    r'''\\\\[^\\/\s]+[\\/]'''
    ')',
    multiLine: true,
  );

  static final _stackLocationSuffixPattern = RegExp(r':\d+(?::\d+)?$');
}

final class ExportKeyPatterns {
  ExportKeyPatterns(Set<String> keys)
      : this._(
          keys.map((key) => key.toLowerCase()).toSet(),
          keys.map(canonicalizeKey).toSet(),
          keys.map(RegExp.escape).join('|'),
        );

  ExportKeyPatterns._(this.keysLower, this.canonicalKeysLower, String keys)
      : jsonString = RegExp(
          '"($keys)"\\s*:\\s*"(?:\\\\.|[^"\\\\])*"',
          caseSensitive: false,
        ),
        jsonScalar = RegExp(
          '"($keys)"\\s*:\\s*(-?\\d[\\d.eE+-]*|true|false|null)',
          caseSensitive: false,
        );

  final Set<String> keysLower;
  final Set<String> canonicalKeysLower;
  final RegExp jsonString;
  final RegExp jsonScalar;

  bool matchesKey(String key, String Function() assignedValue) {
    final lower = key.trim().toLowerCase();
    if (keysLower.contains(lower)) return true;
    final canonical = canonicalizeKey(key);
    if (canonicalKeysLower.contains(canonical)) return true;
    if (!_containsKeySegments(canonical)) return false;
    final qualifier = secretMetadataQualifier(canonical);
    return qualifier == null ||
        !isSecretMetadataValue(qualifier, assignedValue());
  }

  bool _containsKeySegments(String canonical) {
    final tokens =
        canonical.split('_').where((token) => token.isNotEmpty).toList();
    for (var start = 0; start < tokens.length; start++) {
      final candidate = StringBuffer();
      for (var end = start; end < tokens.length; end++) {
        if (candidate.isNotEmpty) candidate.write('_');
        candidate.write(tokens[end]);
        final value = candidate.toString();
        if (end < tokens.length - 1 &&
            trailingSegmentOnlyKeys.contains(value)) {
          continue;
        }
        if (canonicalKeysLower.contains(value)) return true;
      }
    }
    return false;
  }
}
