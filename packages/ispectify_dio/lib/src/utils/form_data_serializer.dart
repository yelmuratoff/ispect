import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';

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
      NetworkJsonKeys.fields: fields,
      NetworkJsonKeys.files: files,
    };
  }

  static Map<String, dynamic> _collectFields(FormData formData) {
    final fields = <String, Object?>{};

    for (final entry in formData.fields) {
      final existing = fields[entry.key];
      if (existing == null) {
        fields[entry.key] = entry.value;
      } else if (existing is List<Object?>) {
        existing.add(entry.value);
      } else {
        fields[entry.key] = <Object?>[existing, entry.value];
      }
    }

    return fields;
  }

  static List<Map<String, Object?>> _collectFiles(FormData formData) =>
      formData.files
          .map(
            (file) => <String, Object?>{
              NetworkJsonKeys.fieldName: file.key,
              NetworkJsonKeys.filename: file.value.filename,
              NetworkJsonKeys.contentTypeValue:
                  file.value.contentType?.toString(),
              NetworkJsonKeys.length: file.value.length,
              NetworkJsonKeys.headers: file.value.headers,
            },
          )
          .toList();
}
