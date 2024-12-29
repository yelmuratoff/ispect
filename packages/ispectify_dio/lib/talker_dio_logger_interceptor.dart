import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'dio_logs.dart';
import 'ispectify_dio.dart';

/// [Dio] http client logger on [ISpectiy] base
///
/// [iSpectify] filed is current [ISpectiy] instance.
/// Provide your instance if your application used [ISpectiy] as default logger
/// Common ISpectiy instance will be used by default
class ISpectifyDioLogger extends Interceptor {
  ISpectifyDioLogger({
    ISpectiy? iSpectify,
    this.settings = const ISpectifyDioLoggerSettings(),
    this.addonId,
  }) {
    _talker = iSpectify ?? ISpectiy();
  }

  late ISpectiy _talker;

  /// [ISpectifyDioLogger] settings and customization
  ISpectifyDioLoggerSettings settings;

  /// ISpectiy addon functionality
  /// addon id for create a lot of addons
  final String? addonId;

  /// Method to update [settings] of [ISpectifyDioLogger]
  void configure({
    bool? printResponseData,
    bool? printResponseHeaders,
    bool? printResponseMessage,
    bool? printErrorData,
    bool? printErrorHeaders,
    bool? printErrorMessage,
    bool? printRequestData,
    bool? printRequestHeaders,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
  }) {
    settings = settings.copyWith(
      printRequestData: printRequestData,
      printRequestHeaders: printRequestHeaders,
      printResponseData: printResponseData,
      printErrorData: printErrorData,
      printErrorHeaders: printErrorHeaders,
      printErrorMessage: printErrorMessage,
      printResponseHeaders: printResponseHeaders,
      printResponseMessage: printResponseMessage,
      requestPen: requestPen,
      responsePen: responsePen,
      errorPen: errorPen,
    );
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    super.onRequest(options, handler);
    if (!settings.enabled) {
      return;
    }
    final accepted = settings.requestFilter?.call(options) ?? true;
    if (!accepted) {
      return;
    }
    try {
      final message = '${options.uri}';
      final httpLog = DioRequestLog(
        message,
        requestOptions: options,
        settings: settings,
      );
      _talker.logCustom(httpLog);
    } catch (_) {
      //pass
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
    if (!settings.enabled) {
      return;
    }
    final accepted = settings.responseFilter?.call(response) ?? true;
    if (!accepted) {
      return;
    }
    try {
      final message = '${response.requestOptions.uri}';
      final httpLog = DioResponseLog(
        message,
        settings: settings,
        response: response,
      );
      _talker.logCustom(httpLog);
    } catch (_) {
      //pass
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    if (!settings.enabled) {
      return;
    }
    final accepted = settings.errorFilter?.call(err) ?? true;
    if (!accepted) {
      return;
    }
    try {
      final message = '${err.requestOptions.uri}';
      final httpErrorLog = DioErrorLog(
        message,
        dioException: err,
        settings: settings,
      );
      _talker.logCustom(httpErrorLog);
    } catch (_) {
      //pass
    }
  }
}
