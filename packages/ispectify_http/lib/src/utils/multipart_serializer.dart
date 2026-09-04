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
      maxBytes: MultipartCapture.sectionBudget(resourceLimits),
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    return MultipartCapture.envelope(
      fields: fields is Map<String, Object?> ? fields : <String, Object?>{},
      files: request.files.map(
        (file) => <String, Object?>{
          NetworkJsonKeys.fieldName: file.field,
          NetworkJsonKeys.filename: file.filename,
          NetworkJsonKeys.contentTypeValue: file.contentType.toString(),
          NetworkJsonKeys.length: file.length,
        },
      ),
      redactionActive: redactionActive,
      resourceLimits: resourceLimits,
    );
  }
}
