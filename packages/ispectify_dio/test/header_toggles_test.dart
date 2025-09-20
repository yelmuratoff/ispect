import 'package:dio/dio.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/error.dart';
import 'package:ispectify_dio/src/data/request.dart';
import 'package:ispectify_dio/src/data/response.dart';
import 'package:ispectify_dio/src/models/error.dart';
import 'package:ispectify_dio/src/models/request.dart';
import 'package:ispectify_dio/src/models/response.dart';
import 'package:test/test.dart';

void main() {
  group('Dio header toggle serialization', () {
    test('Response additionalData omits headers when disabled', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/users',
          method: 'GET',
          headers: {'Authorization': 'Bearer token'},
        ),
        statusCode: 200,
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
        data: {'ok': true},
      );

      const settings = ISpectDioInterceptorSettings(
        
      );

      final log = DioResponseLog(
        'Test',
        responseData: DioResponseData(
          response: response,
          requestData: DioRequestData(response.requestOptions),
        ),
        settings: settings,
        method: 'GET',
        url: response.requestOptions.uri.toString(),
        path: response.requestOptions.uri.path,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        requestHeaders: const <String, dynamic>{},
        headers: const <String, String>{},
        requestBody: const {},
        responseBody: const {},
      );

      final additional = log.additionalData!;
      expect(additional.containsKey('headers'), isFalse);
      final req = additional['request-options'] as Map<String, dynamic>;
      expect(req.containsKey('headers'), isFalse);
    });

    test('Request additionalData omits headers when disabled', () {
      final opts = RequestOptions(
        path: '/ping',
        method: 'POST',
        headers: {'x-api-key': 'secret'},
      );
      const settings = ISpectDioInterceptorSettings(
        
      );

      final log = DioRequestLog(
        'Test',
        requestData: DioRequestData(opts),
        settings: settings,
        method: 'POST',
        url: opts.uri.toString(),
        path: opts.uri.path,
        headers: const {},
        body: null,
      );

      final additional = log.additionalData!;
      expect(additional.containsKey('headers'), isFalse);
    });

    test('Error additionalData omits headers when disabled', () {
      final requestOptions = RequestOptions(
        path: '/err',
        method: 'GET',
        headers: {'Authorization': 'Bearer token'},
      );
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 400,
        headers: Headers.fromMap({
          'content-type': ['json'],
        }),
        data: {'e': 'bad'},
      );
      final ex =
          DioException(requestOptions: requestOptions, response: response);

      const settings = ISpectDioInterceptorSettings(
        
      );

      final log = DioErrorLog(
        'err',
        errorData: DioErrorData(
          exception: ex,
          requestData: DioRequestData(requestOptions),
          responseData: DioResponseData(
              response: response, requestData: DioRequestData(requestOptions),),
        ),
        settings: settings,
        method: 'GET',
        url: requestOptions.uri.toString(),
        path: requestOptions.uri.path,
        statusCode: 400,
        statusMessage: null,
        requestHeaders: const {},
        headers: const {},
        body: const {'e': 'bad'},
      );

      final additional = log.additionalData!;
      final req = additional['request-options'] as Map<String, dynamic>;
      expect(req.containsKey('headers'), isFalse);
      final resp = additional['response'] as Map<String, dynamic>;
      expect(resp.containsKey('headers'), isFalse);
    });
  });
}
