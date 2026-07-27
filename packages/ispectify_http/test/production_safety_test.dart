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

void main() {
  test(
    'omitted flag bypasses capture, filters, and redaction',
    () async {
      var requestFilterCalls = 0;
      var responseFilterCalls = 0;
      var errorFilterCalls = 0;
      final redactor = _CountingRedactor();
      final logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
      final interceptor = ISpectHttpInterceptor(
        logger: logger,
        redactor: redactor,
        settings: ISpectHttpInterceptorSettings(
          requestChain: NetworkFilterChain<http.BaseRequest>.fromPredicate((_) {
            requestFilterCalls++;
            return true;
          }),
          responseChain:
              NetworkFilterChain<http.BaseResponse>.fromPredicate((_) {
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
        Uri.parse('https://api.example.com/users?token=synthetic-secret'),
      );
      final response = http.Response(
        '{"password":"synthetic-secret"}',
        200,
        request: request,
      );
      final errorResponse = http.Response(
        '{"password":"synthetic-secret"}',
        500,
        request: request,
      );

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
    },
    skip: kISpectEnabled
        ? 'This regression test must run without ISPECT_ENABLED.'
        : false,
  );
}
