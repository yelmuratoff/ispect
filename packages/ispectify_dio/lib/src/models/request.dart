import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioRequestLog extends ISpectifyData {
  DioRequestLog(
    super.message, {
    required this.requestData,
    required this.settings,
    required this.method,
    required this.url,
    required this.path,
    required this.headers,
    required this.body,
  }) : super(
          title: getKey,
          key: getKey,
          pen: settings.requestPen ?? (AnsiPen()..xterm(219)),
          additionalData: requestData.toJson,
        );

  final String method;
  final String url;
  final String path;
  final Map<String, dynamic> headers;
  final Object? body;
  final ISpectifyDioLoggerSettings settings;
  final DioRequestData requestData;

  static const getKey = 'http-request';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    final data = body;

    try {
      if (settings.printRequestData && data != null) {
        final prettyData = encoder.convert(data);
        msg += '\nData: $prettyData';
      }
      if (settings.printRequestHeaders && headers.isNotEmpty) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}
