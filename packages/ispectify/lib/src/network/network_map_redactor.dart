import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';

/// Standard redaction pipeline for network `toJson()` maps.
///
/// Each method mutates [map] in place, matching the existing pattern across
/// all interceptor data classes. This keeps the consumer code minimal:
///
/// ```dart
/// if (redactor == null) return map;
/// NetworkMapRedactor.redactUrl(map, redactor);
/// NetworkMapRedactor.redactHeaders(map, redactor, ...);
/// NetworkMapRedactor.redactData(map, redactor, ...);
/// ```
abstract final class NetworkMapRedactor {
  /// Redacts a URL field by applying [RedactionService.redactUrl].
  ///
  /// No-op if the field is absent or not a [String].
  static void redactUrl(
    Map<String, dynamic> map,
    RedactionService redactor, {
    String key = NetworkJsonKeys.url,
  }) {
    final value = map[key];
    if (value is String) {
      map[key] = redactor.redactUrl(value);
    }
  }

  /// Redacts a headers field using [RedactionService.redactHeaders].
  ///
  /// Returns the redacted headers map so callers can apply additional
  /// transformations (e.g. stringifying values for `http` package).
  static Map<String, dynamic>? redactHeaders(
    Map<String, dynamic> map,
    RedactionService redactor, {
    String key = NetworkJsonKeys.headers,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final raw = map[key];
    if (raw == null) return null;
    final hdrs = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : null);
    if (hdrs == null) return null;

    final redacted = redactor.redactHeaders(
      hdrs,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    map[key] = redacted;
    return redacted;
  }

  /// Redacts a data/body field via [RedactionService.redact].
  ///
  /// Preserves `null` — if the field is absent or `null`, nothing changes.
  static void redactData(
    Map<String, dynamic> map,
    RedactionService redactor, {
    String key = NetworkJsonKeys.data,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    if (!map.containsKey(key)) return;
    final raw = map[key];
    map[key] = redactor.redact(
          raw,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ) ??
        raw;
  }

  /// Redacts an arbitrary map field (e.g. `extra`, `query-parameters`).
  ///
  /// Keys listed in [preserveKeys] are restored after redaction — useful for
  /// internal metadata like [NetworkJsonKeys.ispectRequestId].
  static void redactMapField(
    Map<String, dynamic> map,
    RedactionService redactor, {
    required String key,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    Set<String> preserveKeys = const {},
  }) {
    final raw = map[key];
    if (raw == null) return;

    final original = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : null);

    final redacted = redactor.redact(
          raw,
          ignoredValues: ignoredValues,
          ignoredKeys: ignoredKeys,
        ) ??
        raw;

    // Restore preserved keys from the original map.
    if (original != null &&
        preserveKeys.isNotEmpty &&
        redacted is Map<String, dynamic>) {
      for (final pk in preserveKeys) {
        if (original.containsKey(pk)) {
          redacted[pk] = original[pk];
        }
      }
    }

    map[key] = redacted;
  }

  /// Redacts `path` and `base-url` fields.
  ///
  /// - `path` is passed through [RedactionService.redact].
  /// - `base-url` has its `userInfo` component replaced if present.
  static void redactPathFields(
    Map<String, dynamic> map,
    RedactionService redactor,
  ) {
    final rawPath = map[NetworkJsonKeys.path];
    if (rawPath is String) {
      map[NetworkJsonKeys.path] =
          redactor.redact(rawPath, keyName: NetworkJsonKeys.path) ?? rawPath;
    }

    final rawBaseUrl = map[NetworkJsonKeys.baseUrl];
    if (rawBaseUrl is String) {
      final baseUri = Uri.tryParse(rawBaseUrl);
      if (baseUri != null && baseUri.userInfo.isNotEmpty) {
        map[NetworkJsonKeys.baseUrl] =
            baseUri.replace(userInfo: userInfoRedactedPlaceholder).toString();
      }
    }
  }

  /// Redacts `location` URLs within redirect entries.
  ///
  /// Mutates each redirect map in place for consistency with other methods.
  static void redactRedirects(
    Map<String, dynamic> map,
    RedactionService redactor,
  ) {
    final redirects = map[NetworkJsonKeys.redirects];
    if (redirects is! List) return;

    for (final redirect in redirects) {
      if (redirect is Map<String, dynamic>) {
        final location = redirect[NetworkJsonKeys.location];
        if (location != null) {
          redirect[NetworkJsonKeys.location] =
              redactor.redactUrl(location.toString());
        }
      }
    }
  }

  /// Redacts multipart request fields and file metadata.
  static void redactMultipart(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final raw = map[NetworkJsonKeys.multipartRequest];
    if (raw is! Map) return;

    final mp = Map<String, dynamic>.from(raw);

    final fields = mp[NetworkJsonKeys.fields];
    if (fields is Map) {
      final red = redactor.redact(
        fields,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      if (red is Map) {
        mp[NetworkJsonKeys.fields] =
            red.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    final files = mp[NetworkJsonKeys.files];
    if (files is List) {
      final red = redactor.redact(
        files,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
      if (red is List) {
        mp[NetworkJsonKeys.files] = red
            .whereType<Map<dynamic, dynamic>>()
            .map(Map<String, Object?>.from)
            .toList();
      }
    }

    map[NetworkJsonKeys.multipartRequest] = mp;
  }
}
