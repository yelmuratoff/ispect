import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

/// Mimics a freezed/json_serializable DTO that Retrofit passes through
/// without serializing (Dio encodes it only at transform time).
class _TypedBody {
  _TypedBody(this.code);

  final String code;
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, dynamic> toJson() {
    toJsonCalls++;
    return <String, dynamic>{'referralCode': code};
  }

  @override
  String toString() {
    toStringCalls++;
    return '_TypedBody(code: $code)';
  }
}

class _OpaqueBody {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    return 'opaque-body';
  }
}

class _AuthBody {
  _AuthBody(this.provider, this.profile);

  final String provider;
  final _TypedBody profile;
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, dynamic> toJson() {
    toJsonCalls++;
    return <String, dynamic>{
      'provider': provider,
      'profile': profile,
    };
  }

  @override
  String toString() {
    toStringCalls++;
    return '_AuthBody(provider: $provider, profile: $profile)';
  }
}

void main() {
  ISpectDioInterceptor buildInterceptor(ISpectLogger logger) =>
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
          printRequestData: true,
        ),
      );

  test('typed body is logged as a non-executing descriptor', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = buildInterceptor(logger);
    final body = _TypedBody('ABC123');

    final options = RequestOptions(path: 'https://api.example.com/apply')
      ..data = body;

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    expect(log.key, ISpectLogType.httpRequest.key);
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    expect(requestData?['data'], isA<String>());
    expect(requestData?['data'], isNot(contains('ABC123')));
    expect(body.toJsonCalls, 0);
    expect(body.toStringCalls, 0);
  });

  test('body without toJson fails closed without stringification', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = buildInterceptor(logger);
    final body = _OpaqueBody();

    final options = RequestOptions(path: 'https://api.example.com/apply')
      ..data = body;

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    expect(requestData?['data'], isA<String>());
    expect(requestData?['data'], isNot(contains('opaque-body')));
    expect(body.toStringCalls, 0);
  });

  test('nested DTO graph is not traversed through toJson', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = buildInterceptor(logger);
    final profile = _TypedBody('ABC123');
    final body = _AuthBody('APPLE', profile);

    final options = RequestOptions(path: 'https://api.example.com/signin')
      ..data = body;

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    expect(requestData?['data'], isA<String>());
    expect(requestData?['data'], isNot(contains('APPLE')));
    expect(requestData?['data'], isNot(contains('ABC123')));
    expect(body.toJsonCalls, 0);
    expect(body.toStringCalls, 0);
    expect(profile.toJsonCalls, 0);
    expect(profile.toStringCalls, 0);
  });

  test('nested DTO remains non-executing when redaction is enabled', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      settings: const ISpectDioInterceptorSettings(printRequestData: true),
    );
    final profile = _TypedBody('ABC123');
    final body = _AuthBody('APPLE', profile);

    final options = RequestOptions(path: 'https://api.example.com/signin')
      ..data = body;

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    expect(requestData?['data'], isA<String>());
    expect(requestData?['data'], isNot(contains('APPLE')));
    expect(requestData?['data'], isNot(contains('ABC123')));
    expect(body.toJsonCalls, 0);
    expect(body.toStringCalls, 0);
    expect(profile.toJsonCalls, 0);
    expect(profile.toStringCalls, 0);
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
