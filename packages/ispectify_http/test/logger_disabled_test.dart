import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

final class _CountingRedactor extends RedactionService {
  int calls = 0;

  @override
  String redactUrl(String url) {
    calls++;
    return super.redactUrl(url);
  }
}

final class _DisablingRedactor extends RedactionService {
  _DisablingRedactor(this.onRedact);

  final void Function() onRedact;
  int calls = 0;

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    calls++;
    onRedact();
    return super.redactForExport(
      data,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }
}

final class _ReadCountingRequest extends http.Request {
  _ReadCountingRequest(super.method, super.url);

  int bodyReads = 0;

  @override
  Uint8List get bodyBytes {
    bodyReads++;
    return super.bodyBytes;
  }
}

void main() {
  setUp(ISpectRedaction.reset);
  tearDown(ISpectRedaction.reset);

  test('disabled logger bypasses capture, filters, and redaction', () async {
    var requestFilterCalls = 0;
    var responseFilterCalls = 0;
    var errorFilterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(
        enabled: false,
        useConsoleLogs: false,
      ),
    );
    final interceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectHttpInterceptorSettings(
        requestChain: NetworkFilterChain<http.BaseRequest>.fromPredicate((_) {
          requestFilterCalls++;
          return true;
        }),
        responseChain: NetworkFilterChain<http.BaseResponse>.fromPredicate((_) {
          responseFilterCalls++;
          return true;
        }),
        errorChain: NetworkFilterChain<http.BaseResponse>.fromPredicate((_) {
          errorFilterCalls++;
          return true;
        }),
      ),
    );
    final request = http.Request(
      'GET',
      Uri.parse('https://api.example.test/users?token=secret'),
    );
    final response = http.Response('', 200, request: request);
    final errorResponse = http.Response('', 500, request: request);

    expect(
      await interceptor.shouldInterceptRequest(request: request),
      isFalse,
    );
    expect(
      await interceptor.shouldInterceptResponse(response: response),
      isFalse,
    );
    expect(
      await interceptor.interceptRequest(request: request),
      same(request),
    );
    expect(
      await interceptor.interceptResponse(response: response),
      same(response),
    );
    expect(
      await interceptor.interceptResponse(response: errorResponse),
      same(errorResponse),
    );

    expect(logger.history, isEmpty);
    expect(requestFilterCalls, 0);
    expect(responseFilterCalls, 0);
    expect(errorFilterCalls, 0);
    expect(redactor.calls, 0);
  });

  test('enabled logger without consumers bypasses request capture', () async {
    var filterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);
    final interceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectHttpInterceptorSettings(
        requestChain: NetworkFilterChain<http.BaseRequest>.fromPredicate((_) {
          filterCalls++;
          return true;
        }),
      ),
    );
    final request = _ReadCountingRequest(
      'POST',
      Uri.parse('https://api.example.test/users?token=secret'),
    )..body = '{"token":"secret"}';
    final readsBeforeCapture = request.bodyReads;

    expect(
      await interceptor.interceptRequest(request: request),
      same(request),
    );

    expect(logger.history, isEmpty);
    expect(filterCalls, 0);
    expect(redactor.calls, 0);
    expect(request.bodyReads, readsBeforeCapture);
  });

  test('disposed logger bypasses capture before inspecting request', () async {
    var filterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectHttpInterceptorSettings(
        requestChain: NetworkFilterChain<http.BaseRequest>.fromPredicate((_) {
          filterCalls++;
          return true;
        }),
      ),
    );
    final request = http.Request(
      'GET',
      Uri.parse('https://api.example.test/users?token=secret'),
    );

    await logger.dispose();

    expect(
      await interceptor.shouldInterceptRequest(request: request),
      isFalse,
    );
    expect(
      await interceptor.interceptRequest(request: request),
      same(request),
    );
    expect(filterCalls, 0);
    expect(redactor.calls, 0);
  });

  test('request predicate can disable request logging before inspection',
      () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final redactor = _CountingRedactor();
    late final ISpectHttpInterceptor interceptor;
    interceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectHttpInterceptorSettings(
        requestChain: NetworkFilterChain<http.BaseRequest>.fromPredicate((_) {
          interceptor.applyConfigurableSettings(
            const ISpectHttpInterceptorSettings(logRequests: false),
          );
          return true;
        }),
      ),
    );
    final request = http.Request(
      'GET',
      Uri.parse('https://api.example.test/users?token=secret'),
    );

    expect(
      await interceptor.interceptRequest(request: request),
      same(request),
    );
    expect(logger.history, isEmpty);
    expect(redactor.calls, 0);
  });

  test('redactor kill switch stops before request payload inspection',
      () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    late final ISpectHttpInterceptor interceptor;
    final redactor = _DisablingRedactor(() {
      interceptor.applyConfigurableSettings(
        const ISpectHttpInterceptorSettings(enabled: false),
      );
    });
    interceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
    );
    final request = _ReadCountingRequest(
      'POST',
      Uri.parse('https://api.example.test/users?token=secret'),
    )..body = '{"token":"secret"}';
    final readsBeforeCapture = request.bodyReads;

    expect(
      await interceptor.interceptRequest(request: request),
      same(request),
    );

    expect(logger.history, isEmpty);
    expect(redactor.calls, 1);
    expect(request.bodyReads, readsBeforeCapture);
  });

  test('redactor kill switch stops before response and error payload reads',
      () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);

    late final ISpectHttpInterceptor responseInterceptor;
    final responseRedactor = _DisablingRedactor(() {
      responseInterceptor.applyConfigurableSettings(
        const ISpectHttpInterceptorSettings(logResponses: false),
      );
    });
    responseInterceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: responseRedactor,
    );
    final responseRequest = _ReadCountingRequest(
      'GET',
      Uri.parse('https://api.example.test/users?token=secret'),
    )..body = '{"token":"secret"}';
    final responseReadsBeforeCapture = responseRequest.bodyReads;
    final response = http.Response('', 200, request: responseRequest);

    expect(
      await responseInterceptor.interceptResponse(response: response),
      same(response),
    );

    late final ISpectHttpInterceptor errorInterceptor;
    final errorRedactor = _DisablingRedactor(() {
      errorInterceptor.applyConfigurableSettings(
        const ISpectHttpInterceptorSettings(enabled: false),
      );
    });
    errorInterceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: errorRedactor,
    );
    final errorRequest = _ReadCountingRequest(
      'GET',
      Uri.parse('https://api.example.test/users?token=secret'),
    )..body = '{"token":"secret"}';
    final errorReadsBeforeCapture = errorRequest.bodyReads;
    final errorResponse = http.Response('', 500, request: errorRequest);

    expect(
      await errorInterceptor.interceptResponse(response: errorResponse),
      same(errorResponse),
    );

    expect(logger.history, isEmpty);
    expect(responseRedactor.calls, 1);
    expect(errorRedactor.calls, 1);
    expect(responseRequest.bodyReads, responseReadsBeforeCapture);
    expect(errorRequest.bodyReads, errorReadsBeforeCapture);
  });

  test('response and error predicates can disable capture before inspection',
      () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final redactor = _CountingRedactor();
    final request = http.Request(
      'GET',
      Uri.parse('https://api.example.test/users?token=secret'),
    );

    late final ISpectHttpInterceptor responseInterceptor;
    responseInterceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectHttpInterceptorSettings(
        responseChain: NetworkFilterChain<http.BaseResponse>.fromPredicate((_) {
          responseInterceptor.applyConfigurableSettings(
            const ISpectHttpInterceptorSettings(logResponses: false),
          );
          return true;
        }),
      ),
    );
    final response = http.Response('', 200, request: request);
    expect(
      await responseInterceptor.interceptResponse(response: response),
      same(response),
    );

    late final ISpectHttpInterceptor errorInterceptor;
    errorInterceptor = ISpectHttpInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectHttpInterceptorSettings(
        errorChain: NetworkFilterChain<http.BaseResponse>.fromPredicate((_) {
          errorInterceptor.applyConfigurableSettings(
            const ISpectHttpInterceptorSettings(enabled: false),
          );
          return true;
        }),
      ),
    );
    final errorResponse = http.Response('', 500, request: request);
    expect(
      await errorInterceptor.interceptResponse(response: errorResponse),
      same(errorResponse),
    );

    expect(logger.history, isEmpty);
    expect(redactor.calls, 0);
  });
}
