import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpErrorLog extends ISpectifyData {
  HttpErrorLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.body,
    required this.responseData,
    required this.settings,
    this.redactor,
  }) : super(
          key: getKey,
          logLevel: LogLevel.error,
          pen: settings.errorPen ?? (AnsiPen()..red()),
          additionalData: responseData?.toJson(
            redactor: redactor,
            printResponseData: settings.printErrorData,
            printRequestData: settings.printRequestData,
            printResponseHeaders: settings.printErrorHeaders,
            printRequestHeaders: settings.printRequestHeaders,
          ),
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, String>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final HttpResponseData? responseData;
  final ISpectHttpInterceptorSettings settings;
  final RedactionService? redactor;

  static const getKey = 'http-error';

  @override
  String get textMessage {
    final buffer = StringBuffer('[$method] $message')
      ..write('\nStatus: $statusCode');

    if (settings.printErrorMessage && statusMessage != null) {
      buffer.write('\nMessage: $statusMessage');
    }

    if (settings.printErrorData && body != null && body!.isNotEmpty) {
      final prettyBody = JsonTruncatorService.pretty(body);
      buffer.write('\nData: $prettyBody');
    }

    if (settings.printErrorHeaders && headers != null && headers!.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(headers);
      buffer.write('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncate()!;
  }
}
