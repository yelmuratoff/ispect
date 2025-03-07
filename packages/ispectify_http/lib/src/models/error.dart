import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';

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
  }) : super(
          key: getKey,
          pen: AnsiPen()..red(),
          additionalData: responseData?.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final HttpResponseData? responseData;

  static const getKey = 'http-error';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    msg += '\nStatus: $statusCode';

    try {
      if (headers?.isNotEmpty ?? false) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}
