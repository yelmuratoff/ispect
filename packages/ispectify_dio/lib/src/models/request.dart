import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_dio/src/data/_data.dart';

class DioRequestLog extends NetworkRequestLog {
  DioRequestLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required ISpectDioInterceptorSettings settings,
    required DioRequestData requestData,
    super.headers,
    super.body,
    RedactionService? redactor,
  })  : _settings = settings,
        _requestData = requestData,
        super(
          settings: settings,
          metadata: requestData.toJson(
            redactor: redactor,
          ),
        );

  final ISpectDioInterceptorSettings _settings;
  final DioRequestData _requestData;

  DioRequestData get requestData => _requestData;

  @override
  ISpectDioInterceptorSettings get settings => _settings;
}
