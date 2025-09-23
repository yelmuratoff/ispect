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
      'request-options': redactor == null
          ? requestData.toJson()
          : requestData.toJson(
              redactor: redactor,
              ignoredValues: ignoredValues,
              ignoredKeys: ignoredKeys,
            ),
      'real-uri': response?.realUri.toString(),
      'data': response?.data,
      'status-code': response?.statusCode,
      'status-message': response?.statusMessage,
      'extra': response?.extra,
      'is-redirect': response?.isRedirect,
      'redirects': response?.redirects == null
          ? null
          : response!.redirects
              .map(
                (e) => {
                  'location': e.location,
                  'status-code': e.statusCode,
                  'method': e.method,
                },
              )
              .toList(),
      'headers': headers?.map,
    };

    if (redactor == null) {
      return map;
    }

    // Redact response-level fields

    map['data'] = redactor.redact(
      map['data'],
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    final hdrs = (map['headers'] as Map?)?.cast<String, dynamic>();
    if (hdrs != null) {
      map['headers'] = redactor.redactHeaders(
        hdrs,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    // Extra may contain sensitive data depending on adapters
    final extra = (map['extra'] as Map?)?.cast<String, dynamic>();
    if (extra != null) {
      map['extra'] = redactor.redact(
        extra,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    return map;
  }
}
