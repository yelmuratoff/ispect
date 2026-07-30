import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioErrorData {
  DioErrorData({
    required this.exception,
    required this.requestData,
    required this.responseData,
  });

  final DioException? exception;
  final DioRequestData requestData;
  final DioResponseData responseData;

  /// Returns a raw JSON-compatible map of the error.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson({
    bool includeData = true,
    bool includeHeaders = true,
    bool includeMessage = true,
    bool? includeRequestData,
    bool? includeRequestHeaders,
    bool redactionActive = false,
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
  }) {
    final shouldIncludeRequestData = includeRequestData ?? includeData;
    final shouldIncludeRequestHeaders = includeRequestHeaders ?? includeHeaders;

    return {
      NetworkJsonKeys.type: exception?.type,
      if (includeMessage) NetworkJsonKeys.message: exception?.message,
      if (includeMessage) NetworkJsonKeys.error: exception?.error,
      if (includeMessage) NetworkJsonKeys.stackTrace: exception?.stackTrace,
      NetworkJsonKeys.response: responseData.toJson(
        includeData: includeData,
        includeHeaders: includeHeaders,
        includeMessage: includeMessage,
        includeRequestData: shouldIncludeRequestData,
        includeRequestHeaders: shouldIncludeRequestHeaders,
        redactionActive: redactionActive,
        captureMode: captureMode,
      ),
      NetworkJsonKeys.request: requestData.toJson(
        includeData: shouldIncludeRequestData,
        includeHeaders: shouldIncludeRequestHeaders,
        redactionActive: redactionActive,
        captureMode: captureMode,
      ),
    };
  }

  /// Applies in-place redaction to a map produced by [toJson].
  ///
  /// Also redacts the embedded [NetworkJsonKeys.response] and
  /// [NetworkJsonKeys.request] sub-maps.
  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    for (final key in const [
      NetworkJsonKeys.message,
      NetworkJsonKeys.error,
      NetworkJsonKeys.stackTrace,
    ]) {
      NetworkMapRedactor.redactFreeText(
        map,
        redactor,
        key: key,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
      );
    }

    if (map[NetworkJsonKeys.response]
        case final Map<String, dynamic> responseMap) {
      DioResponseData.redact(
        responseMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
      );
    }
    if (map[NetworkJsonKeys.request]
        case final Map<String, dynamic> requestMap) {
      DioRequestData.redact(
        requestMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
        resourceLimits: resourceLimits,
      );
    }
  }
}
