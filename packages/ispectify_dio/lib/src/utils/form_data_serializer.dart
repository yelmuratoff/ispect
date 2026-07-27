import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';

/// Utility helpers for converting Dio [FormData] into structured maps that can be
/// logged and redacted consistently across the package.
final class DioFormDataSerializer {
  const DioFormDataSerializer._();

  /// Serializes a [FormData] instance into a map with two keys:
  /// - `fields`: regular form fields with duplicate keys preserved as lists
  /// - `files`: file metadata (name, content type, length, headers)
  static Map<String, dynamic> serialize(
    FormData formData, {
    bool redactionActive = false,
  }) {
    final rawFields = LogExportOutput.boundJsonValue(
      formData.fields.map(
        (entry) => <String, Object?>{
          NetworkJsonKeys.fieldName: entry.key,
          NetworkJsonKeys.data: entry.value,
        },
      ),
      maxBytes: LogExportOutput.maxPreparedValueBytes ~/ 2,
      replaceOversizedStrings: redactionActive,
    );
    final rawFiles = LogExportOutput.boundJsonValue(
      formData.files.map(
        (file) => <String, Object?>{
          NetworkJsonKeys.fieldName: file.key,
          NetworkJsonKeys.filename: file.value.filename,
          NetworkJsonKeys.contentTypeValue: file.value.contentType?.toString(),
          NetworkJsonKeys.length: file.value.length,
          NetworkJsonKeys.headers: file.value.headers,
        },
      ),
      maxBytes: LogExportOutput.maxPreparedValueBytes ~/ 2,
      replaceOversizedStrings: redactionActive,
    );
    final fields = _collectFields(rawFields);
    final files = <Map<String, Object?>>[];
    if (rawFiles is List<Object?>) {
      for (final item in rawFiles) {
        if (item is Map<String, Object?>) {
          files.add(item);
        } else {
          files.add(
            <String, Object?>{
              JsonValueNormalizer.traversalMarkerKey: item,
            },
          );
          break;
        }
      }
    }
    final bounded = LogExportOutput.boundJsonValue(
      <String, Object?>{
        NetworkJsonKeys.fields: fields,
        NetworkJsonKeys.files: files,
      },
      // Leave headroom for JSON object/list punctuation around retained text.
      maxBytes: 44 * 1024,
      replaceOversizedStrings: redactionActive,
    );
    return bounded is Map<String, Object?>
        ? Map<String, dynamic>.from(bounded)
        : <String, dynamic>{
            NetworkJsonKeys.fields: <String, Object?>{},
            NetworkJsonKeys.files: <Object?>[],
          };
  }

  static Map<String, dynamic> _collectFields(Object? rawFields) {
    final fields = <String, Object?>{};
    if (rawFields is! List<Object?>) return fields;
    for (final item in rawFields) {
      if (item is! Map<String, Object?>) {
        fields[JsonValueNormalizer.traversalMarkerKey] =
            JsonValueNormalizer.maxCollectionItemsReached;
        break;
      }
      final key = item[NetworkJsonKeys.fieldName];
      if (key is! String ||
          key.contains(LogExportOutput.truncatedMarker) ||
          key == JsonValueNormalizer.unprintableValue) {
        fields[JsonValueNormalizer.traversalMarkerKey] =
            LogExportOutput.truncatedMarker;
        break;
      }
      final value = item[NetworkJsonKeys.data];
      final existing = fields[key];
      if (existing == null) {
        fields[key] = value;
      } else if (existing is List<Object?>) {
        existing.add(value);
      } else {
        fields[key] = <Object?>[existing, value];
      }
    }

    return fields;
  }
}
