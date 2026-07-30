import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

/// Serializes an HTTP [MultipartRequest] into a map that can be logged and
/// redacted consistently.
class HttpMultipartSerializer {
  const HttpMultipartSerializer._();

  static Map<String, dynamic> serialize(
    MultipartRequest request, {
    bool redactionActive = false,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final fields = LogExportOutput.boundJsonValue(
      request.fields,
      maxBytes: resourceLimits.maxNetworkBodyBytes ~/ 2,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    final files = LogExportOutput.boundJsonValue(
      request.files.map(
        (file) => <String, Object?>{
          NetworkJsonKeys.fieldName: file.field,
          NetworkJsonKeys.filename: file.filename,
          NetworkJsonKeys.contentTypeValue: file.contentType.toString(),
          NetworkJsonKeys.length: file.length,
        },
      ),
      maxBytes: resourceLimits.maxNetworkBodyBytes ~/ 2,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    final bounded = LogExportOutput.boundJsonValue(
      <String, Object?>{
        NetworkJsonKeys.fields:
            fields is Map<String, Object?> ? fields : <String, Object?>{},
        NetworkJsonKeys.files: files is List<Object?> ? files : <Object?>[],
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
