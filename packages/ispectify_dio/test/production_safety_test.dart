import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

final class _SerializationProbe {
  _SerializationProbe(this.onSerialize);

  final void Function() onSerialize;

  Map<String, Object?> toJson() {
    onSerialize();
    return const {'password': 'synthetic-secret'};
  }
}

final class _ObservedErrorHandler extends ErrorInterceptorHandler {
  Future<void> get done async {
    try {
      await future;
    } on Object {
      // Dio represents `next(error)` as an error completion.
    }
  }
}

void main() {
  test(
    'omitted flag bypasses capture, filters, and request mutation',
    () async {
      var serialized = false;
      var requestFilterCalls = 0;
      var responseFilterCalls = 0;
      var errorFilterCalls = 0;
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: ISpectDioInterceptorSettings(
          requestChain: NetworkFilterChain<RequestOptions>.fromPredicate((_) {
            requestFilterCalls++;
            return true;
          }),
          responseChain:
              NetworkFilterChain<Response<dynamic>>.fromPredicate((_) {
            responseFilterCalls++;
            return true;
          }),
          errorChain: NetworkFilterChain<DioException>.fromPredicate((_) {
            errorFilterCalls++;
            return true;
          }),
        ),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/users',
        data: _SerializationProbe(() => serialized = true),
        extra: {'existing': 'value'},
      );
      final errorHandler = _ObservedErrorHandler();
      final errorHandled = errorHandler.done;

      interceptor
        ..onRequest(options, RequestInterceptorHandler())
        ..onResponse(
          Response<dynamic>(requestOptions: options, statusCode: 200),
          ResponseInterceptorHandler(),
        )
        ..onError(
          DioException(requestOptions: options),
          errorHandler,
        );
      await errorHandled;

      expect(logger.history, isEmpty);
      expect(serialized, isFalse);
      expect(requestFilterCalls, 0);
      expect(responseFilterCalls, 0);
      expect(errorFilterCalls, 0);
      expect(options.extra, {'existing': 'value'});
    },
    skip: kISpectEnabled
        ? 'This regression test must run without ISPECT_ENABLED.'
        : false,
  );
}
