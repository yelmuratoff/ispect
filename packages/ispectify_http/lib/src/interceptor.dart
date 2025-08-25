import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/models/_models.dart';
import 'package:ispectify_http/src/settings.dart';

class ISpectHttpInterceptor extends InterceptorContract {
  ISpectHttpInterceptor({
    ISpectify? logger,
    this.settings = const ISpectHttpInterceptorSettings(),
  }) {
    _logger = logger ?? ISpectify();
  }

  late ISpectify _logger;

  /// `ISpectHttpInterceptor` settings and customization
  ISpectHttpInterceptorSettings settings;

  /// Method to update `settings` of [ISpectHttpInterceptor]
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
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (!settings.enabled) {
      return request;
    }

    final accepted = settings.requestFilter?.call(request) ?? true;
    if (!accepted) {
      return request;
    }

    final message = '${request.url}';
    _logger.logCustom(
      HttpRequestLog(
        message,
        method: request.method,
        url: request.url.toString(),
        path: request.url.path,
        headers: settings.printRequestHeaders ? request.headers : null,
        settings: settings,
        body: settings.printRequestData
            ? ((request is Request) ? request.body : null)
            : null,
      ),
    );
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (!settings.enabled) {
      return response;
    }

    final accepted = settings.responseFilter?.call(response) ?? true;
    if (!accepted) {
      return response;
    }

    final message = '${response.request?.url}';
    Map<String, dynamic>? body;

    if (response is Response && settings.printResponseData) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = {'raw': response.body};
      }
    } else if (response.request is MultipartRequest &&
        settings.printRequestData) {
      final request = response.request! as MultipartRequest;
      body = {
        'fields': request.fields,
        'files': request.files
            .map(
              (file) => {
                'filename': file.filename,
                'length': file.length,
                'contentType': file.contentType,
                'field': file.field,
              },
            )
            .toList(),
      };
    }

    if (response.statusCode >= 400 && response.statusCode < 600) {
      final errorAccepted = settings.errorFilter?.call(response) ?? true;
      if (!errorAccepted) {
        return response;
      }

      _logger.logCustom(
        HttpErrorLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          settings: settings,
          statusMessage:
              settings.printErrorMessage ? response.reasonPhrase : null,
          requestHeaders:
              settings.printRequestHeaders ? response.request?.headers : null,
          headers: settings.printErrorHeaders ? response.headers : null,
          body: body ?? {},
          responseData: HttpResponseData(
            baseResponse: response,
            requestData: HttpRequestData(response.request),
            response: response is Response ? response : null,
            multipartRequest: response.request is MultipartRequest
                ? response.request! as MultipartRequest
                : null,
          ),
        ),
      );
    } else {
      _logger.logCustom(
        HttpResponseLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage:
              settings.printResponseMessage ? response.reasonPhrase : null,
          requestHeaders:
              settings.printRequestHeaders ? response.request?.headers : null,
          headers: settings.printResponseHeaders ? response.headers : null,
          requestBody: settings.printRequestData ? body : null,
          responseBody: settings.printResponseData ? response : null,
          settings: settings,
          responseData: HttpResponseData(
            baseResponse: response,
            requestData: HttpRequestData(response.request),
            response: response is Response ? response : null,
            multipartRequest: response.request is MultipartRequest
                ? response.request! as MultipartRequest
                : null,
          ),
        ),
      );
    }

    return response;
  }
}
