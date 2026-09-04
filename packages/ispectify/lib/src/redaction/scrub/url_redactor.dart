import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/redaction/constants/detection_patterns.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart' as ph;
import 'package:ispectify/src/redaction/scrub/assignment_tokenizer.dart';
import 'package:ispectify/src/redaction/scrub/code_units.dart';
import 'package:ispectify/src/redaction/scrub/export_string_scrubber.dart';
import 'package:ispectify/src/redaction/scrub/url_component_codec.dart';

/// Redacts credentials and sensitive parameters in URLs, including nested
/// percent-encoded URLs and parameter lists inside values and fragments.
///
/// The callbacks read the owning service's current policy on every call, so
/// runtime changes to ignored keys or the placeholder apply immediately.
final class UrlRedactor {
  const UrlRedactor({
    required String Function() placeholder,
    required ExportKeyPatterns? Function() exportKeyPatterns,
    required bool Function(String key) Function() keyMatcher,
    required Object? Function(String value, String keyName) redactValue,
  })  : _placeholder = placeholder,
        _exportKeyPatterns = exportKeyPatterns,
        _keyMatcher = keyMatcher,
        _redactValue = redactValue;

  final String Function() _placeholder;
  final ExportKeyPatterns? Function() _exportKeyPatterns;
  final bool Function(String key) Function() _keyMatcher;
  final Object? Function(String value, String keyName) _redactValue;

  /// Redacts query-parameter values and userInfo credentials in a URL string.
  ///
  /// Returns the original [url] unchanged when there is nothing to redact
  /// (no query parameters and no userInfo). When the URL cannot be parsed,
  /// falls back to regex-based sanitization of credentials and sensitive
  /// query parameters rather than returning it verbatim.
  String redactUrl(String url) => _redactUrl(
        url,
        remainingOperations: _maxNestedUrlOperations,
        maxOutputLength: _redactedUrlOutputLimit(url.length),
      );

  String _redactUrl(
    String url, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      // Malformed URL — Uri APIs are unavailable. Best-effort regex sanitize
      // so credentials and sensitive query params don't survive verbatim.
      final queryRedacted = AssignmentTokenizer.maskQueryParameters(
        url,
        _keyMatcher(),
        _placeholder(),
      );
      final redacted = _maskAssignments(
        ExportStringScrubber.scrub(
          queryRedacted,
          _exportKeyPatterns(),
          mask: _placeholder(),
        ),
      );
      return redacted.length <= maxOutputLength ? redacted : _placeholder();
    }

    final hasQuery = uri.hasQuery;
    final hasUserInfo = uri.userInfo.isNotEmpty;
    final redactedQuery = hasQuery
        ? _redactQuery(
            uri.query,
            remainingOperations: remainingOperations,
            maxOutputLength: maxOutputLength,
          )
        : null;
    final queryChanged = redactedQuery != null && redactedQuery != uri.query;
    final redactedFragment = uri.fragment.isNotEmpty
        ? _redactFragment(
            uri.fragment,
            remainingOperations: remainingOperations,
            maxOutputLength: maxOutputLength,
          )
        : null;
    final fragmentChanged =
        redactedFragment != null && redactedFragment != uri.fragment;
    final redactedPath = uri.path.isEmpty ? null : _redactPathTokens(uri.path);
    final pathChanged = redactedPath != null && redactedPath != uri.path;
    if (!queryChanged && !hasUserInfo && !fragmentChanged && !pathChanged) {
      return url;
    }

    final redacted = uri
        .replace(
          userInfo: hasUserInfo ? ph.userInfoRedactedPlaceholder : null,
          path: pathChanged ? redactedPath : null,
          query: queryChanged ? redactedQuery : null,
          fragment: fragmentChanged ? redactedFragment : null,
        )
        .toString();
    return redacted.length <= maxOutputLength ? redacted : _placeholder();
  }

  String _redactPathTokens(String path) =>
      ExportStringScrubber.maskEmbeddedTokens(path, _placeholder());

  String _redactQuery(
    String query, {
    required int remainingOperations,
    required int maxOutputLength,
  }) =>
      UrlComponentCodec.mapParameterSegments(query, (pair) {
        final separator = pair.indexOf('=');
        if (separator < 0) return pair;

        final encodedKey = pair.substring(0, separator);
        final encodedValue = pair.substring(separator + 1);
        final decodedKey = UrlComponentCodec.decodeKey(encodedKey);
        if (decodedKey == null) {
          return '$encodedKey=${Uri.encodeQueryComponent(_placeholder())}';
        }

        final redacted = _redactUrlComponentValue(
          encodedValue,
          keyName: decodedKey,
          remainingOperations: remainingOperations,
          maxOutputLength: maxOutputLength,
        );
        if (redacted == encodedValue) return pair;
        return '$encodedKey=${Uri.encodeQueryComponent(redacted)}';
      });

  /// Redacts sensitive values in a URL fragment that carries `key=value` pairs
  /// (e.g. the OAuth implicit-grant `#access_token=…&id_token=…` redirect).
  ///
  /// Returns [fragment] unchanged when it is not a `key=value` list.
  String _redactFragment(
    String fragment, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final direct = _redactDecodedFragment(
      fragment,
      remainingOperations: remainingOperations,
      maxOutputLength: maxOutputLength,
    );
    if (direct != fragment) return direct;

    var decoded = fragment;
    var operationsLeft = remainingOperations;
    for (var depth = 0; depth < _maxNestedUrlDecodePasses; depth++) {
      final candidate = UrlComponentCodec.tryDecode(decoded);
      if (candidate == null) return _placeholder();
      if (candidate == decoded) return fragment;
      if (operationsLeft <= 0) return _placeholder();
      operationsLeft--;
      decoded = candidate;
      final redacted = _redactDecodedFragment(
        decoded,
        remainingOperations: operationsLeft,
        maxOutputLength: maxOutputLength,
      );
      if (redacted != decoded) return redacted;
    }

    final remaining = UrlComponentCodec.tryDecode(decoded);
    if (remaining == null || remaining != decoded) {
      return _placeholder();
    }
    return fragment;
  }

  String _redactDecodedFragment(
    String fragment, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final queryIndex = fragment.indexOf('?');
    if (queryIndex >= 0) {
      final query = fragment.substring(queryIndex + 1);
      final redactedQuery = _redactQuery(
        query,
        remainingOperations: remainingOperations,
        maxOutputLength: maxOutputLength,
      );
      return '${fragment.substring(0, queryIndex + 1)}$redactedQuery';
    }
    if (!fragment.contains('=')) return fragment;
    return UrlComponentCodec.mapParameterSegments(fragment, (pair) {
      final idx = pair.indexOf('=');
      if (idx < 0) return pair;
      final key = pair.substring(0, idx);
      final value = pair.substring(idx + 1);
      final decodedKey = UrlComponentCodec.decodeKey(key);
      if (decodedKey == null) {
        return '$key=${_placeholder()}';
      }
      final redacted = _redactUrlComponentValue(
        value,
        keyName: decodedKey,
        remainingOperations: remainingOperations,
        maxOutputLength: maxOutputLength,
      );
      return '$key=$redacted';
    });
  }

  String _redactUrlComponentValue(
    String value, {
    required String keyName,
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final redactedValue = _redactValue(value, keyName);
    final keyRedacted = switch (redactedValue) {
      null => '',
      final String text => text,
      final bool primitive => primitive.toString(),
      final num primitive when primitive is! double || primitive.isFinite =>
        primitive.toString(),
      _ => _placeholder(),
    };
    if (LogExportOutput.utf8Length(
          keyRedacted,
          limit: maxOutputLength,
        ) >
        maxOutputLength) {
      return _placeholder();
    }
    if (keyRedacted != value) return keyRedacted;

    var decoded = value;
    if (UrlComponentCodec.malformedPercentEncoding.hasMatch(decoded)) {
      return _placeholder();
    }
    var operationsLeft = remainingOperations;
    final initialUrlRedaction = _redactNestedUrlValue(
      decoded,
      remainingOperations: operationsLeft,
      maxOutputLength: maxOutputLength,
    );
    if (initialUrlRedaction != null) return initialUrlRedaction;
    final initialAssignmentRedaction = _redactNestedAssignments(decoded);
    if (initialAssignmentRedaction != null) {
      return initialAssignmentRedaction;
    }
    for (var depth = 0; depth < _maxNestedUrlDecodePasses; depth++) {
      final candidate = UrlComponentCodec.tryDecode(decoded);
      if (candidate == null) {
        return decoded == value ? _placeholder() : value;
      }
      if (candidate == decoded) return value;
      if (operationsLeft <= 0) return _placeholder();
      operationsLeft--;
      decoded = candidate;
      final nestedUrlRedaction = _redactNestedUrlValue(
        decoded,
        remainingOperations: operationsLeft,
        maxOutputLength: maxOutputLength,
      );
      if (nestedUrlRedaction != null) return nestedUrlRedaction;
      final assignmentRedaction = _redactNestedAssignments(decoded);
      if (assignmentRedaction != null) return assignmentRedaction;
    }

    final remaining = UrlComponentCodec.tryDecode(decoded);
    if (remaining == null || remaining != decoded) {
      return _placeholder();
    }
    return value;
  }

  String? _redactNestedAssignments(String value) {
    final redacted = _maskAssignments(value);
    return redacted == value ? null : redacted;
  }

  String _maskAssignments(String value) =>
      AssignmentTokenizer.maskSensitiveAssignments(
        value,
        _keyMatcher(),
        _placeholder(),
      );

  String? _redactNestedUrlValue(
    String value, {
    required int remainingOperations,
    required int maxOutputLength,
  }) {
    final uri = Uri.tryParse(value);
    final queryStart = value.indexOf('?');
    final fragmentStart = value.indexOf('#');
    final hasParameterShape =
        (queryStart >= 0 && value.substring(queryStart + 1).contains('=')) ||
            (fragmentStart >= 0 &&
                value.substring(fragmentStart + 1).contains('='));
    final isUrlShaped = _httpSchemePattern.hasMatch(value) ||
        hasParameterShape ||
        (uri != null &&
            (uri.hasQuery ||
                uri.userInfo.isNotEmpty ||
                (uri.fragment.isNotEmpty && uri.fragment.contains('='))));
    if (!isUrlShaped) return null;
    if (UrlComponentCodec.malformedPercentEncoding.hasMatch(value)) {
      return _placeholder();
    }
    if (remainingOperations <= 0) return _placeholder();

    final redacted = _redactUrl(
      value,
      remainingOperations: remainingOperations - 1,
      maxOutputLength: maxOutputLength,
    );
    return redacted == value ? null : redacted;
  }

  static const int _maxNestedUrlDecodePasses = 5;
  static const int _maxNestedUrlOperations = 16;
  static const int _maxRedactedUrlExpansionFactor = 4;
  static const int _redactedUrlExpansionSlack = 1024;

  static int _redactedUrlOutputLimit(int inputLength) =>
      inputLength * _maxRedactedUrlExpansionFactor + _redactedUrlExpansionSlack;

  static final RegExp _httpSchemePattern = RegExp(
    'https?://',
    caseSensitive: false,
  );

  /// Finds HTTP(S) URLs embedded in [text] and redacts their query parameters
  /// and userInfo credentials.
  ///
  /// Useful for sanitizing error messages that may contain full URLs with
  /// sensitive query parameters or credentials.
  String redactUrlsInText(String text) => text.replaceAllMapped(
        urlPattern,
        (match) {
          final candidate = match.group(0)!;
          final urlEnd = _embeddedUrlEnd(candidate);
          return '${redactUrl(candidate.substring(0, urlEnd))}'
              '${candidate.substring(urlEnd)}';
        },
      );

  static int _embeddedUrlEnd(String candidate) {
    var end = candidate.length;
    while (end > 0) {
      final trailing = candidate.codeUnitAt(end - 1);
      if (trailing == CodeUnits.dot ||
          trailing == CodeUnits.comma ||
          trailing == CodeUnits.semicolon ||
          trailing == CodeUnits.colon ||
          trailing == CodeUnits.exclamation) {
        end--;
        continue;
      }
      if (trailing == CodeUnits.closeParenthesis &&
          _hasUnbalancedTrailingDelimiter(
            candidate,
            end,
            CodeUnits.openParenthesis,
            CodeUnits.closeParenthesis,
          )) {
        end--;
        continue;
      }
      if (trailing == CodeUnits.closeBracket &&
          _hasUnbalancedTrailingDelimiter(
            candidate,
            end,
            CodeUnits.openBracket,
            CodeUnits.closeBracket,
          )) {
        end--;
        continue;
      }
      if (trailing == CodeUnits.closeBrace &&
          _hasUnbalancedTrailingDelimiter(
            candidate,
            end,
            CodeUnits.openBrace,
            CodeUnits.closeBrace,
          )) {
        end--;
        continue;
      }
      break;
    }
    return end;
  }

  static bool _hasUnbalancedTrailingDelimiter(
    String value,
    int end,
    int opening,
    int closing,
  ) {
    var balance = 0;
    for (var index = 0; index < end; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == opening) {
        balance++;
      } else if (codeUnit == closing) {
        balance--;
      }
    }
    return balance < 0;
  }
}
