import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/dio_logs.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  group('DioRequestLog', () {
    test('textMessage should include method and message', () {
      final requestOptions = RequestOptions(path: '/test', method: 'GET');
      final settings = ISpectifyDioLoggerSettings(
        requestPen: AnsiPen()..blue(),
      );
      final dioRequestLog = DioRequestLog(
        'Test message',
        requestOptions: requestOptions,
        settings: settings,
      );

      final result = dioRequestLog.textMessage;

      expect(result, contains('[GET] Test message'));
    });

    test('textMessage should include data if printRequestData is true', () {
      final requestOptions = RequestOptions(path: '/test', method: 'POST', data: {'key': 'value'});
      final settings = ISpectifyDioLoggerSettings(printRequestData: true);
      final dioRequestLog = DioRequestLog('Test message', requestOptions: requestOptions, settings: settings);

      final result = dioRequestLog.textMessage;

      expect(result, contains('Data: {\n  "key": "value"\n}'));
    });

    test('textMessage should include headers if printRequestHeaders is true', () {
      final requestOptions = RequestOptions(path: '/test', method: 'GET', headers: {'Authorization': 'Bearer Token'});
      final settings = ISpectifyDioLoggerSettings(printRequestHeaders: true);
      final dioRequestLog = DioRequestLog('Test message', requestOptions: requestOptions, settings: settings);

      final result = dioRequestLog.textMessage;

      expect(result, contains('Headers: {\n  "Authorization": "Bearer Token"\n}'));
    });

    // Add more tests for DioRequestLog as needed
  });

  group('DioResponseLog', () {
    test('textMessage should include method, message, and status', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 200,
        data: {'key': 'value'},
        headers: Headers.fromMap({
          'content-type': ['application/json']
        }),
      );
      final settings = ISpectifyDioLoggerSettings(
        responsePen: AnsiPen()..blue(),
      );
      final dioResponseLog = DioResponseLog(
        'Test message',
        response: response,
        settings: settings,
      );

      final result = dioResponseLog.textMessage;

      expect(dioResponseLog.pen, isNotNull);
      expect(result, contains('[GET] Test message'));
      expect(result, contains('Status: 200'));
      expect(result, contains('Data: {\n  "key": "value"\n}'));
    });

    test('textMessage should include message if printResponseMessage is true', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 200,
        statusMessage: 'OK',
      );
      final settings = ISpectifyDioLoggerSettings(printResponseMessage: true);
      final dioResponseLog = DioResponseLog(
        'Test message',
        response: response,
        settings: settings,
      );

      final result = dioResponseLog.textMessage;

      expect(result, contains('Message: OK'));
    });

    test('textMessage should include headers if printResponseHeaders is true', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 200,
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
      );
      final settings = ISpectifyDioLoggerSettings(printResponseHeaders: true);
      final dioResponseLog = DioResponseLog('Test message', response: response, settings: settings);

      final result = dioResponseLog.textMessage;

      expect(
          result,
          contains('Headers: {\n'
              '  "content-type": [\n'
              '    "application/json"\n'
              '  ]\n'
              '}'));
    });

    // Add more tests for DioResponseLog as needed
  });

  group('DioErrorLog', () {
    test('textMessage should include method, title, and message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
      );
      final settings = ISpectifyDioLoggerSettings(
        errorPen: AnsiPen()..blue(),
      );
      final dioErrorLog = DioErrorLog('Error title', dioException: dioException, settings: settings);

      final result = dioErrorLog.textMessage;

      expect(
          result,
          contains('[log] [GET] Error title\n'
              'Message: Error message'));
    });

    test('textMessage should not include data, header and message if disabled', () {
      final dioException = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          message: 'Error message',
          response: Response(
              requestOptions: RequestOptions(path: '/test', method: 'GET'),
              headers: Headers.fromMap(
                {
                  'content-type': ['application/json'],
                },
              )));
      final settings = ISpectifyDioLoggerSettings(
        errorPen: AnsiPen()..blue(),
        printErrorData: false,
        printErrorHeaders: false,
        printErrorMessage: false,
      );
      final dioErrorLog = DioErrorLog('Error title', dioException: dioException, settings: settings);

      final result = dioErrorLog.textMessage;
      expect(result, contains('[log] [GET] Error title'));
      expect(result, isNot(contains('Message: Error message')));
      expect(
          result,
          isNot(contains(
            'Headers: {\n'
            '  "content-type": [\n'
            '    "application/json"\n'
            '  ]\n'
            '}',
          )));
    });

    test('textMessage should include status if response has a status code', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 404,
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        response: response,
        message: 'Error message',
      );

      final settings = ISpectifyDioLoggerSettings();
      final dioErrorLog = DioErrorLog('Error title', dioException: dioException, settings: settings);

      final result = dioErrorLog.textMessage;

      expect(result, contains('Status: 404'));
    });

    test('textMessage should include data if response has data', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        statusCode: 500,
        data: {'error': 'Internal Server Error'},
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
        response: response,
      );

      final settings = ISpectifyDioLoggerSettings();
      final dioErrorLog = DioErrorLog('Error title', dioException: dioException, settings: settings);

      final result = dioErrorLog.textMessage;

      expect(result, contains('Data: {\n  "error": "Internal Server Error"\n}'));
    });

    test('textMessage should include headers if request has headers', () {
      final response = Response(requestOptions: RequestOptions(path: '/test', method: 'GET'));
      response.headers = Headers.fromMap(
        {
          'content-type': ['application/json'],
        },
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        message: 'Error message',
        response: response,
      );

      final settings = ISpectifyDioLoggerSettings(printResponseHeaders: true);
      final dioErrorLog = DioErrorLog('Error title', dioException: dioException, settings: settings);

      final result = dioErrorLog.textMessage;

      expect(
          result,
          contains(
            'Headers: {\n'
            '  "content-type": [\n'
            '    "application/json"\n'
            '  ]\n'
            '}',
          ));
    });
  });
}
