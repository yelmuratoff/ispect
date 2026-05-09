import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/utils/form_data_serializer.dart';

class DioRequestData {
  DioRequestData(this.requestOptions);

  final RequestOptions requestOptions;

  /// Returns a raw JSON-compatible map of the request.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson() {
    final normalizedHeaders =
        NetworkPayloadSanitizer.toStringKeyMap(requestOptions.headers);
    final normalizedQuery =
        NetworkPayloadSanitizer.toStringKeyMap(requestOptions.queryParameters);
    final normalizedExtra =
        NetworkPayloadSanitizer.toStringKeyMap(requestOptions.extra);
    final normalizedData = _normalizeBody(requestOptions.data);

    final url = requestOptions.uri.toString();
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
      NetworkJsonKeys.headers: normalizedHeaders,
      NetworkJsonKeys.data: normalizedData,

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
    );
  }

  Object? _normalizeBody(Object? data) {
    if (data is FormData) {
      return DioFormDataSerializer.serialize(data);
    }
    return data;
  }
}
