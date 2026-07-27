import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
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

final class _ReadCountingMap extends MapBase<String, Object?> {
  _ReadCountingMap(this._values);

  final Map<String, Object?> _values;
  int reads = 0;

  @override
  Object? operator [](Object? key) {
    reads++;
    return _values[key];
  }

  @override
  void operator []=(String key, Object? value) {
    _values[key] = value;
  }

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys {
    reads++;
    return _values.keys;
  }

  @override
  Object? remove(Object? key) => _values.remove(key);
}

final class _ObservedErrorHandler extends ErrorInterceptorHandler {
  Future<void> get done async {
    try {
      await future;
    } on Object {
      return;
    }
  }
}

void main() {
  setUp(ISpectRedaction.reset);
  tearDown(ISpectRedaction.reset);

  test('disabled logger bypasses capture, filters, and request mutation',
      () async {
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
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectDioInterceptorSettings(
        requestChain: NetworkFilterChain<RequestOptions>.fromPredicate((_) {
          requestFilterCalls++;
          return true;
        }),
        responseChain: NetworkFilterChain<Response<dynamic>>.fromPredicate((_) {
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
      path: 'https://api.example.test/users?token=secret',
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
    expect(requestFilterCalls, 0);
    expect(responseFilterCalls, 0);
    expect(errorFilterCalls, 0);
    expect(redactor.calls, 0);
    expect(options.extra, {'existing': 'value'});
  });

  test('enabled logger without consumers bypasses request capture', () {
    var filterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        useHistory: false,
      ),
    );
    addTearDown(logger.dispose);
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectDioInterceptorSettings(
        requestChain: NetworkFilterChain<RequestOptions>.fromPredicate((_) {
          filterCalls++;
          return true;
        }),
      ),
    );
    final payload = _ReadCountingMap({'token': 'secret'});
    final options = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
      data: payload,
      extra: {'existing': 'value'},
    );
    final readsBeforeCapture = payload.reads;

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(logger.history, isEmpty);
    expect(filterCalls, 0);
    expect(redactor.calls, 0);
    expect(payload.reads, readsBeforeCapture);
    expect(options.extra, {'existing': 'value'});
  });

  test('disposed logger bypasses capture before inspecting request', () async {
    var filterCalls = 0;
    final redactor = _CountingRedactor();
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectDioInterceptorSettings(
        requestChain: NetworkFilterChain<RequestOptions>.fromPredicate((_) {
          filterCalls++;
          return true;
        }),
      ),
    );
    final options = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
      extra: {'existing': 'value'},
    );

    await logger.dispose();
    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(filterCalls, 0);
    expect(redactor.calls, 0);
    expect(options.extra, {'existing': 'value'});
  });

  test('request predicate can disable request logging before inspection', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final redactor = _CountingRedactor();
    late final ISpectDioInterceptor interceptor;
    interceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectDioInterceptorSettings(
        requestChain: NetworkFilterChain<RequestOptions>.fromPredicate((_) {
          interceptor.applyConfigurableSettings(
            const ISpectDioInterceptorSettings(logRequests: false),
          );
          return true;
        }),
      ),
    );
    final options = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
      extra: {'existing': 'value'},
    );

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(logger.history, isEmpty);
    expect(redactor.calls, 0);
    expect(options.extra['existing'], 'value');
  });

  test('redactor kill switch stops before request payload inspection', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    late final ISpectDioInterceptor interceptor;
    final redactor = _DisablingRedactor(() {
      interceptor.applyConfigurableSettings(
        const ISpectDioInterceptorSettings(enabled: false),
      );
    });
    interceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
    );
    final payload = _ReadCountingMap({'token': 'secret'});
    final options = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
      data: payload,
    );
    final readsBeforeCapture = payload.reads;

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(logger.history, isEmpty);
    expect(redactor.calls, 1);
    expect(payload.reads, readsBeforeCapture);
  });

  test('redactor kill switch stops before response and error payload reads',
      () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);

    late final ISpectDioInterceptor responseInterceptor;
    final responseRedactor = _DisablingRedactor(() {
      responseInterceptor.applyConfigurableSettings(
        const ISpectDioInterceptorSettings(logResponses: false),
      );
    });
    responseInterceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: responseRedactor,
    );
    final responsePayload = _ReadCountingMap({'token': 'secret'});
    final responseOptions = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
    );
    final responseReadsBeforeCapture = responsePayload.reads;

    responseInterceptor.onResponse(
      Response<dynamic>(
        requestOptions: responseOptions,
        statusCode: 200,
        data: responsePayload,
      ),
      ResponseInterceptorHandler(),
    );

    late final ISpectDioInterceptor errorInterceptor;
    final errorRedactor = _DisablingRedactor(() {
      errorInterceptor.applyConfigurableSettings(
        const ISpectDioInterceptorSettings(enabled: false),
      );
    });
    errorInterceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: errorRedactor,
    );
    final errorPayload = _ReadCountingMap({'token': 'secret'});
    final errorOptions = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
    );
    final errorReadsBeforeCapture = errorPayload.reads;
    final errorHandler = _ObservedErrorHandler();
    final errorHandled = errorHandler.done;

    errorInterceptor.onError(
      DioException(
        requestOptions: errorOptions,
        response: Response<dynamic>(
          requestOptions: errorOptions,
          statusCode: 500,
          data: errorPayload,
        ),
      ),
      errorHandler,
    );
    await errorHandled;

    expect(logger.history, isEmpty);
    expect(responseRedactor.calls, 1);
    expect(errorRedactor.calls, 1);
    expect(responsePayload.reads, responseReadsBeforeCapture);
    expect(errorPayload.reads, errorReadsBeforeCapture);
  });

  test('response and error predicates can disable capture before inspection',
      () async {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    addTearDown(logger.dispose);
    final redactor = _CountingRedactor();
    late final ISpectDioInterceptor responseInterceptor;
    responseInterceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectDioInterceptorSettings(
        responseChain: NetworkFilterChain<Response<dynamic>>.fromPredicate((_) {
          responseInterceptor.applyConfigurableSettings(
            const ISpectDioInterceptorSettings(logResponses: false),
          );
          return true;
        }),
      ),
    );
    final options = RequestOptions(
      path: 'https://api.example.test/users?token=secret',
    );
    responseInterceptor.onResponse(
      Response<dynamic>(requestOptions: options, statusCode: 200),
      ResponseInterceptorHandler(),
    );

    late final ISpectDioInterceptor errorInterceptor;
    errorInterceptor = ISpectDioInterceptor(
      logger: logger,
      redactor: redactor,
      settings: ISpectDioInterceptorSettings(
        errorChain: NetworkFilterChain<DioException>.fromPredicate((_) {
          errorInterceptor.applyConfigurableSettings(
            const ISpectDioInterceptorSettings(enabled: false),
          );
          return true;
        }),
      ),
    );
    final errorHandler = _ObservedErrorHandler();
    final errorHandled = errorHandler.done;
    errorInterceptor.onError(
      DioException(requestOptions: options),
      errorHandler,
    );
    await errorHandled;

    expect(logger.history, isEmpty);
    expect(redactor.calls, 0);
  });
}
