import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/network/replay/network_replay_body.dart';
import 'package:ispectify/src/redaction/constants/key_defaults.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';
import 'package:meta/meta.dart';

/// A transport-agnostic description of an HTTP request to send.
///
/// Built either from scratch in the composer UI or reconstructed from a
/// captured log via [NetworkReplayRequestParser.fromRequestMap]. Query
/// parameters live inside [uri]; the UI edits them through `uri.queryParameters`.
@immutable
final class NetworkReplayRequest {
  const NetworkReplayRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.body,
  });

  /// HTTP verb in upper case (`GET`, `POST`, ...).
  final String method;

  /// Full target including any query parameters.
  final Uri uri;

  /// Request headers. Redacted values from a captured log are excluded here
  /// (see [ParsedReplayRequest.redactedHeaderKeys]) so the real client's
  /// interceptors can re-inject them at send time.
  final Map<String, String> headers;

  /// Payload, or `null` for a request without a body.
  final NetworkReplayBody? body;

  NetworkReplayRequest copyWith({
    String? method,
    Uri? uri,
    Map<String, String>? headers,
    NetworkReplayBody? body,
  }) =>
      NetworkReplayRequest(
        method: method ?? this.method,
        uri: uri ?? this.uri,
        headers: headers ?? this.headers,
        body: body ?? this.body,
      );
}

/// The result of reconstructing a [NetworkReplayRequest] from a captured log,
/// carrying which values were dropped because they were redacted.
///
/// The UI uses this to mark fields as "provided by your client" instead of
/// silently sending placeholder text such as `[REDACTED]`.
@immutable
final class ParsedReplayRequest {
  const ParsedReplayRequest({
    required this.request,
    this.redactedHeaderKeys = const {},
    this.bodyRedacted = false,
  });

  final NetworkReplayRequest request;

  /// Header names whose captured value was redacted and therefore omitted.
  final Set<String> redactedHeaderKeys;

  /// Whether the captured body was redacted (and so not reconstructable).
  final bool bodyRedacted;
}

/// Reconstructs a [NetworkReplayRequest] from a captured request map.
///
/// The input uses [NetworkJsonKeys] names, matching what the Dio and `http`
/// interceptors store. Redacted header values are dropped rather than resent.
abstract final class NetworkReplayRequestParser {
  /// Builds a [ParsedReplayRequest] from a captured request [map].
  ///
  /// Returns `null` when [map] lacks a usable URL.
  static ParsedReplayRequest? fromRequestMap(
    Map<String, dynamic> map, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final bounded = LogExportOutput.boundJsonValue(
      map,
      maxBytes: resourceLimits.maxLogRecordBytes,
      resourceLimits: resourceLimits,
    );
    if (bounded is! Map<String, Object?>) return null;

    final urlValue = bounded[NetworkJsonKeys.url] ?? bounded['uri'];
    if (urlValue is! String ||
        _isUnsafeText(urlValue) ||
        LogExportOutput.utf8Length(
              urlValue,
              limit: resourceLimits.maxCapturedValueBytes,
            ) >
            resourceLimits.maxCapturedValueBytes) {
      return null;
    }
    final uri = Uri.tryParse(urlValue);
    if (uri == null) return null;
    final provenance = _provenanceOf(bounded);
    if (provenance[NetworkJsonKeys.urlRedacted] == true) return null;

    final rawMethod = bounded[NetworkJsonKeys.method];
    final method = rawMethod is String && !_isUnsafeText(rawMethod)
        ? LogExportOutput.truncateUtf8(rawMethod, maxBytes: 32).toUpperCase()
        : 'GET';

    final redactedHeaderKeys = <String>{};
    final recordedHeaderKeys = provenance[NetworkJsonKeys.redactedHeaderKeys];
    if (recordedHeaderKeys is List<Object?>) {
      redactedHeaderKeys.addAll(recordedHeaderKeys.whereType<String>());
    }
    final headers = _parseHeaders(
      bounded,
      redactedHeaderKeys,
      resourceLimits,
    );

    final contentType = _primitiveText(
      bounded[NetworkJsonKeys.contentType] ??
          headers['content-type'] ??
          headers['Content-Type'],
    );
    if (contentType != null && _isUnsafeText(contentType)) return null;

    if (provenance[NetworkJsonKeys.queryRedacted] == true ||
        _containsUnsafeMarker(bounded[NetworkJsonKeys.queryParameters])) {
      return null;
    }

    var bodyRedacted = provenance[NetworkJsonKeys.bodyRedacted] == true;
    final body = bodyRedacted
        ? null
        : _parseBody(
            bounded,
            contentType: contentType,
            resourceLimits: resourceLimits,
            onRedacted: () => bodyRedacted = true,
          );

    return ParsedReplayRequest(
      request: NetworkReplayRequest(
        method: method,
        uri: _withQueryParameters(uri, bounded, resourceLimits),
        headers: headers,
        body: body,
      ),
      redactedHeaderKeys: redactedHeaderKeys,
      bodyRedacted: bodyRedacted,
    );
  }

  static Map<String, String> _parseHeaders(
    Map<String, dynamic> map,
    Set<String> redactedKeys,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final raw = map[NetworkJsonKeys.headers];
    if (raw is! Map) return const {};
    final headers = <String, String>{};
    for (final entry in raw.entries.take(resourceLimits.maxNetworkHeaders)) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      final name = key is String ? key : null;
      final text = _primitiveText(value);
      if (name == null ||
          text == null ||
          _isUnsafeText(name) ||
          _isUnsafeText(text)) {
        if (name != null && !_isUnsafeText(name)) {
          redactedKeys.add(name);
        }
        continue;
      }
      if (redactedKeys.contains(name) ||
          _isSensitiveHeaderName(name) ||
          _containsUnsafeMarker(text)) {
        redactedKeys.add(name);
        continue;
      }
      headers[name] = text;
    }
    return headers;
  }

  static Uri _withQueryParameters(
    Uri uri,
    Map<String, dynamic> map,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final raw = map[NetworkJsonKeys.queryParameters];
    if (raw is! Map || raw.isEmpty) return uri;
    final merged = <String, String>{...uri.queryParameters};
    for (final entry in raw.entries.take(resourceLimits.maxCollectionItems)) {
      final key = entry.key;
      final value = _primitiveText(entry.value);
      if (key is String &&
          value != null &&
          !_isUnsafeText(key) &&
          !_isUnsafeText(value)) {
        merged[key] = value;
      }
    }
    return merged.isEmpty ? uri : uri.replace(queryParameters: merged);
  }

  static NetworkReplayBody? _parseBody(
    Map<String, dynamic> map, {
    required String? contentType,
    required DiagnosticResourceLimits resourceLimits,
    required void Function() onRedacted,
  }) {
    final multipart = map[NetworkJsonKeys.multipartRequest];
    if (multipart is Map) {
      final boundedMultipart = LogExportOutput.boundJsonValue(
        multipart,
        maxBytes: resourceLimits.maxNetworkBodyBytes,
        resourceLimits: resourceLimits,
        replaceOversizedStrings: true,
      );
      if (boundedMultipart is! Map || _containsUnsafeMarker(boundedMultipart)) {
        onRedacted();
        return null;
      }
      return _parseMultipart(boundedMultipart, resourceLimits);
    }

    final raw = map.containsKey(NetworkJsonKeys.data)
        ? map[NetworkJsonKeys.data]
        : map[NetworkJsonKeys.body];
    if (raw == null) return null;
    final boundedRaw = LogExportOutput.boundJsonValue(
      raw,
      maxBytes: resourceLimits.maxNetworkBodyBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: true,
    );
    if (_containsUnsafeMarker(boundedRaw)) {
      onRedacted();
      return null;
    }

    if (boundedRaw is Map || boundedRaw is List) {
      return JsonReplayBody(boundedRaw);
    }

    final text = _primitiveText(boundedRaw);
    if (text == null || _isUnsafeText(text)) {
      onRedacted();
      return null;
    }
    if (contentType != null &&
        contentType.contains('application/x-www-form-urlencoded')) {
      try {
        return FormUrlEncodedReplayBody(Uri.splitQueryString(text));
      } on FormatException {
        onRedacted();
        return null;
      } catch (_) {
        onRedacted();
        return null;
      }
    }
    return TextReplayBody(text, contentType: contentType);
  }

  static MultipartReplayBody _parseMultipart(
    Map<dynamic, dynamic> multipart,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final fields = <MultipartReplayField>[];
    final rawFields = multipart[NetworkJsonKeys.fields];
    if (rawFields is Map) {
      for (final entry
          in rawFields.entries.take(resourceLimits.maxCollectionItems)) {
        final name = entry.key;
        final value = _primitiveText(entry.value) ?? '';
        if (name is String && !_isUnsafeText(name) && !_isUnsafeText(value)) {
          fields.add(MultipartReplayField(name, value));
        }
      }
    }
    return MultipartReplayBody(fields: fields);
  }

  static String? _primitiveText(Object? value) => switch (value) {
        final String text => text,
        final bool primitive => primitive.toString(),
        final num primitive => primitive.toString(),
        _ => null,
      };

  static Map<String, Object?> _provenanceOf(Map<String, Object?> map) {
    final value = map[NetworkJsonKeys.redactionProvenance];
    return value is Map<String, Object?> ? value : const {};
  }

  static bool _isSensitiveHeaderName(String name) {
    final lower = name.trim().toLowerCase();
    final underscored = lower.replaceAll('-', '_');
    return defaultSensitiveKeys.contains(lower) ||
        defaultSensitiveKeys.contains(underscored);
  }

  static bool _containsUnsafeMarker(Object? value) {
    if (value is String) return _isUnsafeText(value);
    if (value is Map) {
      for (final entry in value.entries) {
        if (_containsUnsafeMarker(entry.key) ||
            _containsUnsafeMarker(entry.value)) {
          return true;
        }
      }
      return false;
    }
    if (value is Iterable) {
      for (final item in value) {
        if (_containsUnsafeMarker(item)) return true;
      }
    }
    return false;
  }

  static bool _isUnsafeText(String value) {
    var candidate = value;
    for (var pass = 0; pass < 3; pass++) {
      if (_containsPlainUnsafeMarker(candidate)) return true;
      try {
        final decoded = Uri.decodeFull(candidate);
        if (decoded == candidate) return false;
        candidate = decoded;
      } on FormatException {
        return true;
      } catch (_) {
        return true;
      }
    }
    return _containsPlainUnsafeMarker(candidate);
  }

  static bool _containsPlainUnsafeMarker(String value) =>
      value.contains(defaultPlaceholder) ||
      value.contains(userInfoRedactedPlaceholder) ||
      value.contains(_legacyShortMask) ||
      value.contains(redactionFailedPlaceholder) ||
      value.contains(conversionFailedPlaceholder) ||
      value.contains(LogExportOutput.truncatedMarker) ||
      value.contains(JsonValueNormalizer.unprintableValue) ||
      value.contains(JsonValueNormalizer.circularReference) ||
      value.contains(JsonValueNormalizer.maxDepthReached) ||
      value.contains(JsonValueNormalizer.maxNodesReached) ||
      value.contains(JsonValueNormalizer.maxCollectionItemsReached) ||
      _binaryMarker.hasMatch(value) ||
      _base64Marker.hasMatch(value) ||
      _diagnosticDescriptor.hasMatch(value);

  static final RegExp _binaryMarker = RegExp(r'\[binary \d+ bytes\]');
  static final RegExp _base64Marker = RegExp(r'\[base64 ~\d+B\]');
  static final RegExp _diagnosticDescriptor = RegExp(r"^Instance of '.+'$");

  /// Pre-unification short mask, still recognized so replay never resends a
  /// value redacted by an older capture.
  static const String _legacyShortMask = '***';
}
