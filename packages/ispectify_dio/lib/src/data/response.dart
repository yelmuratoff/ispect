import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioResponseData {
  DioResponseData({
    required this.response,
    required this.requestData,
  });

  final Response<dynamic>? response;

  final DioRequestData requestData;

  /// Returns a raw JSON-compatible map of the response.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson({
    bool includeData = true,
    bool includeHeaders = true,
    bool includeMessage = true,
    bool includeRequestData = true,
    bool includeRequestHeaders = true,
    bool redactionActive = false,
  }) {
    final resp = response;
    final headers = includeHeaders ? resp?.headers : null;
    final redirects = _serializeRedirects(
      resp?.redirects,
      redactionActive: redactionActive,
    );
    return <String, dynamic>{
      // --- Status: first thing you check ---
      NetworkJsonKeys.statusCode: resp?.statusCode,
      if (includeMessage) NetworkJsonKeys.statusMessage: resp?.statusMessage,

      // --- Identity ---
      NetworkJsonKeys.method: resp?.requestOptions.method,
      NetworkJsonKeys.url: _responseUrl(
        resp,
        redirects,
        requestUri: requestData.uriSnapshot,
        redactionActive: redactionActive,
      ),

      // --- Payload ---
      if (includeHeaders) NetworkJsonKeys.headers: headers?.map,
      if (includeData) NetworkJsonKeys.data: resp?.data,

      // --- Redirects ---
      NetworkJsonKeys.isRedirect: resp?.isRedirect,
      NetworkJsonKeys.redirects: redirects,

      // --- Meta ---
      NetworkJsonKeys.extra: resp?.extra,

      // --- Original request (reference) ---
      NetworkJsonKeys.request: requestData.toJson(
        includeData: includeRequestData,
        includeHeaders: includeRequestHeaders,
        redactionActive: redactionActive,
      ),
    };
  }

  static List<Object?>? _serializeRedirects(
    List<RedirectRecord>? redirects, {
    required bool redactionActive,
  }) {
    if (redirects == null) return null;
    final bounded = LogExportOutput.boundJsonValue(
      redirects.map(
        (redirect) {
          final location = NetworkUriSnapshot.fromUri(redirect.location);
          return <String, Object?>{
            NetworkJsonKeys.location: location.url,
            NetworkJsonKeys.statusCode: redirect.statusCode,
            NetworkJsonKeys.method: redirect.method,
          };
        },
      ),
      replaceOversizedStrings: redactionActive,
    );
    return bounded is List<Object?> ? bounded : <Object?>[];
  }

  static String? _responseUrl(
    Response<dynamic>? response,
    List<Object?>? redirects, {
    required NetworkUriSnapshot requestUri,
    required bool redactionActive,
  }) {
    if (response == null) return null;
    if (redirects != null && redirects.isNotEmpty) {
      final last = redirects.last;
      if (last case final Map<String, Object?> redirect) {
        final location = redirect[NetworkJsonKeys.location];
        if (location is String) return location;
      }
      return LogExportOutput.truncatedMarker;
    }
    final bounded = LogExportOutput.boundJsonValue(
      requestUri.url,
      replaceOversizedStrings: redactionActive,
    );
    return bounded is String ? bounded : JsonValueNormalizer.unprintableValue;
  }

  /// Applies in-place redaction to a map produced by [toJson].
  ///
  /// Also redacts the embedded [NetworkJsonKeys.request] sub-map.
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
    NetworkMapRedactor.redactUrl(map, redactor);
    NetworkMapRedactor.redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.statusMessage,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
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
      key: NetworkJsonKeys.extra,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactRedirects(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    if (map[NetworkJsonKeys.request]
        case final Map<String, dynamic> requestMap) {
      DioRequestData.redact(
        requestMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
  }
}
