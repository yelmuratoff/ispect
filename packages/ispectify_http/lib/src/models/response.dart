import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpResponseLog extends ISpectifyData {
  HttpResponseLog(
    super.message, {
    required this.responseData,
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.requestBody,
    required this.responseBody,
    required this.settings,
    this.redactor,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.responsePen ?? (AnsiPen()..xterm(35)),
          additionalData: responseData?.toJson(redactor: redactor),
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, String>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
  final ISpectHttpInterceptorSettings settings;
  final HttpResponseData? responseData;
  final RedactionService? redactor;

  static const getKey = 'http-response';

  @override
  String get textMessage {
    final buffer = StringBuffer('[$method] $message')
      ..write('\nStatus: $statusCode');

    if (settings.printResponseMessage && statusMessage != null) {
      buffer.write('\nMessage: $statusMessage');
    }

    if (settings.printResponseData && responseBody != null) {
      final prettyData = JsonTruncatorService.pretty(
        responseBody,
      );
      buffer.write('\nData: $prettyData');
    }

    if (settings.printResponseHeaders &&
        headers != null &&
        headers!.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(
        headers,
      );
      buffer.write('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncate()!;
  }
}
