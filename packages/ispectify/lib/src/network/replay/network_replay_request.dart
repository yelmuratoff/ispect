import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/network/replay/network_replay_body.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
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
  static ParsedReplayRequest? fromRequestMap(Map<String, dynamic> map) {
    final urlValue = map[NetworkJsonKeys.url] ?? map['uri'];
    final uri = urlValue is String ? Uri.tryParse(urlValue) : null;
    if (uri == null) return null;

    final method =
        (map[NetworkJsonKeys.method] as String?)?.toUpperCase() ?? 'GET';

    final redactedHeaderKeys = <String>{};
    final headers = _parseHeaders(map, redactedHeaderKeys);

    final contentType = (map[NetworkJsonKeys.contentType] ??
            headers['content-type'] ??
            headers['Content-Type'])
        ?.toString();

    var bodyRedacted = false;
    final body = _parseBody(
      map,
      contentType: contentType,
      onRedacted: () => bodyRedacted = true,
    );

    return ParsedReplayRequest(
      request: NetworkReplayRequest(
        method: method,
        uri: _withQueryParameters(uri, map),
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
  ) {
    final raw = map[NetworkJsonKeys.headers];
    if (raw is! Map) return const {};
    final headers = <String, String>{};
    raw.forEach((key, value) {
      if (value == null) return;
      final name = key.toString();
      final text = value.toString();
      if (_isRedacted(text)) {
        redactedKeys.add(name);
        return;
      }
      headers[name] = text;
    });
    return headers;
  }

  static Uri _withQueryParameters(Uri uri, Map<String, dynamic> map) {
    final raw = map[NetworkJsonKeys.queryParameters];
    if (raw is! Map || raw.isEmpty) return uri;
    final merged = <String, String>{...uri.queryParameters};
    raw.forEach((key, value) {
      if (value != null) merged[key.toString()] = value.toString();
    });
    return merged.isEmpty ? uri : uri.replace(queryParameters: merged);
  }

  static NetworkReplayBody? _parseBody(
    Map<String, dynamic> map, {
    required String? contentType,
    required void Function() onRedacted,
  }) {
    final multipart = map[NetworkJsonKeys.multipartRequest];
    if (multipart is Map) return _parseMultipart(multipart);

    final raw = map.containsKey(NetworkJsonKeys.data)
        ? map[NetworkJsonKeys.data]
        : map[NetworkJsonKeys.body];
    if (raw == null) return null;

    if (raw is Map || raw is List) return JsonReplayBody(raw);

    final text = raw.toString();
    if (_isRedacted(text)) {
      onRedacted();
      return null;
    }
    if (contentType != null &&
        contentType.contains('application/x-www-form-urlencoded')) {
      return FormUrlEncodedReplayBody(Uri.splitQueryString(text));
    }
    return TextReplayBody(text, contentType: contentType);
  }

  static MultipartReplayBody _parseMultipart(Map<dynamic, dynamic> multipart) {
    final fields = <MultipartReplayField>[];
    final rawFields = multipart[NetworkJsonKeys.fields];
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        fields
            .add(MultipartReplayField(key.toString(), value?.toString() ?? ''));
      });
    }
    return MultipartReplayBody(fields: fields);
  }

  static bool _isRedacted(String value) =>
      value == defaultPlaceholder || value == _legacyShortMask;

  /// Pre-unification short mask, still recognized so replay never resends a
  /// value redacted by an older capture.
  static const String _legacyShortMask = '***';
}
