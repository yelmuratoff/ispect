import 'package:ispectify/ispectify.dart';

/// Builds a rich console message for HTTP network logs.
///
/// Delegates to the shared [buildNetworkConsoleMessage] from `ispectify` core.
String buildHttpConsoleMessage({
  required String source,
  required String operation,
  required String target,
  Duration? duration,
  bool success = true,
  int? statusCode,
  String? statusMessage,
  Object? body,
  Map<String, dynamic>? headers,
  String? errorMessage,
  bool printStatusCode = true,
  bool printStatusMessage = false,
  bool printBody = false,
  bool printHeaders = false,
  bool printErrorMessage = false,
}) =>
    buildNetworkConsoleMessage(
      source: source,
      operation: operation,
      target: target,
      duration: duration,
      success: success,
      statusCode: statusCode,
      statusMessage: statusMessage,
      body: body,
      headers: headers,
      errorMessage: errorMessage,
      printStatusCode: printStatusCode,
      printStatusMessage: printStatusMessage,
      printBody: printBody,
      printHeaders: printHeaders,
      printErrorMessage: printErrorMessage,
    );
