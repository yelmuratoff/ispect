import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/network/network_log_options.dart';
import 'package:ispectify/src/network/network_logs.dart';
import 'package:test/test.dart';

class _TestOptions implements NetworkLogPrintOptions {
  const _TestOptions();

  @override
  bool get printRequestData => true;

  @override
  bool get printRequestHeaders => true;

  @override
  bool get printResponseData => true;

  @override
  bool get printResponseHeaders => true;

  @override
  bool get printResponseMessage => true;

  @override
  bool get printErrorData => true;

  @override
  bool get printErrorHeaders => true;

  @override
  bool get printErrorMessage => true;

  @override
  AnsiPen? get requestPen => null;

  @override
  AnsiPen? get responsePen => null;

  @override
  AnsiPen? get errorPen => null;
}

void main() {
  const options = _TestOptions();

  group('NetworkRequestLog', () {
    test('exposes immutable headers', () {
      final log = NetworkRequestLog(
        'GET /users',
        method: 'GET',
        url: 'https://example.com/users',
        path: '/users',
        settings: options,
        headers: {'Authorization': 'Bearer token'},
      );

      expect(
        () => log.headers!['Authorization'] = 'mutated',
        throwsUnsupportedError,
      );
    });

    test('only includes non-null metadata keys', () {
      final log = NetworkRequestLog(
        'GET /users',
        method: 'GET',
        url: 'https://example.com/users',
        path: '/users',
        settings: options,
      );

      expect(log.additionalData, isNotNull);
      expect(log.additionalData!.keys, containsAll(['method', 'url', 'path']));
      expect(
        log.additionalData!.values.whereType<Object?>(),
        everyElement(isNotNull),
      );
      expect(
        () => log.additionalData!['method'] = 'mutated',
        throwsUnsupportedError,
      );
    });
  });

  group('NetworkErrorLog', () {
    test('surfaces metadata safely', () {
      final log = NetworkErrorLog(
        'Request failed',
        method: 'GET',
        url: 'https://example.com/users',
        path: '/users',
        statusCode: 500,
        statusMessage: 'Internal Server Error',
        settings: options,
        headers: {'content-type': 'application/json'},
      );

      expect(
        log.additionalData!['statusCode'],
        500,
      );
      expect(
        () => log.headers!['content-type'] = 'mutated',
        throwsUnsupportedError,
      );
    });
  });
}
