import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:test/test.dart';

Object? _decodeOrder(http.Response response) =>
    <String, Object?>{'orderId': response.bodyBytes.first, 'token': 'tok-1'};

void main() {
  group('ISpectHttpInterceptorSettings.responseDataConverter', () {
    late ISpectLogger logger;

    setUp(() {
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      );
    });

    InterceptedClient client(
      ISpectHttpInterceptorSettings settings, {
      int statusCode = 200,
    }) =>
        InterceptedClient.build(
          interceptors: [
            ISpectHttpInterceptor(logger: logger, settings: settings),
          ],
          client: MockClient(
            (request) async => http.Response.bytes(
              [7, 0, 255],
              statusCode,
              headers: {'content-type': 'application/x-protobuf'},
              request: request,
            ),
          ),
        );

    Map<String, dynamic> loggedBody(String typeKey, String dataKey) {
      final log = logger.history.lastWhere((l) => l.key == typeKey);
      final meta = log.additionalData![TraceKeys.meta] as Map<String, dynamic>;
      return (meta[dataKey] as Map<String, dynamic>)['body']
          as Map<String, dynamic>;
    }

    test('logs the converted value instead of the raw bytes', () async {
      await client(
        const ISpectHttpInterceptorSettings(
          enableRedaction: false,
          responseDataConverter: _decodeOrder,
        ),
      ).get(Uri.parse('https://api.example.com/orders/7'));

      expect(
        loggedBody(ISpectLogType.httpResponse.key, 'response-data'),
        {'orderId': 7, 'token': 'tok-1'},
      );
    });

    test('redacts the converted value like any captured body', () async {
      await client(
        const ISpectHttpInterceptorSettings(
          responseDataConverter: _decodeOrder,
        ),
      ).get(Uri.parse('https://api.example.com/orders/7'));

      final body = loggedBody(ISpectLogType.httpResponse.key, 'response-data');
      expect(body['orderId'], 7);
      expect(body['token'], isNot('tok-1'));
    });

    test('converts error responses too', () async {
      await client(
        const ISpectHttpInterceptorSettings(
          enableRedaction: false,
          responseDataConverter: _decodeOrder,
        ),
        statusCode: 422,
      ).get(Uri.parse('https://api.example.com/orders/7'));

      expect(
        loggedBody(ISpectLogType.httpError.key, 'error-data'),
        {'orderId': 7, 'token': 'tok-1'},
      );
    });

    Object? rawBody(String typeKey, String dataKey) {
      final log = logger.history.singleWhere((l) => l.key == typeKey);
      final meta = log.additionalData![TraceKeys.meta] as Map<String, dynamic>;
      return (meta[dataKey] as Map<String, dynamic>)['body'];
    }

    ISpectHttpInterceptorSettings throwingSettings() =>
        ISpectHttpInterceptorSettings(
          responseDataConverter: (_) =>
              throw const FormatException('secret payload'),
        );

    void expectConverterWarning() {
      final warning = logger.history.singleWhere(
        (l) => l.logLevel == LogLevel.warning,
      );
      expect(warning.message, contains('FormatException'));
      expect(warning.message, isNot(contains('secret payload')));
    }

    test('a failing converter keeps the response with a placeholder body',
        () async {
      final response = await client(throwingSettings())
          .get(Uri.parse('https://api.example.com/orders/7'));

      expect(response.bodyBytes, [7, 0, 255]);
      expectConverterWarning();
      expect(
        rawBody(ISpectLogType.httpResponse.key, 'response-data'),
        LogExportOutput.truncatedMarker,
      );
    });

    test('a failing converter keeps the error log of a failed request',
        () async {
      await client(throwingSettings(), statusCode: 502)
          .get(Uri.parse('https://api.example.com/orders/7'));

      expectConverterWarning();
      expect(
        rawBody(ISpectLogType.httpError.key, 'error-data'),
        LogExportOutput.truncatedMarker,
      );
    });

    test('the builder and copyWith carry the converter', () {
      final built = ISpectHttpInterceptorSettingsBuilder()
          .withResponseDataConverter(_decodeOrder)
          .build();

      expect(built.responseDataConverter, same(_decodeOrder));
      expect(
        const ISpectHttpInterceptorSettings()
            .copyWith(responseDataConverter: _decodeOrder)
            .responseDataConverter,
        same(_decodeOrder),
      );
    });
  });
}
