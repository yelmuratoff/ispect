import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/models/response.dart';
import 'package:test/test.dart';

void main() {
  test('preserves duplicate form fields and lists them', () async {
    final inspector = ISpectify();
    final interceptor = ISpectDioInterceptor(
      logger: inspector,
      settings: const ISpectDioInterceptorSettings(
        enableRedaction: false,
      ),
    );

    // Build a fake response with FormData in requestOptions
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

    final future = inspector.stream
        .where((e) => e is DioResponseLog)
        .cast<DioResponseLog>()
        .first;

    interceptor.onResponse(response, ResponseInterceptorHandler());

    final log = await future;
    final reqBody = log.requestBody!['fields'] as Map<String, Object?>;
    expect(reqBody['tags[]'], isA<List<Object?>>());
    expect((reqBody['tags[]']! as List<Object?>).length, 2);
    expect(reqBody['single'], isA<List<Object?>>());
    expect((reqBody['single']! as List<Object?>).length, 2);
  });

  test('response FormData preserves duplicate fields', () async {
    final inspector = ISpectify();
    final interceptor = ISpectDioInterceptor(
      logger: inspector,
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

    final future = inspector.stream
        .where((e) => e is DioResponseLog)
        .cast<DioResponseLog>()
        .first;

    interceptor.onResponse(response, ResponseInterceptorHandler());

    final log = await future;
    final body = log.responseBody! as Map<String, Object?>;
    final fields = body['fields']! as Map<String, Object?>;
    expect(fields['ids'], isA<List<Object?>>());
    expect((fields['ids']! as List<Object?>).length, 2);
  });
}
