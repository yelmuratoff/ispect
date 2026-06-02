import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

/// Mimics a freezed/json_serializable DTO that Retrofit passes through
/// without serializing (Dio encodes it only at transform time).
class _TypedBody {
  const _TypedBody(this.code);

  final String code;

  Map<String, dynamic> toJson() => <String, dynamic>{'referralCode': code};

  @override
  String toString() => '_TypedBody(code: $code)';
}

class _OpaqueBody {
  @override
  String toString() => 'opaque-body';
}

void main() {
  ISpectDioInterceptor buildInterceptor(ISpectLogger logger) =>
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
        ),
      );

  test('typed body with toJson is logged as its JSON map', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = buildInterceptor(logger);

    final options = RequestOptions(path: 'https://api.example.com/apply')
      ..data = const _TypedBody('ABC123');

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    expect(log.key, ISpectLogType.httpRequest.key);
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    expect(requestData?['data'], <String, dynamic>{'referralCode': 'ABC123'});
  });

  test('body without toJson is logged as the raw value', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = buildInterceptor(logger);

    final options = RequestOptions(path: 'https://api.example.com/apply');
    final body = _OpaqueBody();
    options.data = body;

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    expect(requestData?['data'], same(body));
  });

  test('map, string and list bodies are passed through untouched', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = buildInterceptor(logger);

    for (final body in <Object>[
      <String, dynamic>{'k': 'v'},
      'plain-string',
      <int>[1, 2, 3],
    ]) {
      final options = RequestOptions(path: 'https://api.example.com/apply')
        ..data = body;

      interceptor.onRequest(options, RequestInterceptorHandler());

      final log = logger.history.last;
      final meta = log.additionalData?[TraceKeys.meta] as Map?;
      final requestData = meta?['request-data'] as Map?;
      expect(requestData?['data'], body);
    }
  });
}
