import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/request.dart';
import 'package:ispectify_dio/src/data/response.dart';
import 'package:test/test.dart';

Map<String, dynamic> _meta(ISpectLogData log) =>
    log.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

final class _ErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        '{"password":"response-secret"}',
        500,
        statusMessage: 'response-message',
        headers: {
          'content-type': ['application/json'],
          'authorization': ['Bearer response-token'],
        },
      );

  @override
  void close({bool force = false}) {}
}

final class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.secret, {this.sensitiveKey = 'password'});

  final String secret;
  final String sensitiveKey;
  late final Exception error = Exception(
    'transport failed {"$sensitiveKey":"$secret"}',
  );
  late final StackTrace stackTrace = StackTrace.fromString(
    'request https://api.example.com?api_key=$secret',
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      throw DioException(
        requestOptions: options,
        message: 'request failed with Bearer $secret',
        error: error,
        stackTrace: stackTrace,
      );

  @override
  void close({bool force = false}) {}
}

final class _SerializationProbe {
  _SerializationProbe(this.onSerialize);

  final void Function() onSerialize;

  Map<String, Object?> toJson() {
    onSerialize();
    return const {'password': 'synthetic-secret'};
  }
}

final class _SensitiveDto {
  _SensitiveDto(this.secret);

  final String secret;
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    return <String, Object?>{
      'password': secret,
      'label': 'visible',
    };
  }

  @override
  String toString() {
    toStringCalls++;
    return secret;
  }
}

final class _ThrowingDto {
  _ThrowingDto(this.secret);

  final String secret;
  int toJsonCalls = 0;
  int toStringCalls = 0;

  Map<String, Object?> toJson() {
    toJsonCalls++;
    throw const FormatException('invalid DTO');
  }

  @override
  String toString() {
    toStringCalls++;
    return secret;
  }
}

final class _ObservedErrorHandler extends ErrorInterceptorHandler {
  Future<void> get done async {
    try {
      await future;
    } on Object {
      // Dio completes next(error) through the error channel.
    }
  }
}

final class _HostileUri implements Uri {
  int pathCalls = 0;
  int runtimeTypeCalls = 0;
  int toStringCalls = 0;

  @override
  Type get runtimeType {
    runtimeTypeCalls++;
    return Uri.parse('https://spoofed.example.test').runtimeType;
  }

  @override
  String get path {
    pathCalls++;
    throw StateError('hostile path');
  }

  @override
  String toString() {
    toStringCalls++;
    throw StateError('hostile formatter');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('hostile Uri member');
}

final class _HostileUriRequestOptions extends RequestOptions {
  _HostileUriRequestOptions(this.hostileUri)
      : super(path: 'https://api.example.com/fallback');

  final Uri hostileUri;
  int uriCalls = 0;

  @override
  Uri get uri {
    uriCalls++;
    return hostileUri;
  }
}

final class _LazyRedirects extends ListBase<RedirectRecord> {
  _LazyRedirects(this.length);

  @override
  final int length;

  int reads = 0;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  RedirectRecord operator [](int index) {
    reads++;
    return RedirectRecord(
      302,
      'GET',
      Uri.parse('https://redirect-$index.example.com'),
    );
  }

  @override
  void operator []=(int index, RedirectRecord value) =>
      throw UnsupportedError('immutable');
}

void main() {
  group('Dio security regressions', () {
    test('hostile request and redirect Uris stay opaque without aborting flow',
        () {
      final uri = _HostileUri();
      final options = _HostileUriRequestOptions(uri);
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        redirects: <RedirectRecord>[
          RedirectRecord(302, 'GET', uri),
        ],
      );

      final requestJson = DioRequestData(options).toJson(
        captureMode: DiagnosticCaptureMode.strict,
      );
      final responseJson = DioResponseData(
        response: response,
        requestData: DioRequestData(options),
      ).toJson(captureMode: DiagnosticCaptureMode.strict);
      final redirect =
          (responseJson[NetworkJsonKeys.redirects] as List).single as Map;

      expect(
        requestJson[NetworkJsonKeys.url],
        'https://api.example.com/fallback',
      );
      expect(
        responseJson[NetworkJsonKeys.url],
        JsonValueNormalizer.unprintableValue,
      );
      expect(
        redirect[NetworkJsonKeys.location],
        JsonValueNormalizer.unprintableValue,
      );
      expect(
        (responseJson[NetworkJsonKeys.request] as Map)[NetworkJsonKeys.url],
        'https://api.example.com/fallback',
      );

      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          captureMode: DiagnosticCaptureMode.strict,
        ),
      );
      final requestHandler = RequestInterceptorHandler();
      final responseHandler = ResponseInterceptorHandler();

      expect(
        () => interceptor.onRequest(options, requestHandler),
        returnsNormally,
      );
      expect(requestHandler.isCompleted, isTrue);
      expect(
        () => interceptor.onResponse(response, responseHandler),
        returnsNormally,
      );
      expect(responseHandler.isCompleted, isTrue);
      expect(logger.history, hasLength(2));
      for (final log in logger.history) {
        expect(
          log.additionalData?[TraceKeys.target],
          'https://api.example.com/fallback',
        );
      }
      expect(options.uriCalls, 0);
      expect(uri.toStringCalls, 0);
      expect(uri.pathCalls, 0);
      expect(uri.runtimeTypeCalls, 0);
    });

    test('does not serialize request bodies when capture is disabled', () {
      var serializationCount = 0;
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printRequestData: false,
        ),
      ).onRequest(
        RequestOptions(
          path: 'https://api.example.com/request',
          data: _SerializationProbe(() => serializationCount++),
        ),
        RequestInterceptorHandler(),
      );

      expect(serializationCount, 0);
      final requestData =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      expect(requestData.containsKey(NetworkJsonKeys.data), isFalse);
    });

    test('bounds FormData fields, files, headers, and oversized strings', () {
      final formData = FormData();
      formData.fields.add(
        MapEntry(
          'oversized',
          'FORM_FIELD_SECRET_${'x' * (1024 * 1024)}',
        ),
      );
      for (var index = 0;
          index < JsonValueNormalizer.defaultMaxCollectionItems + 100;
          index++) {
        formData.fields.add(MapEntry('field-$index', 'value-$index'));
        formData.files.add(
          MapEntry(
            'file-$index',
            MultipartFile.fromBytes(
              const [],
              filename: 'file-$index.txt',
              headers: <String, List<String>>{
                'x-file': <String>[
                  if (index == 0)
                    'FILE_HEADER_SECRET_${'y' * (1024 * 1024)}'
                  else
                    'value-$index',
                ],
              },
            ),
          ),
        );
      }
      final request = RequestOptions(
        path: 'https://api.example.com/upload',
        data: formData,
      );

      final data = DioRequestData(request).toJson(
        redactionActive: true,
      )[NetworkJsonKeys.data] as Map;
      final encoded = data.toString();
      expect(encoded, isNot(contains('FORM_FIELD_SECRET_')));
      expect(encoded, isNot(contains('FILE_HEADER_SECRET_')));
      expect(encoded, contains(LogExportOutput.truncatedMarker));
      expect(
        LogExportOutput.utf8Length(encoded),
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes),
      );
    });

    test('bounds lazy redirect traversal and does not read the raw last item',
        () {
      final redirects = _LazyRedirects(
        JsonValueNormalizer.defaultMaxCollectionItems * 100,
      );
      final options = RequestOptions(path: 'https://api.example.com/start');
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        redirects: redirects,
      );

      final data = DioResponseData(
        response: response,
        requestData: DioRequestData(options),
      ).toJson();
      final serialized = data[NetworkJsonKeys.redirects] as List;

      expect(
        redirects.reads,
        lessThanOrEqualTo(
          JsonValueNormalizer.defaultMaxCollectionItems + 1,
        ),
      );
      expect(
        serialized.last,
        JsonValueNormalizer.maxCollectionItemsReached,
      );
      expect(
        data[NetworkJsonKeys.url],
        LogExportOutput.truncatedMarker,
      );
    });

    test('redacts sensitive keys in a JSON-encoded request body', () {
      const secret = 'DIO-JSON-STRING-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(printRequestData: true),
      ).onRequest(
        RequestOptions(
          path: 'https://api.example.com/login',
          data: '{"username":"ada","password":"$secret"}',
        ),
        RequestInterceptorHandler(),
      );

      final data =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      expect(data[NetworkJsonKeys.data], isA<String>());
      expect(data[NetworkJsonKeys.data], isNot(contains(secret)));
    });

    test('captures and redacts response DTOs by default', () {
      const bodySecret = 'violet-response-payload';
      const extraSecret = 'violet-response-extra';
      final body = _SensitiveDto(bodySecret);
      final extra = _SensitiveDto(extraSecret);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final options = RequestOptions(path: 'https://api.example.com/profile');

      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printResponseData: true,
        ),
      ).onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: body,
          extra: <String, Object?>{'diagnostic': extra},
        ),
        ResponseInterceptorHandler(),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData] as Map;
      final safeExtra = responseData[NetworkJsonKeys.extra] as Map;
      expect(responseData[NetworkJsonKeys.data], {
        'password': '[REDACTED]',
        'label': 'visible',
      });
      expect(safeExtra['diagnostic'], {
        'password': '[REDACTED]',
        'label': 'visible',
      });
      expect(responseData.toString(), isNot(contains(bodySecret)));
      expect(responseData.toString(), isNot(contains(extraSecret)));
      expect(body.toJsonCalls, 1);
      expect(body.toStringCalls, 0);
      expect(extra.toJsonCalls, 1);
      expect(extra.toStringCalls, 0);
    });

    test('does not invoke throwing response DTO formatters', () {
      const bodySecret = 'violet-throwing-response';
      const extraSecret = 'violet-throwing-extra';
      final body = _ThrowingDto(bodySecret);
      final extra = _ThrowingDto(extraSecret);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final options = RequestOptions(path: 'https://api.example.com/profile');

      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printResponseData: true,
        ),
      ).onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: body,
          extra: <String, Object?>{'diagnostic': extra},
        ),
        ResponseInterceptorHandler(),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData] as Map;
      final safeExtra = responseData[NetworkJsonKeys.extra] as Map;
      expect(responseData[NetworkJsonKeys.data], isA<String>());
      expect(safeExtra['diagnostic'], isA<String>());
      expect(responseData.toString(), isNot(contains(bodySecret)));
      expect(responseData.toString(), isNot(contains(extraSecret)));
      expect(body.toJsonCalls, 1);
      expect(body.toStringCalls, 0);
      expect(extra.toJsonCalls, 1);
      expect(extra.toStringCalls, 0);
    });

    test('scrubs malformed JSON with configured sensitive keys', () {
      const secret = 'DIO-MALFORMED-CUSTOM-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(printRequestData: true),
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      ).onRequest(
        RequestOptions(
          path: 'https://api.example.com/login',
          data: '{"tenantSecret":"$secret",}',
        ),
        RequestInterceptorHandler(),
      );

      final data =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      expect(data[NetworkJsonKeys.data], isA<String>());
      expect(data[NetworkJsonKeys.data], isNot(contains(secret)));
    });

    test('disabled request and response fields are not retained', () {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printRequestData: false,
          printRequestHeaders: false,
          printResponseData: false,
          printResponseHeaders: false,
          printResponseMessage: false,
        ),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/users',
        data: '{"password":"request-secret"}',
        headers: {'Authorization': 'Bearer request-token'},
      );

      interceptor
        ..onRequest(options, RequestInterceptorHandler())
        ..onResponse(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            statusMessage: 'response-message',
            data: {'password': 'response-secret'},
            headers: Headers()..add('Authorization', 'Bearer response-token'),
          ),
          ResponseInterceptorHandler(),
        );

      final requestData =
          _meta(logger.history[0])[NetworkJsonKeys.requestData] as Map;
      expect(requestData.containsKey(NetworkJsonKeys.data), isFalse);
      expect(requestData.containsKey(NetworkJsonKeys.headers), isFalse);

      final responseData =
          _meta(logger.history[1])[NetworkJsonKeys.responseData] as Map;
      expect(responseData.containsKey(NetworkJsonKeys.data), isFalse);
      expect(responseData.containsKey(NetworkJsonKeys.headers), isFalse);
      expect(responseData.containsKey(NetworkJsonKeys.statusMessage), isFalse);
      final nestedRequest = responseData[NetworkJsonKeys.request] as Map;
      expect(nestedRequest.containsKey(NetworkJsonKeys.data), isFalse);
      expect(nestedRequest.containsKey(NetworkJsonKeys.headers), isFalse);
    });

    test('production settings retain only an error record', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: ISpectDioInterceptorSettingsBuilder.production().build(),
      );
      final successOptions =
          RequestOptions(path: 'https://api.example.com/success');

      interceptor
        ..onRequest(successOptions, RequestInterceptorHandler())
        ..onResponse(
          Response<dynamic>(
            requestOptions: successOptions,
            statusCode: 200,
          ),
          ResponseInterceptorHandler(),
        );

      expect(logger.history, isEmpty);

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _ErrorAdapter()
        ..interceptors.add(interceptor);
      try {
        await dio.get<dynamic>('/failure');
      } on DioException {
        // Expected: Dio rejects 5xx responses by default.
      }

      expect(logger.history, hasLength(1));
      expect(logger.history.single.key, ISpectLogType.httpError.key);
      expect(
        logger.history.single.additionalData?[TraceKeys.correlationId],
        isNotNull,
      );
    });

    test('disabled error fields are not retained', () async {
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          logRequests: false,
          printRequestData: false,
          printRequestHeaders: false,
          printErrorData: false,
          printErrorHeaders: false,
          printErrorMessage: false,
        ),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _ErrorAdapter()
        ..interceptors.add(interceptor);

      try {
        await dio.post<dynamic>(
          '/failure',
          data: '{"password":"request-secret"}',
          options: Options(
            headers: {'Authorization': 'Bearer request-token'},
          ),
        );
      } on DioException {
        // Expected: Dio rejects 5xx responses by default.
      }

      final log = logger.history.single;
      final errorData = _meta(log)[NetworkJsonKeys.errorData] as Map;
      expect(errorData.containsKey(NetworkJsonKeys.message), isFalse);
      expect(errorData.containsKey(NetworkJsonKeys.error), isFalse);
      expect(errorData.containsKey(NetworkJsonKeys.stackTrace), isFalse);
      final response = errorData[NetworkJsonKeys.response] as Map;
      expect(response.containsKey(NetworkJsonKeys.data), isFalse);
      expect(response.containsKey(NetworkJsonKeys.headers), isFalse);
      final request = errorData[NetworkJsonKeys.request] as Map;
      expect(request.containsKey(NetworkJsonKeys.data), isFalse);
      expect(request.containsKey(NetworkJsonKeys.headers), isFalse);
      expect(log.exception, isNull);
      expect(log.error, isNull);
    });

    test('error capture does not inspect a disabled request body', () async {
      var serializationCount = 0;
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
          logRequests: false,
          printRequestData: false,
          printRequestHeaders: false,
          printErrorData: true,
          printErrorHeaders: true,
          printErrorMessage: false,
        ),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/failure',
        data: _SerializationProbe(() => serializationCount++),
        headers: {'Authorization': 'Bearer request-token'},
      );

      final handler = _ObservedErrorHandler();
      final handled = handler.done;
      interceptor.onError(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 500,
            data: const {'errorCode': 'synthetic'},
            headers: Headers()..add('Content-Type', 'application/json'),
          ),
        ),
        handler,
      );
      await handled;

      expect(serializationCount, 0);
      final errorData =
          _meta(logger.history.single)[NetworkJsonKeys.errorData] as Map;
      final response = errorData[NetworkJsonKeys.response] as Map;
      expect(response.containsKey(NetworkJsonKeys.data), isTrue);
      expect(response.containsKey(NetworkJsonKeys.headers), isTrue);
      final responseRequest = response[NetworkJsonKeys.request] as Map;
      expect(responseRequest.containsKey(NetworkJsonKeys.data), isFalse);
      expect(responseRequest.containsKey(NetworkJsonKeys.headers), isFalse);
      final request = errorData[NetworkJsonKeys.request] as Map;
      expect(request.containsKey(NetworkJsonKeys.data), isFalse);
      expect(request.containsKey(NetworkJsonKeys.headers), isFalse);
    });

    test('redacts free-text Dio error metadata and normalizes objects',
        () async {
      const secret = 'DIO-ERROR-METADATA-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _ThrowingAdapter(secret)
        ..interceptors.add(ISpectDioInterceptor(logger: logger));

      try {
        await dio.get<dynamic>('/failure');
      } on DioException {
        // Expected: the synthetic transport fails.
      }

      final log = logger.history
          .firstWhere((entry) => entry.key == ISpectLogType.httpError.key);
      final errorData = _meta(log)[NetworkJsonKeys.errorData] as Map;
      expect(errorData[NetworkJsonKeys.message], isA<String>());
      expect(errorData[NetworkJsonKeys.error], isA<String>());
      expect(errorData[NetworkJsonKeys.stackTrace], isA<String>());
      expect(errorData[NetworkJsonKeys.message], isNot(contains(secret)));
      expect(errorData[NetworkJsonKeys.error], isNot(contains(secret)));
      expect(errorData[NetworkJsonKeys.stackTrace], isNot(contains(secret)));
      expect(log.textMessage, isNot(contains(secret)));
      expect(log.exception?.toString(), isNot(contains(secret)));
      expect(log.error?.toString(), isNot(contains(secret)));
      expect(log.stackTrace?.toString(), isNot(contains(secret)));
    });

    test('uses configured sensitive keys for Dio error metadata', () async {
      const secret = 'DIO-CUSTOM-KEY-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _ThrowingAdapter(
          secret,
          sensitiveKey: 'tenantSecret',
        )
        ..interceptors.add(
          ISpectDioInterceptor(
            logger: logger,
            redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
          ),
        );

      try {
        await dio.get<dynamic>('/failure');
      } on DioException {
        // Expected: the synthetic transport fails.
      }

      final log = logger.history
          .firstWhere((entry) => entry.key == ISpectLogType.httpError.key);
      final errorData = _meta(log)[NetworkJsonKeys.errorData] as Map;
      expect(errorData[NetworkJsonKeys.error], isNot(contains(secret)));
      expect(log.textMessage, isNot(contains(secret)));
      expect(log.exception?.toString(), isNot(contains(secret)));
      expect(log.error?.toString(), isNot(contains(secret)));
      expect(log.stackTrace?.toString(), isNot(contains(secret)));
    });

    test('redacts server-controlled status messages', () {
      const secret = 'DIO-STATUS-MESSAGE-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        redactor: RedactionService(sensitiveKeys: {'tenantSecret'}),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/request',
      );

      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          statusMessage: 'upstream {"tenantSecret":"$secret"}',
        ),
        ResponseInterceptorHandler(),
      );

      final log = logger.history.single;
      final responseData =
          _meta(log)[NetworkJsonKeys.responseData] as Map<String, dynamic>;
      expect(
        responseData[NetworkJsonKeys.statusMessage],
        isNot(contains(secret)),
      );
      expect(log.textMessage, isNot(contains(secret)));
    });

    test('redaction opt-out preserves server-controlled status messages', () {
      const secret = 'DIO-RAW-STATUS-MESSAGE-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(enableRedaction: false),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/request',
      );

      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          statusMessage: 'upstream {"tenantSecret":"$secret"}',
        ),
        ResponseInterceptorHandler(),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData]
              as Map<String, dynamic>;
      expect(
        responseData[NetworkJsonKeys.statusMessage],
        contains(secret),
      );
    });

    test('redaction opt-out preserves a JSON-encoded request body', () {
      const secret = 'DIO-RAW-JSON-SECRET';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
          printRequestData: true,
        ),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/login',
        data: '{"password":"$secret"}',
      );

      interceptor.onRequest(options, RequestInterceptorHandler());

      final requestData =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      expect(requestData[NetworkJsonKeys.data], contains(secret));
    });

    test('redaction opt-out captures request extra DTOs', () {
      final extra = _SensitiveDto('violet-raw-request-extra');
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(enableRedaction: false),
      );
      final options = RequestOptions(
        path: 'https://api.example.com/profile',
        extra: <String, Object?>{'diagnostic': extra},
      );

      interceptor.onRequest(options, RequestInterceptorHandler());

      final requestData =
          _meta(logger.history.single)[NetworkJsonKeys.requestData] as Map;
      final rawExtra = requestData[NetworkJsonKeys.extra] as Map;
      expect(rawExtra['diagnostic'], {
        'password': extra.secret,
        'label': 'visible',
      });
      expect(extra.toJsonCalls, 1);
      expect(extra.toStringCalls, 0);
    });

    test('redaction opt-out captures response DTOs', () {
      final body = _SensitiveDto('violet-raw-response');
      final extra = _SensitiveDto('violet-raw-extra');
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final options = RequestOptions(path: 'https://api.example.com/profile');

      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          enableRedaction: false,
          printResponseData: true,
        ),
      ).onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: body,
          extra: <String, Object?>{'diagnostic': extra},
        ),
        ResponseInterceptorHandler(),
      );

      final responseData =
          _meta(logger.history.single)[NetworkJsonKeys.responseData] as Map;
      final rawExtra = responseData[NetworkJsonKeys.extra] as Map;
      expect(responseData[NetworkJsonKeys.data], {
        'password': body.secret,
        'label': 'visible',
      });
      expect(rawExtra['diagnostic'], {
        'password': extra.secret,
        'label': 'visible',
      });
      expect(body.toJsonCalls, 1);
      expect(body.toStringCalls, 0);
      expect(extra.toJsonCalls, 1);
      expect(extra.toStringCalls, 0);
    });

    test('redaction opt-out snapshots Dio error object metadata', () async {
      const secret = 'DIO-RAW-ERROR-SECRET';
      final adapter = _ThrowingAdapter(secret);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          ISpectDioInterceptor(
            logger: logger,
            settings:
                const ISpectDioInterceptorSettings(enableRedaction: false),
          ),
        );

      try {
        await dio.get<dynamic>('/failure');
      } on DioException {
        // Expected: the synthetic transport fails.
      }

      final log = logger.history
          .firstWhere((entry) => entry.key == ISpectLogType.httpError.key);
      final errorData = _meta(log)[NetworkJsonKeys.errorData] as Map;
      expect(errorData[NetworkJsonKeys.message], contains(secret));
      expect(errorData[NetworkJsonKeys.error], isA<String>());
      expect(errorData[NetworkJsonKeys.stackTrace], isA<String>());
      expect(errorData[NetworkJsonKeys.error], isNot(same(adapter.error)));
      expect(
        errorData[NetworkJsonKeys.stackTrace],
        isNot(same(adapter.stackTrace)),
      );
      expect(log.textMessage, isNot(contains(secret)));
      expect(log.exception, isA<Exception>());
      expect(log.exception, isNot(isA<DioException>()));
      expect(log.exception.toString(), isNot(contains(secret)));
    });
  });
}
