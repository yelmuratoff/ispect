import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

RedactionService _service(String key, String placeholder) => RedactionService(
      sensitiveKeys: {key},
      sensitiveKeyPatterns: const <RegExp>[],
      fullyMaskedKeys: {key},
      visibleEdgeLength: 0,
      placeholder: placeholder,
    );

ISpectDioInterceptor _interceptor(
  ISpectLogger logger, {
  RedactionService? redactor,
}) =>
    ISpectDioInterceptor(
      logger: logger,
      settings: const ISpectDioInterceptorSettings(
        printRequestData: true,
        printRequestHeaders: true,
      ),
      redactor: redactor,
    );

void _logRequest(
  ISpectDioInterceptor interceptor, {
  required String key,
  required String value,
  String method = 'GET',
  String? contentType,
  Map<String, dynamic>? headers,
}) {
  interceptor.onRequest(
    RequestOptions(
      path: 'https://api.example.test/session',
      data: <String, Object?>{key: value},
      method: method,
      contentType: contentType,
      headers: headers,
    ),
    RequestInterceptorHandler(),
  );
}

String _latestMeta(ISpectLogger logger) =>
    logger.history.last.additionalData?[TraceKeys.meta].toString() ?? '';

void main() {
  group('ISpectDioInterceptor redaction policy', () {
    setUp(ISpectRedaction.reset);
    tearDown(ISpectRedaction.reset);

    test('uses the globally configured redaction service', () {
      const secret = 'DIO-GLOBAL-SECRET';
      final global = _service('tenantSecret', '[DIO-GLOBAL]');
      ISpectRedaction.configure(service: global);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger);

      _logRequest(
        interceptor,
        key: 'tenantSecret',
        value: secret,
        headers: const <String, dynamic>{
          'tenantSecret=DIO-GLOBAL-HEADER-NAME':
              'tenantSecret=DIO-GLOBAL-HEADER-VALUE',
        },
      );

      expect(interceptor.redactor, same(global));
      expect(_latestMeta(logger), contains('[DIO-GLOBAL]'));
      expect(_latestMeta(logger), isNot(contains(secret)));
      expect(
        _latestMeta(logger),
        isNot(contains('DIO-GLOBAL-HEADER-NAME')),
      );
      expect(
        _latestMeta(logger),
        isNot(contains('DIO-GLOBAL-HEADER-VALUE')),
      );
    });

    test('sees global reconfiguration after construction and first use', () {
      final first = _service('firstSecret', '[DIO-FIRST]');
      final second = _service('secondSecret', '[DIO-SECOND]');
      ISpectRedaction.configure(service: first);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger);
      _logRequest(
        interceptor,
        key: 'firstSecret',
        value: 'DIO-FIRST-VALUE',
      );

      ISpectRedaction.configure(service: second);
      _logRequest(
        interceptor,
        key: 'secondSecret',
        value: 'DIO-SECOND-VALUE',
      );

      expect(interceptor.redactor, same(second));
      expect(_latestMeta(logger), contains('[DIO-SECOND]'));
      expect(_latestMeta(logger), isNot(contains('DIO-SECOND-VALUE')));
    });

    test('keeps an explicit redactor pinned for payload and method', () {
      final explicit = _service('tenantSecret', '[DIO-EXPLICIT]');
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const <String>{},
          sensitiveKeyPatterns: const <RegExp>[],
        ),
      );
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger, redactor: explicit);

      ISpectRedaction.configure(
        service: _service('otherSecret', '[DIO-OTHER]'),
      );
      _logRequest(
        interceptor,
        key: 'tenantSecret',
        value: 'DIO-EXPLICIT-VALUE',
        method: 'TRACE tenantSecret=DIO-METHOD-VALUE',
        contentType: 'application/x-test; tenantSecret=DIO-CONTENT-TYPE-VALUE',
        headers: const <String, dynamic>{
          'tenantSecret=DIO-EXPLICIT-HEADER-NAME':
              'tenantSecret=DIO-EXPLICIT-HEADER-VALUE',
        },
      );

      expect(interceptor.redactor, same(explicit));
      expect(_latestMeta(logger), contains('[DIO-EXPLICIT]'));
      expect(_latestMeta(logger), isNot(contains('DIO-EXPLICIT-VALUE')));
      expect(_latestMeta(logger), isNot(contains('DIO-METHOD-VALUE')));
      expect(_latestMeta(logger), isNot(contains('DIO-CONTENT-TYPE-VALUE')));
      expect(
        _latestMeta(logger),
        isNot(contains('DIO-EXPLICIT-HEADER-NAME')),
      );
      expect(
        _latestMeta(logger),
        isNot(contains('DIO-EXPLICIT-HEADER-VALUE')),
      );
      expect(
        logger.history.last.additionalData?[TraceKeys.operation],
        contains('[DIO-EXPLICIT]'),
      );
      expect(
        logger.history.last.additionalData?[TraceKeys.operation],
        isNot(contains('DIO-METHOD-VALUE')),
      );
    });

    test('global disable overrides an explicit redactor', () {
      const secret = 'DIO-GLOBALLY-DISABLED';
      final explicit = _service('tenantSecret', '[DIO-EXPLICIT]');
      ISpectRedaction.configure(enabled: false);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger, redactor: explicit);

      _logRequest(
        interceptor,
        key: 'tenantSecret',
        value: secret,
        headers: const <String, dynamic>{
          'tenantSecret=DIO-GLOBAL-DISABLE-HEADER-NAME':
              'tenantSecret=DIO-GLOBAL-DISABLE-HEADER-VALUE',
        },
      );

      expect(_latestMeta(logger), contains(secret));
      expect(
        _latestMeta(logger),
        contains('DIO-GLOBAL-DISABLE-HEADER-NAME'),
      );
      expect(
        _latestMeta(logger),
        contains('DIO-GLOBAL-DISABLE-HEADER-VALUE'),
      );
      expect(_latestMeta(logger), isNot(contains('[DIO-EXPLICIT]')));
    });

    test('redacts names and free-text values with the default policy', () {
      const rawName = 'sk-DIOHEADERNAMESECRET123456';
      const rawValue = 'password=DIO-ARBITRARY-HEADER-VALUE';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      _logRequest(
        _interceptor(logger),
        key: 'safe',
        value: 'visible',
        headers: const <String, dynamic>{rawName: rawValue},
      );

      expect(_latestMeta(logger), isNot(contains(rawName)));
      expect(
        _latestMeta(logger),
        isNot(contains('DIO-ARBITRARY-HEADER-VALUE')),
      );
    });

    test('preserves raw header names only for the integration opt-out', () {
      const rawName = 'email=raw.dio.person@example.test';
      const rawValue = 'password=RAW-DIO-HEADER-VALUE';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printRequestData: true,
          printRequestHeaders: true,
          enableRedaction: false,
        ),
      );

      _logRequest(
        interceptor,
        key: 'safe',
        value: 'visible',
        headers: const <String, dynamic>{rawName: rawValue},
      );

      expect(_latestMeta(logger), contains(rawName));
      expect(_latestMeta(logger), contains(rawValue));
    });

    test('redacts every method copy in response and error metadata', () async {
      final explicit = _service('tenantSecret', '[DIO-METHOD]');
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger, redactor: explicit);

      for (final isError in [false, true]) {
        final method = isError
            ? 'TRACE tenantSecret=DIO-ERROR-METHOD'
            : 'TRACE tenantSecret=DIO-RESPONSE-METHOD';
        final options = RequestOptions(
          path: 'https://api.example.test/session',
          method: method,
          contentType:
              'application/x-test; tenantSecret=DIO-CONTENT-TYPE-$isError',
          headers: <String, dynamic>{
            'tenantSecret=DIO-NESTED-HEADER-NAME-$isError':
                'tenantSecret=DIO-NESTED-HEADER-VALUE-$isError',
          },
        );
        if (isError) {
          final handler = _ConsumingErrorInterceptorHandler();
          final completion = handler.consume();
          interceptor.onError(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 500,
              ),
            ),
            handler,
          );
          await completion;
        } else {
          interceptor.onResponse(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
            ),
            ResponseInterceptorHandler(),
          );
        }

        final serializedLog = logger.history.last.additionalData.toString();
        expect(serializedLog, contains('[DIO-METHOD]'));
        expect(serializedLog, isNot(contains(method.split('=').last)));
        expect(
          serializedLog,
          isNot(contains('DIO-CONTENT-TYPE-$isError')),
        );
        expect(
          serializedLog,
          isNot(contains('DIO-NESTED-HEADER-NAME-$isError')),
        );
        expect(
          serializedLog,
          isNot(contains('DIO-NESTED-HEADER-VALUE-$isError')),
        );
      }
    });

    test('active redaction replaces oversized FormData fields before masking',
        () {
      const prefix = 'DIO-OVERSIZED-FIELD-SECRET';
      final formData = FormData()
        ..fields.add(
          MapEntry(
            'notes',
            '$prefix${'x' * (LogExportOutput.maxPreparedValueBytes * 2)}',
          ),
        );
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      _interceptor(logger).onRequest(
        RequestOptions(
          path: 'https://api.example.test/upload',
          data: formData,
        ),
        RequestInterceptorHandler(),
      );

      expect(_latestMeta(logger), contains(LogExportOutput.truncatedMarker));
      expect(_latestMeta(logger), isNot(contains(prefix)));
    });
  });
}

final class _ConsumingErrorInterceptorHandler extends ErrorInterceptorHandler {
  Future<void> consume() async {
    try {
      await future;
    } on Object {
      return;
    }
  }
}
