import 'package:dio/dio.dart';

/// Utility helpers for converting Dio [FormData] into structured maps that can be
/// logged and redacted consistently across the package.
final class DioFormDataSerializer {
  const DioFormDataSerializer._();

  /// Serializes a [FormData] instance into a map with two keys:
  /// - `fields`: regular form fields with duplicate keys preserved as lists
  /// - `files`: file metadata (name, content type, length, headers)
  static Map<String, dynamic> serialize(FormData formData) {
    final fields = _collectFields(formData);
    final files = _collectFiles(formData);

    return {
      'fields': fields,
      'files': files,
    };
  }

  static Map<String, dynamic> _collectFields(FormData formData) {
    final fields = <String, Object?>{};

    for (final entry in formData.fields) {
      final existing = fields[entry.key];
      if (existing == null) {
        fields[entry.key] = entry.value;
      } else if (existing is List) {
        existing.add(entry.value);
      } else {
        fields[entry.key] = [existing, entry.value];
      }
    }

    return fields;
  }

  static List<Map<String, Object?>> _collectFiles(FormData formData) =>
      formData.files
          .map(
            (file) => <String, Object?>{
              'key': file.key,
              'filename': file.value.filename,
              'contentType': file.value.contentType?.toString(),
              'length': file.value.length,
              'headers': file.value.headers,
            },
          )
          .toList();
}
