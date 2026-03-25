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

  Map<String, dynamic> toJson({
    RedactionService? redactor,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    final headers = response?.headers;
    final map = <String, dynamic>{
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
      NetworkJsonKeys.request: redactor == null
          ? requestData.toJson()
          : requestData.toJson(
              redactor: redactor,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
    };

    if (redactor == null) return map;

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

    return map;
  }
}
