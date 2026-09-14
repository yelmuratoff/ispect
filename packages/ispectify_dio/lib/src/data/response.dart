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
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  }) {
    final resp = response;
    final headers = includeHeaders && resp != null
        ? NetworkPayloadSanitizer.toStringKeyMap(
            resp.headers.map,
            captureMode: captureMode,
            resourceLimits: requestData.resourceLimits,
            maxEntries: requestData.resourceLimits.maxNetworkHeaders,
          )
        : null;
    final redirects = _serializeRedirects(
      resp?.redirects,
      redactionActive: redactionActive,
      captureMode: captureMode,
      resourceLimits: requestData.resourceLimits,
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
        resourceLimits: requestData.resourceLimits,
      ),

      // --- Payload ---
      if (includeHeaders) NetworkJsonKeys.headers: headers,
      if (includeData)
        NetworkJsonKeys.data: LogExportOutput.boundJsonValue(
          NetworkPayloadSanitizer.encodeJsonGracefully(
            resp?.data,
            captureMode: captureMode,
            resourceLimits: requestData.resourceLimits,
          ),
          maxBytes: requestData.resourceLimits.maxNetworkBodyBytes,
          resourceLimits: requestData.resourceLimits,
          replaceOversizedStrings: redactionActive,
        ),

      // --- Redirects ---
      NetworkJsonKeys.isRedirect: resp?.isRedirect,
      NetworkJsonKeys.redirects: redirects,

      // --- Meta ---
      NetworkJsonKeys.extra: NetworkPayloadSanitizer.toStringKeyMap(
        resp?.extra,
        captureMode: captureMode,
        resourceLimits: requestData.resourceLimits,
      ),

      // --- Original request (reference) ---
      NetworkJsonKeys.request: requestData.toJson(
        includeData: includeRequestData,
        includeHeaders: includeRequestHeaders,
        redactionActive: redactionActive,
        captureMode: captureMode,
      ),
    };
  }

  static List<Object?>? _serializeRedirects(
    List<RedirectRecord>? redirects, {
    required bool redactionActive,
    required DiagnosticCaptureMode captureMode,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    if (redirects == null) return null;
    final bounded = LogExportOutput.boundJsonValue(
      redirects.map(
        (redirect) {
          final location = NetworkUriSnapshot.fromUri(
            redirect.location,
            captureMode: captureMode,
            resourceLimits: resourceLimits,
          );
          return <String, Object?>{
            NetworkJsonKeys.location: location.url,
            NetworkJsonKeys.statusCode: redirect.statusCode,
            NetworkJsonKeys.method: redirect.method,
          };
        },
      ),
      replaceOversizedStrings: redactionActive,
      resourceLimits: resourceLimits,
    );
    return bounded is List<Object?> ? bounded : <Object?>[];
  }

  static String? _responseUrl(
    Response<dynamic>? response,
    List<Object?>? redirects, {
    required NetworkUriSnapshot requestUri,
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
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
      resourceLimits: resourceLimits,
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
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    NetworkMapRedactor.redactMethod(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactUrl(
      map,
      redactor,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.statusMessage,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactData(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactHeaders(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactMapField(
      map,
      redactor,
      key: NetworkJsonKeys.extra,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );
    NetworkMapRedactor.redactRedirects(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
      resourceLimits: resourceLimits,
    );

    if (map[NetworkJsonKeys.request]
        case final Map<String, dynamic> requestMap) {
      DioRequestData.redact(
        requestMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
      );
    }
  }
}
