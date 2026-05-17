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
  Map<String, dynamic> toJson() => {
        // --- Error summary: what went wrong ---
        NetworkJsonKeys.type: exception?.type,
        NetworkJsonKeys.message: exception?.message,
        NetworkJsonKeys.error: exception?.error,
        NetworkJsonKeys.stackTrace: exception?.stackTrace,

        // --- Response (if any) ---
        NetworkJsonKeys.response: responseData.toJson(),

        // --- Original request (reference) ---
        NetworkJsonKeys.request: requestData.toJson(),
      };

  /// Applies in-place redaction to a map produced by [toJson].
  ///
  /// Also redacts the embedded [NetworkJsonKeys.response] and
  /// [NetworkJsonKeys.request] sub-maps.
  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    // Redact free-text fields
    final msg = map[NetworkJsonKeys.message];
    if (msg != null) {
      map[NetworkJsonKeys.message] = redactor.redact(
        msg,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
    final err = map[NetworkJsonKeys.error];
    if (err != null) {
      map[NetworkJsonKeys.error] = redactor.redact(
        err,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }

    if (map[NetworkJsonKeys.response]
        case final Map<String, dynamic> responseMap) {
      DioResponseData.redact(
        responseMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
    if (map[NetworkJsonKeys.request]
        case final Map<String, dynamic> requestMap) {
      DioRequestData.redact(
        requestMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
  }
}
