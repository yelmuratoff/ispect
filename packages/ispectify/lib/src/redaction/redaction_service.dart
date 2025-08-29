import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';

/// RedactionService
///
/// A single-class, configurable service to redact sensitive values in
/// headers, JSON-like maps, and lists. Designed to be fast, recursive, and
/// idempotent with sensible defaults.
///
/// Notes:
/// - Case-insensitive key matching for headers/JSON keys.
/// - Partial masking keeps useful context (e.g., "Bearer ") and first/last chars.
/// - Handles nested Map/List structures.
/// - Detects likely binary/base64 payloads and replaces with placeholders.
/// - Limits recursion depth to avoid performance issues.
class RedactionService {
  RedactionService({
    Set<String>? sensitiveKeys,
    List<RegExp>? sensitiveKeyPatterns,
    int? maxDepth,
    int? stringEdgeVisible,
    String? placeholder,
    bool? redactBinary,
    bool? redactBase64,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  })  : _sensitiveKeysLower = (sensitiveKeys ?? _kDefaultSensitiveKeys)
            .map((e) => e.toLowerCase())
            .toSet(),
        _sensitiveKeyPatterns =
            sensitiveKeyPatterns ?? _kDefaultSensitiveKeyRegexps,
        _maxDepth = maxDepth ?? 16,
        _stringEdgeVisible = stringEdgeVisible ?? 2,
        _placeholder = placeholder ?? '[REDACTED]',
        _redactBinary = redactBinary ?? true,
        _redactBase64 = redactBase64 ?? true,
        _ignoredValues = {...?ignoredValues, ...ISpectifyLogType.keys},
        _ignoredKeyNamesLower = {
          ...?(ignoredKeys?.map((e) => e.toLowerCase())),
        };

  final Set<String> _sensitiveKeysLower;
  final List<RegExp> _sensitiveKeyPatterns;
  final int _maxDepth;
  final int _stringEdgeVisible;
  final String _placeholder;
  final bool _redactBinary;
  final bool _redactBase64;
  final Set<String> _ignoredValues; // exact string matches to skip redaction
  final Set<String>
      _ignoredKeyNamesLower; // key names (lowercased) to skip sensitivity

  // --- Public API ----------------------------------------------------------

  /// Redacts a headers map (case-insensitive keys). Returns a new map; does not mutate input.
  ///
  /// - [ignoredValues] allows passing a per-call set of exact strings to skip redaction.
  /// - [ignoredKeys] allows passing a per-call set of key names (case-insensitive) to skip redaction.
  Map<String, Object?> redactHeaders(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final out = <String, Object?>{};
    final callIgnored =
        (ignoredValues == null || ignoredValues.isEmpty) ? null : ignoredValues;
    final callIgnoredKeysLower = (ignoredKeys == null || ignoredKeys.isEmpty)
        ? null
        : ignoredKeys.map((e) => e.toLowerCase()).toSet();
    headers.forEach((key, value) {
      final keyStr = key;
      out[keyStr] = _redactNode(
        value,
        keyName: keyStr,
        depth: 0,
        ignoredValues: callIgnored,
        ignoredKeysLower: callIgnoredKeysLower,
      );
    });
    return out;
  }

  /// Redacts any JSON-like data structure (Map/List/scalars).
  /// - [keyName] can be provided to control masking at the current level.
  /// - [ignoredValues] allows passing a per-call set of exact strings to skip redaction.
  /// - [ignoredKeys] allows passing a per-call set of key names (case-insensitive) to skip redaction.
  Object? redact(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _redactNode(
        data,
        keyName: keyName,
        depth: 0,
        ignoredValues: (ignoredValues == null || ignoredValues.isEmpty)
            ? null
            : ignoredValues,
        ignoredKeysLower: (ignoredKeys == null || ignoredKeys.isEmpty)
            ? null
            : ignoredKeys.map((e) => e.toLowerCase()).toSet(),
      );

  /// Add a string value to the ignore list (exact match).
  void ignoreValue(String value) {
    _ignoredValues.add(value);
  }

  /// Add multiple string values to the ignore list (exact matches).
  void ignoreValues(Iterable<String> values) {
    _ignoredValues.addAll(values);
  }

  /// Remove a string value from the ignore list.
  void unignoreValue(String value) {
    _ignoredValues.remove(value);
  }

  /// Clear all ignored string values.
  void clearIgnoredValues() {
    _ignoredValues.clear();
  }

  /// Add a key name to the ignore list (case-insensitive).
  void ignoreKey(String keyName) {
    _ignoredKeyNamesLower.add(keyName.toLowerCase());
  }

  /// Add multiple key names to the ignore list (case-insensitive).
  void ignoreKeys(Iterable<String> keyNames) {
    for (final k in keyNames) {
      _ignoredKeyNamesLower.add(k.toLowerCase());
    }
  }

  /// Remove a key name from the ignore list.
  void unignoreKey(String keyName) {
    _ignoredKeyNamesLower.remove(keyName.toLowerCase());
  }

  /// Clear all ignored key names.
  void clearIgnoredKeys() {
    _ignoredKeyNamesLower.clear();
  }

  // --- Core logic ----------------------------------------------------------

  Object? _redactNode(
    Object? node, {
    required String? keyName,
    required int depth,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeysLower,
  }) {
    if (node == null) return null;
    if (depth > _maxDepth) return node; // safety guard

    // If key is sensitive (and not in ignored keys), mask scalar values directly (idempotent check inside)
    if (_isSensitiveKey(keyName, ignoredKeysLower)) {
      if (node is String) {
        if (_isIgnoredValue(node, ignoredValues)) return node;
        return _maskString(node, keyName: keyName);
      }
      if (node is num || node is bool || node is DateTime) return _placeholder;
      if (node is Uint8List) return _binaryPlaceholder(node.length);
      // For complex types under sensitive key, replace with placeholder
      return _placeholder;
    }

    // For non-sensitive keys, handle based on type
    if (node is Map) {
      final input = node;
      final out = input.map((k, v) {
        final childKey = k.toString();
        return MapEntry(
          k,
          _redactNode(
            v,
            keyName: childKey,
            depth: depth + 1,
            ignoredValues: ignoredValues,
            ignoredKeysLower: ignoredKeysLower,
          ),
        );
      });
      return out;
    }
    if (node is List) {
      return node
          .map(
            (e) => _redactNode(
              e,
              keyName: keyName,
              depth: depth + 1,
              ignoredValues: ignoredValues,
              ignoredKeysLower: ignoredKeysLower,
            ),
          )
          .toList(growable: false);
    }

    if (node is Uint8List) {
      return _redactBinary ? _binaryPlaceholder(node.length) : node;
    }

    if (node is String) {
      if (_isIgnoredValue(node, ignoredValues)) return node;
      // If the content itself looks like a JWT, token, or base64/binary, mask partially.
      if (_looksLikeAuthorizationValue(node)) {
        return _maskString(node, keyName: keyName);
      }
      if (_redactBase64 && _isLikelyBase64(node)) {
        return _base64Placeholder(node.length);
      }
      if (_redactBinary && _isProbablyBinaryString(node)) {
        return _binaryPlaceholder(node.codeUnits.length);
      }
      return node;
    }

    // Primitive non-string types left as-is
    return node;
  }

  bool _isSensitiveKey(String? key, Set<String>? callIgnoredKeysLower) {
    if (key == null) return false;
    final k = key.toLowerCase();
    if (_isIgnoredKeyLower(k, callIgnoredKeysLower)) return false;
    if (_sensitiveKeysLower.contains(k)) return true;
    for (final r in _sensitiveKeyPatterns) {
      if (r.hasMatch(k)) return true;
    }
    return false;
  }

  // --- Masking helpers -----------------------------------------------------

  String _maskString(String value, {required String? keyName}) {
    if (value == _placeholder) return value; // idempotent

    // Keep scheme for tokens like "Bearer ", "Basic ", etc.
    final Match? m = _schemeRegex.firstMatch(value);
    if (m != null) {
      final head = m.group(0) ?? '';
      final rest = value.substring(head.length);
      return '$head${_maskEdges(rest)}';
    }

    // Cookies: mask values but keep cookie names
    if (keyName != null && keyName.toLowerCase() == 'cookie') {
      return value.split(';').map((part) {
        final p = part.trim();
        final idx = p.indexOf('=');
        if (idx <= 0) return p; // flags like HttpOnly
        final name = p.substring(0, idx);
        final val = p.substring(idx + 1);
        return '$name=${_maskEdges(val)}';
      }).join('; ');
    }

    return _maskEdges(value);
  }

  String _maskEdges(String input) {
    if (input.isEmpty) return _placeholder;
    if (input.length <= _stringEdgeVisible * 2) return _placeholder;
    final start = input.substring(0, _stringEdgeVisible);
    final end = input.substring(input.length - _stringEdgeVisible);
    // final hidden = input.length - (_stringEdgeVisible * 2);
    return '$start…$end ($_placeholder)';
  }

  // --- Detection helpers ---------------------------------------------------

  bool _looksLikeAuthorizationValue(String s) {
    // JWT: header.payload.signature (base64url parts)
    if (_jwtRegex.hasMatch(s)) {
      return true;
    }
    // Common token hints
    if (s.startsWith('Bearer ') ||
        s.startsWith('Basic ') ||
        s.startsWith('Digest ')) {
      return true;
    }
    if (_tokenPrefixRegex.hasMatch(s)) {
      return true; // GitHub/Slack tokens
    }
    return false;
  }

  bool _isLikelyBase64(String s) {
    // Quick checks to avoid expensive operations
    if (s.length < 32) return false;
    if (s.length % 4 != 0) return false;
    if (!_base64Regex.hasMatch(s)) return false;
    try {
      // Attempt to decode small sample to validate; avoid full decode for very large strings
      final sample = s.length > 256 ? s.substring(0, 256) : s;
      base64Decode(sample);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isProbablyBinaryString(String s) {
    // Heuristic: ratio of non-printable characters
    var nonPrintable = 0;
    for (final code in s.codeUnits) {
      if (code == 9 || code == 10 || code == 13) continue; // whitespace
      if (code < 32 || code > 126) nonPrintable++;
      if (nonPrintable > 8) return true; // early exit
    }
    return false;
  }

  String _binaryPlaceholder(int length) => '[binary $length bytes]';
  String _base64Placeholder(int length) => '[base64 ~${length}B]';

  bool _isIgnoredValue(String value, Set<String>? callIgnored) =>
      _ignoredValues.contains(value) || (callIgnored?.contains(value) ?? false);

  bool _isIgnoredKeyLower(String keyLower, Set<String>? callIgnored) =>
      _ignoredKeyNamesLower.contains(keyLower) ||
      (callIgnored?.contains(keyLower) ?? false);

  // --- Defaults ------------------------------------------------------------

  static const Set<String> _kDefaultSensitiveKeys = <String>{
    'authorization',
    'proxy-authorization',
    'x-api-key',
    'api-key',
    'apikey',
    'apiKey',
    'token',
    'access_token',
    'refresh_token',
    'id_token',
    'password',
    'secret',
    'client-secret',
    'client_secret',
    'private-key',
    'private_key',
    'set-cookie',
    'cookie',
  };

  static final List<RegExp> _kDefaultSensitiveKeyRegexps = <RegExp>[
    RegExp(r'(?:^|[_\-])token(?:$|[_\-])', caseSensitive: false),
    RegExp(r'(?:^|[_\-])secret(?:$|[_\-])', caseSensitive: false),
    RegExp(r'(?:^|[_\-])pass(?:word)?(?:$|[_\-])', caseSensitive: false),
    RegExp(r'(?:^|[_\-])key(?:$|[_\-])', caseSensitive: false),
    RegExp(r'(?:^|[_\-])auth(?:$|[_\-])', caseSensitive: false),
  ];

  static final RegExp _schemeRegex = RegExp(r'^(\w+)\s+', caseSensitive: false);
  static final RegExp _jwtRegex =
      RegExp(r'^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$');
  static final RegExp _tokenPrefixRegex = RegExp('^(ghp_|pat_|xox[baprs]-)');
  static final RegExp _base64Regex = RegExp(r'^[A-Za-z0-9+/=\-_\r\n]+$');
}
