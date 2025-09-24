import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/error.dart';
import 'package:ispectify_dio/src/data/request.dart';
import 'package:ispectify_dio/src/data/response.dart';
import 'package:ispectify_dio/src/models/error.dart';
import 'package:ispectify_dio/src/models/request.dart';
import 'package:ispectify_dio/src/models/response.dart';
import 'package:test/test.dart';

void main() {
  group('DioRequestLog', () {
    test('textMessage should include method and message', () {
      final requestOptions = RequestOptions(path: '/test', method: 'GET');
      final settings = ISpectDioInterceptorSettings(
        requestPen: AnsiPen()..blue(),
      );
      final dioRequestLog = DioRequestLog(
        'Test message',
        requestData: DioRequestData(requestOptions),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        headers: <String, dynamic>{},
        body: null,
      );

      final result = dioRequestLog.textMessage;

      expect(result, contains('[GET] Test message'));
    });

    test('textMessage should include data if printRequestData is true', () {
      final requestOptions =
          RequestOptions(path: '/test', method: 'POST', data: {'key': 'value'});
      const settings = ISpectDioInterceptorSettings();
      final dioRequestLog = DioRequestLog(
        'Test message',
        requestData: DioRequestData(requestOptions),
        settings: settings,
        method: 'POST',
        url: 'https://example.com/test',
        path: '/test',
        headers: <String, dynamic>{},
        body: {'key': 'value'},
      );

      final result = dioRequestLog.textMessage;

      expect(result, contains('Data: {\n  "key": "value"\n}'));
    });

    test('textMessage should include headers if printRequestHeaders is true',
        () {
      final requestOptions = RequestOptions(
        path: '/test',
        method: 'GET',
        headers: {'Authorization': 'Bearer Token'},
      );
      const settings = ISpectDioInterceptorSettings(printRequestHeaders: true);
      final dioRequestLog = DioRequestLog(
        'Test message',
        requestData: DioRequestData(requestOptions),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        headers: <String, dynamic>{'Authorization': 'Bearer Token'},
        body: null,
      );

      final result = dioRequestLog.textMessage;

      expect(
        result,
        contains('Headers: {\n  "Authorization": "Bearer Token"\n}'),
      );
    });

    // Add more tests for DioRequestLog as needed
  });

  group('DioResponseLog', () {
    test('textMessage should include method, message, and status', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 200,
        data: {'key': 'value'},
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
      );
      final settings = ISpectDioInterceptorSettings(
        responsePen: AnsiPen()..blue(),
      );
      final dioResponseLog = DioResponseLog(
        'Test message',
        responseData: DioResponseData(
          response: response,
          requestData: DioRequestData(response.requestOptions),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: 200,
        statusMessage: null,
        requestHeaders: <String, dynamic>{},
        headers: {'content-type': 'application/json'},
        requestBody: null,
        responseBody: {'key': 'value'},
      );

      final result = dioResponseLog.textMessage;

      expect(dioResponseLog.pen, isNotNull);
      expect(result, contains('[http-response] [GET] Test message'));
      expect(result, contains('Status: 200'));
      expect(result, contains('Data: {\n  "key": "value"\n}'));
    });

    test('textMessage should include message if printResponseMessage is true',
        () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 200,
        statusMessage: 'OK',
      );
      const settings = ISpectDioInterceptorSettings();
      final dioResponseLog = DioResponseLog(
        'Test message',
        responseData: DioResponseData(
          response: response,
          requestData: DioRequestData(response.requestOptions),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: 200,
        statusMessage: 'OK',
        requestHeaders: {},
        headers: {},
        requestBody: null,
        responseBody: null,
      );

      final result = dioResponseLog.textMessage;

      expect(result, contains('Message: OK'));
    });

    test('textMessage should include headers if printResponseHeaders is true',
        () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 200,
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
      );
      const settings = ISpectDioInterceptorSettings(printResponseHeaders: true);
      final dioResponseLog = DioResponseLog(
        'Test message',
        responseData: DioResponseData(
          response: response,
          requestData: DioRequestData(response.requestOptions),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: 200,
        statusMessage: null,
        requestHeaders: <String, dynamic>{},
        headers: {'content-type': 'application/json'},
        requestBody: null,
        responseBody: null,
      );

      final result = dioResponseLog.textMessage;

      expect(
        result,
        contains('Headers: {\n'
            '  "content-type": "application/json"\n'
            '}'),
      );
    });

    // Add more tests for DioResponseLog as needed
  });

  group('DioErrorLog', () {
    test('textMessage should include method, title, and message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
      );
      final settings = ISpectDioInterceptorSettings(
        errorPen: AnsiPen()..blue(),
      );
      final dioErrorLog = DioErrorLog(
        'Error title',
        errorData: DioErrorData(
          exception: dioException,
          requestData: DioRequestData(dioException.requestOptions),
          responseData: DioResponseData(
            response: dioException.response,
            requestData: DioRequestData(dioException.requestOptions),
          ),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: null,
        statusMessage: null,
        requestHeaders: <String, dynamic>{},
        headers: null,
        body: null,
      );

      final result = dioErrorLog.textMessage;

      expect(
        result,
        contains('[GET] Error title\n'
            'Message: Error message'),
      );
    });

    test('textMessage should not include data, header and message if disabled',
        () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
        response: Response(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          headers: Headers.fromMap(
            {
              'content-type': ['application/json'],
            },
          ),
        ),
      );
      final settings = ISpectDioInterceptorSettings(
        errorPen: AnsiPen()..blue(),
        printErrorData: false,
        printErrorHeaders: false,
        printErrorMessage: false,
      );
      final dioErrorLog = DioErrorLog(
        'Error title',
        errorData: DioErrorData(
          exception: dioException,
          requestData: DioRequestData(dioException.requestOptions),
          responseData: DioResponseData(
            response: dioException.response,
            requestData: DioRequestData(dioException.requestOptions),
          ),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: null,
        statusMessage: null,
        requestHeaders: <String, dynamic>{},
        headers: {'content-type': 'application/json'},
        body: null,
      );

      final result = dioErrorLog.textMessage;
      expect(result, contains('[GET] Error title'));
      expect(result, isNot(contains('Message: Error message')));
      expect(
        result,
        isNot(
          contains('Headers: {\n'
              '  "content-type": [\n'
              '    "application/json"\n'
              '  ]\n'
              '}'),
        ),
      );
    });

    test('textMessage should include status if response has a status code', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 404,
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        response: response,
        message: 'Error message',
      );

      const settings = ISpectDioInterceptorSettings();
      final dioErrorLog = DioErrorLog(
        'Error title',
        errorData: DioErrorData(
          exception: dioException,
          requestData: DioRequestData(dioException.requestOptions),
          responseData: DioResponseData(
            response: dioException.response,
            requestData: DioRequestData(dioException.requestOptions),
          ),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: 404,
        statusMessage: null,
        requestHeaders: {},
        headers: {},
        body: null,
      );

      final result = dioErrorLog.textMessage;

      expect(result, contains('Status: 404'));
    });

    test('textMessage should include data if response has data', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 500,
        data: {'error': 'Internal Server Error'},
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
        response: response,
      );

      const settings = ISpectDioInterceptorSettings();
      final dioErrorLog = DioErrorLog(
        'Error title',
        errorData: DioErrorData(
          exception: dioException,
          requestData: DioRequestData(dioException.requestOptions),
          responseData: DioResponseData(
            response: dioException.response,
            requestData: DioRequestData(dioException.requestOptions),
          ),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: 500,
        statusMessage: null,
        requestHeaders: {},
        headers: {},
        body: {'error': 'Internal Server Error'},
      );

      final result = dioErrorLog.textMessage;

      expect(
        result,
        contains('Data: {\n  "error": "Internal Server Error"\n}'),
      );
    });

    test('textMessage should include headers if request has headers', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
      )..headers = Headers.fromMap(
          {
            'content-type': ['application/json'],
          },
        );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
        response: response,
      );

      const settings = ISpectDioInterceptorSettings(printResponseHeaders: true);
      final dioErrorLog = DioErrorLog(
        'Error title',
        errorData: DioErrorData(
          exception: dioException,
          requestData: DioRequestData(dioException.requestOptions),
          responseData: DioResponseData(
            response: dioException.response,
            requestData: DioRequestData(dioException.requestOptions),
          ),
        ),
        settings: settings,
        method: 'GET',
        url: 'https://example.com/test',
        path: '/test',
        statusCode: null,
        statusMessage: null,
        requestHeaders: <String, dynamic>{},
        headers: {'content-type': 'application/json'},
        body: null,
      );

      final result = dioErrorLog.textMessage;

      expect(
        result,
        contains('Headers: {\n'
            '  "content-type": "application/json"\n'
            '}'),
      );
    });
  });
}
