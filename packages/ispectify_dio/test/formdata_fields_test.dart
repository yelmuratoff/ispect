import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

void main() {
  test('preserves duplicate form fields in request data', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      settings: const ISpectDioInterceptorSettings(
        enableRedaction: false,
      ),
    );

    final options = RequestOptions(path: 'https://upload.example.com');
    final formData = FormData();
    formData.fields
      ..add(const MapEntry('tags[]', 'a'))
      ..add(const MapEntry('tags[]', 'b'))
      ..add(const MapEntry('single', 'one'))
      ..add(const MapEntry('single', 'two'));
    options.data = formData;

    final response = Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: 'ok',
    );

    interceptor.onResponse(response, ResponseInterceptorHandler());

    final log = logger.history.last;
    expect(log.key, ISpectLogType.httpResponse.key);
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    expect(meta, isNotNull);
    // requestData contains the full request JSON including FormData
    final requestData = meta?['response-data'] as Map?;
    final request = requestData?['request'] as Map?;
    final data = request?['data'] as Map?;
    expect(data, isNotNull);
    final fields = data?['fields'] as Map?;
    expect(fields?['tags[]'], isA<List<dynamic>>());
    expect((fields?['tags[]'] as List).length, 2);
  });

  test('response with FormData is logged', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      settings: const ISpectDioInterceptorSettings(
        enableRedaction: false,
      ),
    );

    final options = RequestOptions(path: 'https://upload.example.com');
    final responseForm = FormData();
    responseForm.fields
      ..add(const MapEntry('ids', '1'))
      ..add(const MapEntry('ids', '2'));

    final response = Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: responseForm,
    );

    interceptor.onResponse(response, ResponseInterceptorHandler());

    final log = logger.history.last;
    expect(log.key, ISpectLogType.httpResponse.key);
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    expect(meta?['status-code'], 200);
    // FormData response body is stored as-is in responseData.data
    final responseData = meta?['response-data'] as Map?;
    expect(responseData, isNotNull);
    // data is a FormData — it's not serialized to Map by DioResponseData.toJson()
    expect(responseData?['data'], isA<FormData>());
  });

  test('request FormData is properly extracted and logged', () {
    final logger = ISpectLogger(
      options: ISpectLoggerOptions(useConsoleLogs: false),
    );
    final interceptor = ISpectDioInterceptor(
      logger: logger,
      settings: const ISpectDioInterceptorSettings(
        enableRedaction: false,
      ),
    );

    final options = RequestOptions(path: 'https://upload.example.com');
    final formData = FormData();
    formData.fields
      ..add(const MapEntry('username', 'john_doe'))
      ..add(const MapEntry('email', 'john@example.com'));
    formData.files.add(
      MapEntry(
        'avatar',
        MultipartFile.fromString('fake image data', filename: 'avatar.jpg'),
      ),
    );
    options.data = formData;

    interceptor.onRequest(options, RequestInterceptorHandler());

    final log = logger.history.last;
    expect(log.key, ISpectLogType.httpRequest.key);
    final meta = log.additionalData?[TraceKeys.meta] as Map?;
    final requestData = meta?['request-data'] as Map?;
    final data = requestData?['data'] as Map?;
    expect(data, isNotNull);

    final fields = data?['fields'] as Map?;
    expect(fields?['username'], 'john_doe');
    expect(fields?['email'], 'john@example.com');

    final files = data?['files'] as List?;
    expect(files, isNotNull);
    expect(files!.length, 1);
    expect((files[0] as Map)['filename'], 'avatar.jpg');
  });
}
