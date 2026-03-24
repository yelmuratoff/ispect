import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpRequestLog extends NetworkRequestLog {
  HttpRequestLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required ISpectHttpInterceptorSettings settings,
    required HttpRequestData requestData,
    super.requestId,
    Map<String, String>? headers,
    super.body,
    RedactionService? redactor,
  })  : _requestData = requestData,
        super(
          settings: settings,
          headers: headers?.map(MapEntry.new),
          metadata: requestData.toJson(
            redactor: redactor,
          ),
        );

  final HttpRequestData _requestData;

  HttpRequestData get requestData => _requestData;
}
