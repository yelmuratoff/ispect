import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

/// Serializes an HTTP [MultipartRequest] into a map that can be logged and
/// redacted consistently.
class HttpMultipartSerializer {
  const HttpMultipartSerializer._();

  static Map<String, dynamic> serialize(MultipartRequest request) {
    final fields = Map<String, Object?>.from(request.fields);
    final files = request.files
        .map(
          (file) => <String, Object?>{
            NetworkJsonKeys.fieldName: file.field,
            NetworkJsonKeys.filename: file.filename,
            NetworkJsonKeys.contentTypeValue: file.contentType.toString(),
            NetworkJsonKeys.length: file.length,
          },
        )
        .toList();

    return {
      NetworkJsonKeys.fields: fields,
      NetworkJsonKeys.files: files,
    };
  }
}
