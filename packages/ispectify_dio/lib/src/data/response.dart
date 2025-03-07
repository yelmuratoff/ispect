import 'package:dio/dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioResponseData {
  DioResponseData({
    required this.response,
    required this.requestData,
  });

  final Response<dynamic>? response;

  final DioRequestData requestData;

  Map<String, dynamic> get toJson => {
        'request-options': requestData.toJson,
        'real-uri': response?.realUri,
        'data': response?.data,
        'status-code': response?.statusCode,
        'status-message': response?.statusMessage,
        'extra': response?.extra,
        'is-redirect': response?.isRedirect,
        'redirects': response?.redirects
            .map(
              (e) => {
                'location': e.location,
                'status-code': e.statusCode,
                'methid': e.method,
              },
            )
            .toList(),
        'headers': response?.headers.map,
      };
}
