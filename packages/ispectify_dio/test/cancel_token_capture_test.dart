import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

final class _HostileCancelToken extends CancelToken {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    throw StateError('tenantSecret=CANCEL_TOKEN_SECRET');
  }
}

void main() {
  for (final captureMode in DiagnosticCaptureMode.values) {
    test('$captureMode capture records only whether a cancel token exists', () {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      addTearDown(logger.dispose);
      final token = _HostileCancelToken();

      ISpectDioInterceptor(
        logger: logger,
        settings: ISpectDioInterceptorSettings(captureMode: captureMode),
      ).onRequest(
        RequestOptions(path: 'https://api.example.test/users')
          ..cancelToken = token,
        RequestInterceptorHandler(),
      );

      final meta = logger.history.single.additionalData?[TraceKeys.meta] as Map;
      final requestData = meta[NetworkJsonKeys.requestData] as Map;
      expect(requestData[NetworkJsonKeys.cancelToken], isTrue);
      expect(token.toStringCalls, 0);
      expect(
        logger.history.single.toString(),
        isNot(contains('CANCEL_TOKEN_SECRET')),
      );
    });
  }
}
