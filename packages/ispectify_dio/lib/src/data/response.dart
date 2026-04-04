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
  Map<String, dynamic> toJson() {
    final headers = response?.headers;
    return <String, dynamic>{
      // --- Status: first thing you check ---
      NetworkJsonKeys.statusCode: response?.statusCode,
      NetworkJsonKeys.statusMessage: response?.statusMessage,

      // --- Identity ---
      NetworkJsonKeys.method: response?.requestOptions.method,
      NetworkJsonKeys.url: response?.realUri.toString(),

      // --- Payload ---
      NetworkJsonKeys.headers: headers?.map,
      NetworkJsonKeys.data: response?.data,

      // --- Redirects ---
      NetworkJsonKeys.isRedirect: response?.isRedirect,
      NetworkJsonKeys.redirects: response?.redirects == null
          ? null
          : response!.redirects
              .map(
                (e) => {
                  NetworkJsonKeys.location: e.location,
                  NetworkJsonKeys.statusCode: e.statusCode,
                  NetworkJsonKeys.method: e.method,
                },
              )
              .toList(),

      // --- Meta ---
      NetworkJsonKeys.extra: response?.extra,

      // --- Original request (reference) ---
      NetworkJsonKeys.request: requestData.toJson(),
    };
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
      key: NetworkJsonKeys.extra,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactRedirects(map, redactor);

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
