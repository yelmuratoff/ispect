import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';

/// Sends composed/replayed requests through an app-owned [Dio] instance.
///
/// Because the request travels through the same [dio] the app configured, its
/// base options, auth interceptors, and retries apply — and the existing
/// [ISpectDioInterceptor] captures it, so no separate unredacted log is made.
/// Register one per client via the ISpect entry point.
final class DioRequestSender implements NetworkRequestSender {
  DioRequestSender(this.dio, {this.id = 'dio', this.label = 'Dio'});

  final Dio dio;

  @override
  final String id;

  @override
  final String label;

  @override
  Future<NetworkReplayResult> send(NetworkReplayRequest request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await dio.request<dynamic>(
        request.uri.toString(),
        data: _data(request.body),
        options: _options(request),
      );
      return NetworkReplayResult(
        statusCode: response.statusCode,
        headers: _flattenHeaders(response.headers),
        body: response.data,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      final response = e.response;
      return NetworkReplayResult(
        statusCode: response?.statusCode,
        headers:
            response == null ? const {} : _flattenHeaders(response.headers),
        body: response?.data,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e,
      );
    }
  }

  Options _options(NetworkReplayRequest request) {
    final contentType = _contentType(request.body);
    final headers = Map<String, dynamic>.from(request.headers);
    if (contentType != null || request.body is MultipartReplayBody) {
      headers.removeWhere((key, _) => key.toLowerCase() == 'content-type');
    }
    return Options(
      method: request.method,
      headers: headers,
      contentType: contentType,
    );
  }

  Object? _data(NetworkReplayBody? body) => switch (body) {
        null => null,
        JsonReplayBody(:final value) => value,
        TextReplayBody(:final text) => text,
        FormUrlEncodedReplayBody(:final fields) => fields,
        MultipartReplayBody(:final fields, :final files) =>
          _toFormData(fields, files),
      };

  String? _contentType(NetworkReplayBody? body) => switch (body) {
        JsonReplayBody() => Headers.jsonContentType,
        FormUrlEncodedReplayBody() => Headers.formUrlEncodedContentType,
        TextReplayBody(:final contentType) => contentType,
        null || MultipartReplayBody() => null,
      };

  FormData _toFormData(
    List<MultipartReplayField> fields,
    List<MultipartReplayFile> files,
  ) {
    final form = FormData();
    for (final field in fields) {
      form.fields.add(MapEntry(field.name, field.value));
    }
    for (final part in files) {
      final file = part.file;
      form.files.add(
        MapEntry(
          part.field,
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.filename,
            contentType: file.contentType == null
                ? null
                : DioMediaType.parse(file.contentType!),
          ),
        ),
      );
    }
    return form;
  }

  Map<String, String> _flattenHeaders(Headers headers) {
    final result = <String, String>{};
    headers.forEach((name, values) => result[name] = values.join(', '));
    return result;
  }
}
