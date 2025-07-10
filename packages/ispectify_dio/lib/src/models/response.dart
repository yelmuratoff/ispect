import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioResponseLog extends ISpectifyData {
  DioResponseLog(
    super.message, {
    required this.responseData,
    required this.settings,
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.requestBody,
    required this.responseBody,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.responsePen ?? (AnsiPen()..xterm(35)),
          additionalData: responseData.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
  final ISpectifyDioLoggerSettings settings;
  final DioResponseData responseData;

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

    return buffer.toString().truncated!;
  }
}
