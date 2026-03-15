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
      'url': response?.realUri.toString(),
      'method': response?.requestOptions.method,
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

    // Redact URL query parameters and userInfo credentials
    final url = map['url'];
    if (url is String) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final hasParams = uri.queryParameters.isNotEmpty;
        final hasUserInfo = uri.userInfo.isNotEmpty;
        if (hasParams || hasUserInfo) {
          final redactedParams = hasParams
              ? uri.queryParameters.map(
                  (key, value) =>
                      MapEntry(key, redactor.redact(value, keyName: key)),
                )
              : null;
          map['url'] = uri
              .replace(
                userInfo: hasUserInfo ? '[REDACTED]' : null,
                queryParameters: redactedParams
                    ?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
              )
              .toString();
        }
      }
    }

    map['data'] = redactor.redact(
      map['data'],
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    final rawHdrs = map['headers'];
    if (rawHdrs is Map) {
      final hdrs = Map<String, dynamic>.from(rawHdrs);
      map['headers'] = redactor.redactHeaders(
        hdrs,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    // Extra may contain sensitive data depending on adapters
    final rawExtra = map['extra'];
    final extra = rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null;
    if (extra != null) {
      map['extra'] = redactor.redact(
        extra,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    // Redact redirect URLs which may contain sensitive query parameters
    final redirects = map['redirects'];
    if (redirects is List) {
      map['redirects'] = redirects.map((redirect) {
        if (redirect is Map<String, dynamic>) {
          final location = redirect['location'];
          if (location != null) {
            return {
              ...redirect,
              'location': redactor.redact(
                location.toString(),
                ignoredValues: ignoredValues,
                ignoredKeys: ignoredKeys,
              ),
            };
          }
        }
        return redirect;
      }).toList();
    }

    return map;
  }
}
