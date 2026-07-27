import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

RedactionService _service(String key, String placeholder) => RedactionService(
      sensitiveKeys: {key},
      sensitiveKeyPatterns: const <RegExp>[],
      fullyMaskedKeys: {key},
      visibleEdgeLength: 0,
      placeholder: placeholder,
    );

ISpectHttpInterceptor _interceptor(
  ISpectLogger logger, {
  RedactionService? redactor,
}) =>
    ISpectHttpInterceptor(
      logger: logger,
      settings: const ISpectHttpInterceptorSettings(
        printRequestData: true,
        printRequestHeaders: true,
      ),
      redactor: redactor,
    );

Future<void> _logRequest(
  ISpectHttpInterceptor interceptor, {
  required String key,
  required String value,
  String method = 'POST',
  Encoding? encoding,
  Map<String, String>? headers,
}) async {
  final request = http.Request(
    method,
    Uri.parse('https://api.example.test/session'),
  );
  if (encoding != null) request.encoding = encoding;
  if (headers != null) request.headers.addAll(headers);
  request.bodyBytes = utf8.encode('{"$key":"$value"}');
  await interceptor.interceptRequest(request: request);
}

String _latestMeta(ISpectLogger logger) =>
    logger.history.last.additionalData?[TraceKeys.meta].toString() ?? '';

void main() {
  group('ISpectHttpInterceptor redaction policy', () {
    setUp(ISpectRedaction.reset);
    tearDown(ISpectRedaction.reset);

    test('uses the globally configured redaction service', () async {
      const secret = 'HTTP-GLOBAL-SECRET';
      final global = _service('tenantSecret', '[HTTP-GLOBAL]');
      ISpectRedaction.configure(service: global);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger);

      await _logRequest(
        interceptor,
        key: 'tenantSecret',
        value: secret,
        headers: const <String, String>{
          'tenantSecret=HTTP-GLOBAL-HEADER-NAME':
              'tenantSecret=HTTP-GLOBAL-HEADER-VALUE',
        },
      );

      expect(interceptor.redactor, same(global));
      expect(_latestMeta(logger), contains('[HTTP-GLOBAL]'));
      expect(_latestMeta(logger), isNot(contains(secret)));
      expect(
        _latestMeta(logger),
        isNot(contains('HTTP-GLOBAL-HEADER-NAME')),
      );
      expect(
        _latestMeta(logger),
        isNot(contains('HTTP-GLOBAL-HEADER-VALUE')),
      );
    });

    test('sees global reconfiguration after construction and first use',
        () async {
      final first = _service('firstSecret', '[HTTP-FIRST]');
      final second = _service('secondSecret', '[HTTP-SECOND]');
      ISpectRedaction.configure(service: first);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger);
      await _logRequest(
        interceptor,
        key: 'firstSecret',
        value: 'HTTP-FIRST-VALUE',
      );

      ISpectRedaction.configure(service: second);
      await _logRequest(
        interceptor,
        key: 'secondSecret',
        value: 'HTTP-SECOND-VALUE',
      );

      expect(interceptor.redactor, same(second));
      expect(_latestMeta(logger), contains('[HTTP-SECOND]'));
      expect(_latestMeta(logger), isNot(contains('HTTP-SECOND-VALUE')));
    });

    test('keeps an explicit redactor pinned for payload and method', () async {
      final explicit = _service('tenantSecret', '[HTTP-EXPLICIT]');
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
        service: _service('otherSecret', '[HTTP-OTHER]'),
      );
      await _logRequest(
        interceptor,
        key: 'tenantSecret',
        value: 'HTTP-EXPLICIT-VALUE',
        method: 'sk-HTTP-METHOD-VALUE',
        encoding: const _NamedEncoding('tenantSecret=HTTP-ENCODING-VALUE'),
        headers: const <String, String>{
          'tenantSecret=HTTP-EXPLICIT-HEADER-NAME':
              'tenantSecret=HTTP-EXPLICIT-HEADER-VALUE',
        },
      );

      expect(interceptor.redactor, same(explicit));
      expect(_latestMeta(logger), contains('[HTTP-EXPLICIT]'));
      expect(_latestMeta(logger), isNot(contains('HTTP-EXPLICIT-VALUE')));
      expect(_latestMeta(logger), isNot(contains('HTTP-METHOD-VALUE')));
      expect(_latestMeta(logger), isNot(contains('HTTP-ENCODING-VALUE')));
      expect(
        _latestMeta(logger),
        isNot(contains('HTTP-EXPLICIT-HEADER-NAME')),
      );
      expect(
        _latestMeta(logger),
        isNot(contains('HTTP-EXPLICIT-HEADER-VALUE')),
      );
      expect(
        logger.history.last.additionalData?[TraceKeys.operation],
        contains('[HTTP-EXPLICIT]'),
      );
      expect(
        logger.history.last.additionalData?[TraceKeys.operation],
        isNot(contains('HTTP-METHOD-VALUE')),
      );
    });

    test('global disable overrides an explicit redactor', () async {
      const secret = 'HTTP-GLOBALLY-DISABLED';
      final explicit = _service('tenantSecret', '[HTTP-EXPLICIT]');
      ISpectRedaction.configure(enabled: false);
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger, redactor: explicit);

      await _logRequest(
        interceptor,
        key: 'tenantSecret',
        value: secret,
        encoding: const _NamedEncoding('token=HTTP-RAW-ENCODING'),
        headers: const <String, String>{
          'tenantSecret=HTTP-GLOBAL-DISABLE-HEADER-NAME':
              'tenantSecret=HTTP-GLOBAL-DISABLE-HEADER-VALUE',
        },
      );

      expect(_latestMeta(logger), contains(secret));
      expect(_latestMeta(logger), contains('HTTP-RAW-ENCODING'));
      expect(
        _latestMeta(logger),
        contains('HTTP-GLOBAL-DISABLE-HEADER-NAME'),
      );
      expect(
        _latestMeta(logger),
        contains('HTTP-GLOBAL-DISABLE-HEADER-VALUE'),
      );
      expect(_latestMeta(logger), isNot(contains('[HTTP-EXPLICIT]')));
    });

    test('redacts names and free-text values with the default policy',
        () async {
      const rawName = 'sk-HTTPHEADERNAMESECRET123456';
      const rawValue = 'password=HTTP-ARBITRARY-HEADER-VALUE';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );

      await _logRequest(
        _interceptor(logger),
        key: 'safe',
        value: 'visible',
        headers: const <String, String>{rawName: rawValue},
      );

      expect(_latestMeta(logger), isNot(contains(rawName)));
      expect(
        _latestMeta(logger),
        isNot(contains('HTTP-ARBITRARY-HEADER-VALUE')),
      );
    });

    test('preserves raw header names only for the integration opt-out',
        () async {
      const rawName = 'email=raw.http.person@example.test';
      const rawValue = 'password=RAW-HTTP-HEADER-VALUE';
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        settings: const ISpectHttpInterceptorSettings(
          printRequestData: true,
          printRequestHeaders: true,
          enableRedaction: false,
        ),
      );

      await _logRequest(
        interceptor,
        key: 'safe',
        value: 'visible',
        headers: const <String, String>{rawName: rawValue},
      );

      expect(_latestMeta(logger), contains(rawName));
      expect(_latestMeta(logger), contains(rawValue));
    });

    test('redacts every method copy in response and error metadata', () async {
      final explicit = _service('tenantSecret', '[HTTP-METHOD]');
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = _interceptor(logger, redactor: explicit);

      for (final statusCode in [200, 500]) {
        final method = statusCode == 200
            ? 'sk-HTTP-RESPONSE-METHOD'
            : 'sk-HTTP-ERROR-METHOD';
        final request = http.Request(
          method,
          Uri.parse('https://api.example.test/session'),
        )
          ..encoding = _NamedEncoding(
            'tenantSecret=HTTP-ENCODING-$statusCode',
          )
          ..headers.addAll(
            <String, String>{
              'tenantSecret=HTTP-NESTED-HEADER-NAME-$statusCode':
                  'tenantSecret=HTTP-NESTED-HEADER-VALUE-$statusCode',
            },
          );
        await interceptor.interceptRequest(request: request);
        await interceptor.interceptResponse(
          response: http.Response(
            '',
            statusCode,
            request: request,
          ),
        );

        final serializedLog = logger.history.last.additionalData.toString();
        expect(serializedLog, contains('[HTTP-METHOD]'));
        expect(serializedLog, isNot(contains(method)));
        expect(
          serializedLog,
          isNot(contains('HTTP-ENCODING-$statusCode')),
        );
        expect(
          serializedLog,
          isNot(contains('HTTP-NESTED-HEADER-NAME-$statusCode')),
        );
        expect(
          serializedLog,
          isNot(contains('HTTP-NESTED-HEADER-VALUE-$statusCode')),
        );
      }
    });
  });
}

final class _NamedEncoding extends Encoding {
  const _NamedEncoding(this.name);

  @override
  final String name;

  @override
  Converter<List<int>, String> get decoder => utf8.decoder;

  @override
  Converter<String, List<int>> get encoder => utf8.encoder;
}
