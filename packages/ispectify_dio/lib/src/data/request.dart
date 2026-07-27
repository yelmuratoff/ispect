import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/utils/form_data_serializer.dart';

class DioRequestData {
  DioRequestData(this.requestOptions)
      : uriSnapshot = _snapshotRequestUrl(requestOptions);

  final RequestOptions requestOptions;

  /// Bounded request URL reconstructed without reading [RequestOptions.uri].
  ///
  /// Query parameters stay in their separately normalized field. This avoids
  /// invoking formatters on arbitrary query values while retaining the stable
  /// base URL and path used for diagnostics.
  final NetworkUriSnapshot uriSnapshot;

  /// Returns a raw JSON-compatible map of the request.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson({
    bool includeData = true,
    bool includeHeaders = true,
    bool redactionActive = false,
  }) {
    final normalizedHeaders = includeHeaders
        ? NetworkPayloadSanitizer.toStringKeyMap(requestOptions.headers)
        : null;
    final normalizedQuery =
        NetworkPayloadSanitizer.toStringKeyMap(requestOptions.queryParameters);
    final normalizedExtra =
        NetworkPayloadSanitizer.toStringKeyMap(requestOptions.extra)
          ..remove(NetworkJsonKeys.ispectRequestStartedAt);
    final normalizedData = includeData
        ? _normalizeBody(
            requestOptions.data,
            redactionActive: redactionActive,
          )
        : null;

    final url = uriSnapshot.url;
    final baseUrl = requestOptions.baseUrl;
    final path = requestOptions.path;

    return <String, dynamic>{
      // --- Identity: what & where ---
      NetworkJsonKeys.method: requestOptions.method,
      NetworkJsonKeys.url: url,

      if (baseUrl.isNotEmpty) NetworkJsonKeys.baseUrl: baseUrl,
      if (path != url) NetworkJsonKeys.path: path,
      NetworkJsonKeys.queryParameters: normalizedQuery,

      // --- Payload ---
      NetworkJsonKeys.contentType: requestOptions.contentType,
      if (includeHeaders) NetworkJsonKeys.headers: normalizedHeaders,
      if (includeData) NetworkJsonKeys.data: normalizedData,

      // --- Timing ---
      NetworkJsonKeys.connectTimeout: requestOptions.connectTimeout,
      NetworkJsonKeys.sendTimeout: requestOptions.sendTimeout,
      NetworkJsonKeys.receiveTimeout: requestOptions.receiveTimeout,

      // --- Behaviour ---
      NetworkJsonKeys.followRedirects: requestOptions.followRedirects,
      NetworkJsonKeys.maxRedirects: requestOptions.maxRedirects,
      NetworkJsonKeys.responseType: requestOptions.responseType,
      NetworkJsonKeys.receiveDataWhenStatusError:
          requestOptions.receiveDataWhenStatusError,
      NetworkJsonKeys.persistentConnection: requestOptions.persistentConnection,
      NetworkJsonKeys.preserveHeaderCase: requestOptions.preserveHeaderCase,
      NetworkJsonKeys.listFormat: requestOptions.listFormat,
      NetworkJsonKeys.cancelToken: requestOptions.cancelToken,

      // --- Meta ---
      NetworkJsonKeys.extra: normalizedExtra,
    };
  }

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    NetworkMapRedactor.redactMethod(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.contentType,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactPathFields(map, redactor);
    NetworkMapRedactor.redactUrl(map, redactor);
    NetworkMapRedactor.redactData(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactHeaders(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactMapField(
      map,
      redactor,
      key: NetworkJsonKeys.queryParameters,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactMapField(
      map,
      redactor,
      key: NetworkJsonKeys.extra,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      preserveKeys: {NetworkJsonKeys.ispectRequestId},
    );
  }

  Object? _normalizeBody(
    Object? data, {
    required bool redactionActive,
  }) {
    if (data is FormData) {
      return DioFormDataSerializer.serialize(
        data,
        redactionActive: redactionActive,
      );
    }
    return NetworkPayloadSanitizer.encodeJsonGracefully(data);
  }

  static NetworkUriSnapshot _snapshotRequestUrl(
    RequestOptions requestOptions,
  ) {
    try {
      var url = requestOptions.path;
      if (!url.startsWith('http:') && !url.startsWith('https:')) {
        url = '${requestOptions.baseUrl}$url';
        final schemeParts = url.split(':/');
        if (schemeParts.length == 2) {
          url = '${schemeParts[0]}:/${schemeParts[1].replaceAll('//', '/')}';
        }
      }
      return NetworkUriSnapshot.fromTrustedText(url);
    } on Object {
      return NetworkUriSnapshot.unavailable;
    }
  }
}
