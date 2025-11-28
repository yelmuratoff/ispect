import 'package:http_interceptor/http_interceptor.dart';

/// Serializes an HTTP [MultipartRequest] into a map that can be logged and
/// redacted consistently.
class HttpMultipartSerializer {
  const HttpMultipartSerializer._();

  static Map<String, dynamic> serialize(MultipartRequest request) {
    final fields = Map<String, Object?>.from(request.fields);
    final files = request.files
        .map(
          (file) => <String, Object?>{
            'field': file.field,
            'filename': file.filename,
            'contentType': file.contentType.toString(),
            'length': file.length,
          },
        )
        .toList();

    return {
      'fields': fields,
      'files': files,
    };
  }
}
