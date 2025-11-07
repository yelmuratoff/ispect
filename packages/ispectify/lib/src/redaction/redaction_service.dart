import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';

class _RedactionConfig {
  const _RedactionConfig({
    required this.sensitiveKeysLower,
    required this.sensitiveKeyPatterns,
    required this.maxDepth,
    required this.stringEdgeVisible,
    required this.placeholder,
    required this.redactBinary,
    required this.redactBase64,
    required this.ignoredValues,
    required this.ignoredKeyNamesLower,
    required this.fullyMaskedKeyNamesLower,
  });

  final Set<String> sensitiveKeysLower;
  final List<RegExp> sensitiveKeyPatterns;
  final int maxDepth;
  final int stringEdgeVisible;
  final String placeholder;
  final bool redactBinary;
  final bool redactBase64;
  final Set<String> ignoredValues;
  final Set<String> ignoredKeyNamesLower;
  final Set<String> fullyMaskedKeyNamesLower;
}

/// A configurable service that redacts sensitive values in headers and payloads.
///
/// The implementation delegates traversal to [_RedactionWalker] so configuration
/// and mutation APIs remain focused and easy to extend.
class RedactionService {
  RedactionService({
    Set<String>? sensitiveKeys,
    List<RegExp>? sensitiveKeyPatterns,
    int? stringEdgeVisible,
    String? placeholder,
    bool? redactBinary,
    bool? redactBase64,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    Set<String>? fullyMaskedKeys,
    int? maxDepth,
  }) : _config = _RedactionConfig(
          sensitiveKeysLower: (sensitiveKeys ?? _kDefaultSensitiveKeys)
              .map((e) => e.toLowerCase())
              .toSet(),
          sensitiveKeyPatterns:
              sensitiveKeyPatterns ?? _kDefaultSensitiveKeyRegexps,
          maxDepth: maxDepth ?? 100,
          stringEdgeVisible: stringEdgeVisible ?? 2,
          placeholder: placeholder ?? '[REDACTED]',
          redactBinary: redactBinary ?? true,
          redactBase64: redactBase64 ?? true,
          ignoredValues: {...?ignoredValues, ...ISpectLogType.keys},
          ignoredKeyNamesLower: {
            ...?(ignoredKeys?.map((e) => e.toLowerCase())),
          },
          fullyMaskedKeyNamesLower:
              (fullyMaskedKeys ?? _kDefaultFullyMaskedKeys)
                  .map((e) => e.toLowerCase())
                  .toSet(),
        ) {
    if (_config.maxDepth <= 0) {
      throw ArgumentError(
        'maxDepth must be positive, got: ${_config.maxDepth}',
      );
    }
    if (_config.stringEdgeVisible < 0) {
      throw ArgumentError(
        'stringEdgeVisible must be non-negative, got: ${_config.stringEdgeVisible}',
      );
    }
    if (_config.placeholder.isEmpty) {
      throw ArgumentError('placeholder must not be empty');
    }
  }

  final _RedactionConfig _config;

  /// Redacts header values, respecting optional per-call overrides.
  Map<String, Object?> redactHeaders(
    Map<String, Object?> headers, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _createWalker(
        _RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
      ).redactHeaders(headers);

  /// Redacts any JSON-like payload (Map/List/scalars).
  Object? redact(
    Object? data, {
    String? keyName,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) =>
      _createWalker(
        _RedactionRequest.fromOverrides(ignoredValues, ignoredKeys),
      ).redact(
        data,
        keyName: keyName,
      );

  _RedactionWalker _createWalker(_RedactionRequest request) =>
      _RedactionWalker(_config, request);

  /// Add a string value to the ignore list (exact match).
  void ignoreValue(String value) {
    _config.ignoredValues.add(value);
  }

  /// Add multiple string values to the ignore list (exact matches).
  void ignoreValues(Iterable<String> values) {
    _config.ignoredValues.addAll(values);
  }

  /// Remove a string value from the ignore list.
  void unignoreValue(String value) {
    _config.ignoredValues.remove(value);
  }

  /// Clear all ignored string values.
  void clearIgnoredValues() {
    _config.ignoredValues.clear();
  }

  /// Add a key name to the ignore list (case-insensitive).
  void ignoreKey(String keyName) {
    _config.ignoredKeyNamesLower.add(keyName.toLowerCase());
  }

  /// Add multiple key names to the ignore list (case-insensitive).
  void ignoreKeys(Iterable<String> keyNames) {
    for (final key in keyNames) {
      _config.ignoredKeyNamesLower.add(key.toLowerCase());
    }
  }

  /// Remove a key name from the ignore list.
  void unignoreKey(String keyName) {
    _config.ignoredKeyNamesLower.remove(keyName.toLowerCase());
  }

  /// Clear all ignored key names.
  void clearIgnoredKeys() {
    _config.ignoredKeyNamesLower.clear();
  }
}

class _RedactionRequest {
  const _RedactionRequest._({
    this.ignoredValues,
    this.ignoredKeysLower,
  });

  factory _RedactionRequest.fromOverrides(
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    final normalizedValues = (ignoredValues == null || ignoredValues.isEmpty)
        ? null
        : Set<String>.unmodifiable(ignoredValues);
    final normalizedKeys = (ignoredKeys == null || ignoredKeys.isEmpty)
        ? null
        : Set<String>.unmodifiable(
            ignoredKeys.map((e) => e.toLowerCase()),
          );
    if (normalizedValues == null && normalizedKeys == null) {
      return empty;
    }
    return _RedactionRequest._(
      ignoredValues: normalizedValues,
      ignoredKeysLower: normalizedKeys,
    );
  }

  static const empty = _RedactionRequest._();

  final Set<String>? ignoredValues;
  final Set<String>? ignoredKeysLower;
}

class _RedactionWalker {
  const _RedactionWalker(this.config, this.request);

  final _RedactionConfig config;
  final _RedactionRequest request;

  Map<String, Object?> redactHeaders(Map<String, Object?> headers) {
    final out = <String, Object?>{};
    headers.forEach((key, value) {
      out[key] = _redactNode(
        value,
        keyName: key,
        depth: 0,
      );
    });
    return out;
  }

  Object? redact(Object? data, {String? keyName}) => _redactNode(
        data,
        keyName: keyName,
        depth: 0,
      );

  Object? _redactNode(
    Object? node, {
    required String? keyName,
    required int depth,
  }) {
    if (node == null) return null;
    if (depth >= config.maxDepth) return node;

    if (_isSensitiveKey(keyName)) {
      return _redactSensitiveValue(node, keyName);
    }

    return _redactByType(node, keyName, depth);
  }

  Object? _redactSensitiveValue(Object? node, String? keyName) {
    if (node is String) {
      if (_isIgnoredValue(node)) return node;
      if (keyName != null &&
          config.fullyMaskedKeyNamesLower.contains(keyName.toLowerCase())) {
        return config.placeholder;
      }
      return _maskString(node, keyName: keyName);
    }
    if (node.isScalarType) return config.placeholder;
    if (node is Uint8List) {
      return config.redactBinary ? _redactUint8List(node) : node;
    }
    return config.placeholder;
  }

  Object? _redactByType(
    Object? node,
    String? keyName,
    int depth,
  ) {
    if (keyName != null &&
        node is String &&
        config.fullyMaskedKeyNamesLower.contains(keyName.toLowerCase())) {
      return config.placeholder;
    }

    if (node is Map) {
      return _redactMap(node, depth);
    }
    if (node is List) {
      return _redactList(node, keyName, depth);
    }
    if (node is Uint8List) {
      return config.redactBinary ? _redactUint8List(node) : node;
    }
    if (node is String) {
      return _redactStringContent(node, keyName);
    }

    return node;
  }

  Map<Object?, Object?> _redactMap(
    Map<Object?, Object?> input,
    int depth,
  ) {
    if (input is Map<String, Object?>) {
      final result = <String, Object?>{};
      input.forEach((key, value) {
        result[key] = _redactNode(
          value,
          keyName: key,
          depth: depth + 1,
        );
      });
      return result;
    }

    final result = <Object?, Object?>{};
    input.forEach((key, value) {
      result[key] = _redactNode(
        value,
        keyName: key?.toString(),
        depth: depth + 1,
      );
    });
    return result;
  }

  List<Object?> _redactList(
    List<Object?> input,
    String? keyName,
    int depth,
  ) =>
      input
          .map(
            (value) => _redactNode(
              value,
              keyName: keyName,
              depth: depth + 1,
            ),
          )
          .toList(growable: false);

  Object? _redactStringContent(
    String value,
    String? keyName,
  ) {
    if (_isIgnoredValue(value)) return value;

    if (_looksLikeAuthorizationValue(value)) {
      return _maskString(value, keyName: keyName);
    }
    if (config.redactBase64 && _isLikelyBase64(value)) {
      return _base64Placeholder(value.length);
    }
    if (config.redactBinary && _isProbablyBinaryString(value)) {
      return _binaryPlaceholder(value.codeUnits.length);
    }
    return value;
  }

  String _maskString(
    String value, {
    required String? keyName,
  }) {
    if (value == config.placeholder) return value;

    final match = _schemeRegex.firstMatch(value);
    if (match != null) {
      final prefix = match.group(0) ?? '';
      final remainder = value.substring(prefix.length);
      return '$prefix${_maskEdges(remainder)}';
    }

    if (keyName != null && keyName.toLowerCase() == 'cookie') {
      return value.split(';').map((part) {
        final trimmed = part.trim();
        final separatorIndex = trimmed.indexOf('=');
        if (separatorIndex <= 0) return trimmed;
        final name = trimmed.substring(0, separatorIndex);
        final cookieValue = trimmed.substring(separatorIndex + 1);
        return '$name=${_maskEdges(cookieValue)}';
      }).join('; ');
    }

    return _maskEdges(value);
  }

  String _maskEdges(String input) {
    if (input.isEmpty) return config.placeholder;
    final edge = config.stringEdgeVisible;
    if (input.length <= edge * 2) return config.placeholder;

    final start = input.substring(0, edge);
    final end = input.substring(input.length - edge);
    return '$start…$end (${config.placeholder})';
  }

  bool _looksLikeAuthorizationValue(String value) {
    if (_jwtRegex.hasMatch(value)) return true;
    if (value.startsWith('Bearer ') ||
        value.startsWith('Basic ') ||
        value.startsWith('Digest ')) {
      return true;
    }
    return _tokenPrefixRegex.hasMatch(value);
  }

  bool _isLikelyBase64(String value) {
    final sanitized = value.replaceAll(RegExp(r'\s'), '');
    if (sanitized.length < 32) return false;
    if (!_base64Regex.hasMatch(sanitized)) return false;
    if (sanitized.length % 4 == 1) return false;

    final sampleLength = sanitized.length > 256 ? 256 : sanitized.length;
    final sample = sanitized.substring(0, sampleLength);
    return _canDecodeBase64Sample(sample);
  }

  bool _canDecodeBase64Sample(String sample) {
    if (_tryDecodeWithCodec(sample, base64)) return true;
    if (_tryDecodeWithCodec(sample, base64Url)) return true;
    return false;
  }

  bool _tryDecodeWithCodec(String input, Base64Codec codec) {
    try {
      codec.decode(input);
      return true;
    } catch (_) {
      final remainder = input.length % 4;
      if (remainder == 0) return false;
      final padded = input.padRight(input.length + (4 - remainder), '=');
      try {
        codec.decode(padded);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  bool _isProbablyBinaryString(String value) {
    const maxNonPrintable = 8;
    const maxInspected = 1024;
    const ratioThreshold = 0.2;
    const ratioSampleFloor = 16;

    var inspected = 0;
    var nonPrintable = 0;
    for (final codePoint in value.runes) {
      if (inspected >= maxInspected) break;
      inspected++;
      if (_isPrintableCodePoint(codePoint)) continue;
      nonPrintable++;
      if (nonPrintable > maxNonPrintable) return true;
      if (inspected >= ratioSampleFloor &&
          nonPrintable / inspected > ratioThreshold) {
        return true;
      }
    }
    return false;
  }

  bool _isPrintableCodePoint(int codePoint) {
    if (codePoint == 0xFFFD) return false;
    if (codePoint == 0x09 || codePoint == 0x0A || codePoint == 0x0D) {
      return true;
    }
    if (codePoint >= 0x20 && codePoint <= 0x7E) return true;
    if (codePoint == 0x85 || codePoint == 0x2028 || codePoint == 0x2029) {
      return true;
    }
    if (codePoint >= 0xA0 && codePoint <= 0xD7FF) return true;
    if (codePoint >= 0xE000 && codePoint <= 0x10FFFF) return true;
    return false;
  }

  String _binaryPlaceholder(int length) => '[binary $length bytes]';

  String _base64Placeholder(int length) => '[base64 ~${length}B]';

  Uint8List _redactUint8List(Uint8List data) {
    final placeholder = _binaryPlaceholder(data.length);
    final placeholderBytes = Uint8List.fromList(placeholder.codeUnits);
    final length = placeholderBytes.length > data.length
        ? data.length
        : placeholderBytes.length;
    final result = Uint8List(data.length)
      ..setRange(0, length, placeholderBytes.take(length));
    for (var i = length; i < data.length; i++) {
      result[i] = 0;
    }
    return result;
  }

  bool _isIgnoredValue(String value) =>
      config.ignoredValues.contains(value) ||
      (request.ignoredValues?.contains(value) ?? false);

  bool _isIgnoredKey(String keyLower) =>
      config.ignoredKeyNamesLower.contains(keyLower) ||
      (request.ignoredKeysLower?.contains(keyLower) ?? false);

  bool _isSensitiveKey(String? key) {
    if (key == null) return false;
    final lower = key.toLowerCase();
    if (_isIgnoredKey(lower)) return false;
    if (config.sensitiveKeysLower.contains(lower)) return true;
    for (final pattern in config.sensitiveKeyPatterns) {
      if (pattern.hasMatch(lower)) return true;
    }
    return false;
  }
}

const Set<String> _kDefaultSensitiveKeys = <String>{
  // Authentication & Authorization
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

  // Personal Identification Numbers
  'ssn',
  'social_security',
  'social-security',
  'social_security_number',
  'socialSecurityNumber',
  'national_id',
  'nationalId',
  'national-id',
  'passport',
  'passport_number',
  'passportNumber',
  'passport-number',
  'drivers_license',
  'driversLicense',
  'drivers-license',
  'driver_license',
  'driverLicense',
  'driver-license',
  'license_number',
  'licenseNumber',
  'license-number',

  // Financial Information
  'credit_card',
  'creditCard',
  'credit-card',
  'card_number',
  'cardNumber',
  'card-number',
  'cc_number',
  'ccNumber',
  'cc-number',
  'cvv',
  'cvc',
  'cvv2',
  'card_cvv',
  'cardCvv',
  'security_code',
  'securityCode',
  'security-code',
  'bank_account',
  'bankAccount',
  'bank-account',
  'account_number',
  'accountNumber',
  'account-number',
  'routing_number',
  'routingNumber',
  'routing-number',
  'iban',
  'swift',
  'swift_code',
  'swiftCode',
  'swift-code',
  'bic',

  // Personal Contact Information (context-dependent)
  'phone',
  'phone_number',
  'phoneNumber',
  'phone-number',
  'mobile',
  'mobile_number',
  'mobileNumber',
  'mobile-number',
  'cell',
  'cell_phone',
  'cellPhone',
  'cell-phone',
};

final List<RegExp> _kDefaultSensitiveKeyRegexps = <RegExp>[
  // Authentication patterns
  RegExp(r'(?:^|[_\-])token(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])secret(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])pass(?:word)?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])key(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])auth(?:$|[_\-])', caseSensitive: false),

  // Personal identification patterns
  RegExp(r'(?:^|[_\-])ssn(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])social[_\-]?security(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])passport(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])drivers?[_\-]?license(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])national[_\-]?id(?:$|[_\-])', caseSensitive: false),

  // Financial patterns
  RegExp(r'(?:^|[_\-])credit[_\-]?card(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])card[_\-]?num(?:ber)?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cvv[0-9]?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cvc(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])bank[_\-]?account(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])routing[_\-]?num(?:ber)?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])account[_\-]?num(?:ber)?(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])iban(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])swift(?:$|[_\-])', caseSensitive: false),

  // Contact information patterns
  RegExp(r'(?:^|[_\-])phone(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])mobile(?:$|[_\-])', caseSensitive: false),
  RegExp(r'(?:^|[_\-])cell(?:$|[_\-])', caseSensitive: false),
];

final RegExp _schemeRegex = RegExp(r'^(\w+)\s+', caseSensitive: false);
final RegExp _jwtRegex =
    RegExp(r'^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$');
final RegExp _tokenPrefixRegex = RegExp('^(ghp_|pat_|xox[baprs]-)');
final RegExp _base64Regex = RegExp(r'^[A-Za-z0-9+/=_-]+$');
const Set<String> _kDefaultFullyMaskedKeys = <String>{
  'filename',
};

extension _ObjectExtensions on Object? {
  bool get isScalarType {
    final obj = this;
    return obj is num || obj is bool || obj is DateTime || obj is String;
  }
}
