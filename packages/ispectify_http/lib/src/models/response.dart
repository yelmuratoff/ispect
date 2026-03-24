import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/settings.dart';

class HttpResponseLog extends NetworkResponseLog {
  HttpResponseLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required super.statusCode,
    required super.statusMessage,
    required ISpectHttpInterceptorSettings settings,
    required HttpResponseData? responseData,
    super.requestId,
    Map<String, String>? requestHeaders,
    Map<String, String>? headers,
    super.requestBody,
    super.responseBody,
    RedactionService? redactor,
  })  : _responseData = responseData,
        super(
          settings: settings,
          requestHeaders: requestHeaders?.map(MapEntry.new),
          headers: headers?.map(MapEntry.new),
          metadata: responseData?.toJson(
            redactor: redactor,
          ),
        );

  final HttpResponseData? _responseData;

  HttpResponseData? get responseData => _responseData;
}
