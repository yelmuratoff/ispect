import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectDioInterceptorSettings', () {
    test('copyWith should create a new instance with the provided values', () {
      const originalSettings = ISpectDioInterceptorSettings();
      final updatedSettings = originalSettings.copyWith(
        printResponseData: false,
        printRequestHeaders: true,
        printErrorHeaders: false,
        requestPen: AnsiPen()..yellow(),
      );

      expect(updatedSettings.printResponseData, equals(false));
      expect(updatedSettings.printRequestHeaders, equals(true));
      expect(updatedSettings.printErrorHeaders, equals(false));
      expect(
        updatedSettings.requestPen,
        isNot(same(originalSettings.requestPen)),
      );
      expect(updatedSettings.responseFilter, isNull);
    });

    test('requestFilter should return true for allowed paths', () {
      final settings = ISpectDioInterceptorSettings(
        requestFilter: (requestOptions) => requestOptions.path == '/allowed',
      );
      final allowedRequestOptions =
          RequestOptions(path: '/allowed', method: 'GET');
      final disallowedRequestOptions =
          RequestOptions(path: '/disallowed', method: 'GET');

      expect(settings.requestFilter!(allowedRequestOptions), equals(true));
      expect(settings.requestFilter!(disallowedRequestOptions), equals(false));
    });

    test('responseFilter should return true for successful responses', () {
      final settings = ISpectDioInterceptorSettings(
        responseFilter: (response) => response.statusCode == 200,
      );
      final successfulResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
      );
      final unsuccessfulResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 404,
      );

      expect(settings.responseFilter!(successfulResponse), equals(true));
      expect(settings.responseFilter!(unsuccessfulResponse), equals(false));
    });

    test('errorFilter should return true for cancelled responses', () {
      final settings = ISpectDioInterceptorSettings(
        errorFilter: (err) => err.type == DioExceptionType.cancel,
      );
      final cancelledResponse = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      final timeoutResponse = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );

      expect(settings.errorFilter!(cancelledResponse), equals(true));
      expect(settings.errorFilter!(timeoutResponse), equals(false));
    });

    test('copyWith preserves enabled flag when changing other settings', () {
      // Test with enabled = false
      const disabledSettings = ISpectDioInterceptorSettings(enabled: false);
      final updatedDisabledSettings = disabledSettings.copyWith(
        printResponseData: false,
        printRequestHeaders: true,
      );

      expect(updatedDisabledSettings.enabled, equals(false));
      expect(updatedDisabledSettings.printResponseData, equals(false));
      expect(updatedDisabledSettings.printRequestHeaders, equals(true));

      // Test with enabled = true (default)
      const enabledSettings = ISpectDioInterceptorSettings();
      final updatedEnabledSettings = enabledSettings.copyWith(
        printErrorHeaders: false,
        printRequestData: false,
      );

      expect(updatedEnabledSettings.enabled, equals(true));
      expect(updatedEnabledSettings.printErrorHeaders, equals(false));
      expect(updatedEnabledSettings.printRequestData, equals(false));
    });
  });
}
