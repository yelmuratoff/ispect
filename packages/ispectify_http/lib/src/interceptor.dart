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
    RedactionService? redactor,
  }) {
    _logger = logger ?? ISpectify();
    _redactor = redactor ?? RedactionService();
  }

  late ISpectify _logger;
  late RedactionService _redactor;

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
    RedactionService? redactor,
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
    if (redactor != null) _redactor = redactor;
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
    final useRedaction = settings.enableRedaction;
    final redactedHeaders = settings.printRequestHeaders
        ? (useRedaction
            ? _redactor
                .redactHeaders(request.headers)
                .map((k, v) => MapEntry(k, v?.toString() ?? ''))
            : request.headers)
        : null;
    final redactedBody = settings.printRequestData
        ? (request is Request
            ? (useRedaction ? _redactor.redact(request.body) : request.body)
            : null)
        : null;
    _logger.logCustom(
      HttpRequestLog(
        message,
        method: request.method,
        url: request.url.toString(),
        path: request.url.path,
        headers: redactedHeaders,
        settings: settings,
        body: redactedBody,
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
    Map<String, dynamic>? requestBodyData;
    Object? responseBodyData;

    if (response is Response && settings.printResponseData) {
      try {
        final decoded = jsonDecode(response.body);
        responseBodyData =
            settings.enableRedaction ? _redactor.redact(decoded) : decoded;
      } catch (_) {
        responseBodyData = settings.enableRedaction
            ? _redactor.redact(response.body)
            : response.body;
      }
    }

    if (response.request is MultipartRequest && settings.printRequestData) {
      final request = response.request! as MultipartRequest;
      final useRedaction = settings.enableRedaction;
      final redactedFields = useRedaction
          ? Map<String, Object?>.from(
              (_redactor.redact(request.fields)! as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              ),
            )
          : Map<String, Object?>.from(request.fields);
      final filesList = request.files
          .map(
            (file) => {
              'filename': file.filename,
              'length': file.length,
              'contentType': file.contentType.toString(),
              'field': file.field,
            },
          )
          .toList();
      final redactedFiles = useRedaction
          ? (_redactor.redact(filesList)! as List).cast<Map<String, Object?>>()
          : filesList.cast<Map<String, Object?>>();
      requestBodyData = {
        'fields': redactedFields,
        'files': redactedFiles,
      };
    }

    if (response.statusCode >= 400 && response.statusCode < 600) {
      final errorAccepted = settings.errorFilter?.call(response) ?? true;
      if (!errorAccepted) {
        return response;
      }

      final errorBodyMap = () {
        if (responseBodyData is Map) {
          try {
            return (settings.enableRedaction
                ? _redactor.redact(responseBodyData)
                : responseBodyData)! as Map<String, dynamic>;
          } catch (_) {
            final raw = responseBodyData as Map<Object?, Object?>;
            return raw.map((k, v) => MapEntry(k.toString(), v));
          }
        }
        if (responseBodyData is Iterable) {
          final iterable = settings.enableRedaction
              ? _redactor.redact(responseBodyData)
              : responseBodyData;
          return <String, dynamic>{'data': iterable};
        }
        if (responseBodyData is String) {
          return <String, dynamic>{
            'raw': settings.enableRedaction
                ? _redactor.redact(responseBodyData)
                : responseBodyData,
          };
        }
        if (responseBodyData != null) {
          return <String, dynamic>{'raw': responseBodyData.toString()};
        }
        return requestBodyData ?? <String, dynamic>{};
      }();

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
          requestHeaders: settings.printRequestHeaders
              ? (settings.enableRedaction
                  ? _redactor
                      .redactHeaders(response.request?.headers ?? const {})
                      .map((k, v) => MapEntry(k, v?.toString() ?? ''))
                  : (response.request?.headers ?? const {}))
              : null,
          headers: settings.printErrorHeaders
              ? (settings.enableRedaction
                  ? _redactor
                      .redactHeaders(response.headers)
                      .map((k, v) => MapEntry(k, v?.toString() ?? ''))
                  : response.headers)
              : null,
          body: errorBodyMap,
          responseData: HttpResponseData(
            baseResponse: response,
            requestData: HttpRequestData(response.request),
            response: response is Response ? response : null,
            multipartRequest: response.request is MultipartRequest
                ? response.request! as MultipartRequest
                : null,
          ),
          redactor: settings.enableRedaction ? _redactor : null,
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
          requestHeaders: settings.printRequestHeaders
              ? (settings.enableRedaction
                  ? _redactor
                      .redactHeaders(response.request?.headers ?? const {})
                      .map((k, v) => MapEntry(k, v?.toString() ?? ''))
                  : (response.request?.headers ?? const {}))
              : null,
          headers: settings.printResponseHeaders
              ? (settings.enableRedaction
                  ? _redactor
                      .redactHeaders(response.headers)
                      .map((k, v) => MapEntry(k, v?.toString() ?? ''))
                  : response.headers)
              : null,
          requestBody: settings.printRequestData ? requestBodyData : null,
          responseBody: settings.printResponseData ? responseBodyData : null,
          settings: settings,
          responseData: HttpResponseData(
            baseResponse: response,
            requestData: HttpRequestData(response.request),
            response: response is Response ? response : null,
            multipartRequest: response.request is MultipartRequest
                ? response.request! as MultipartRequest
                : null,
          ),
          redactor: settings.enableRedaction ? _redactor : null,
        ),
      );
    }

    return response;
  }
}
