import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/network/network_json_keys.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Shared capture budget for multipart request bodies.
///
/// Fields and file descriptors each receive half of
/// [DiagnosticResourceLimits.maxNetworkBodyBytes], and the assembled envelope
/// is bounded once more so both adapters retain the same amount of an upload.
abstract final class MultipartCapture {
  /// Byte budget for the fields section or the files section alone.
  static int sectionBudget(DiagnosticResourceLimits resourceLimits) =>
      resourceLimits.maxNetworkBodyBytes ~/ 2;

  /// Bounds [files] and wraps them with the already-bounded [fields] into the
  /// `{fields, files}` envelope.
  static Map<String, dynamic> envelope({
    required Object? fields,
    required Iterable<Map<String, Object?>> files,
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final rawFiles = LogExportOutput.boundJsonValue(
      files,
      maxBytes: sectionBudget(resourceLimits),
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    final boundedFiles = <Map<String, Object?>>[];
    if (rawFiles is List<Object?>) {
      for (final item in rawFiles) {
        if (item is Map<String, Object?>) {
          boundedFiles.add(item);
        } else {
          boundedFiles.add(
            <String, Object?>{JsonValueNormalizer.traversalMarkerKey: item},
          );
          break;
        }
      }
    }
    final bounded = LogExportOutput.boundJsonValue(
      <String, Object?>{
        NetworkJsonKeys.fields: fields,
        NetworkJsonKeys.files: boundedFiles,
      },
      maxBytes: resourceLimits.maxNetworkBodyBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    return bounded is Map<String, Object?>
        ? Map<String, dynamic>.from(bounded)
        : <String, dynamic>{
            NetworkJsonKeys.fields: <String, Object?>{},
            NetworkJsonKeys.files: <Object?>[],
          };
  }
}
