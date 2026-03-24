import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpRequestLog extends NetworkRequestLog {
  HttpRequestLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required ISpectHttpInterceptorSettings settings,
    super.requestId,
    Map<String, String>? headers,
    super.body,
  })  : super(
          settings: settings,
          headers: headers?.map(MapEntry.new),
        );
}
