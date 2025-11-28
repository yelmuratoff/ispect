import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/models/_models.dart';
import 'package:ispectify_http/src/settings.dart';
import 'package:ispectify_http/src/utils/multipart_serializer.dart';

class ISpectHttpInterceptor extends InterceptorContract
    with BaseNetworkInterceptor {
  ISpectHttpInterceptor({
    ISpectLogger? logger,
    this.settings = const ISpectHttpInterceptorSettings(),
    RedactionService? redactor,
  }) {
    initializeInterceptor(logger: logger, redactor: redactor);
  }

  /// `ISpectHttpInterceptor` settings and customization
  ISpectHttpInterceptorSettings settings;

  @override
  bool get enableRedaction => settings.enableRedaction;

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
    if (redactor != null) this.redactor = redactor;
  }

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (!_shouldProcessRequest(request)) return request;

    final useRedaction = settings.enableRedaction;

    final headers = settings.printRequestHeaders
        ? _stringHeaders(request.headers, useRedaction)
        : null;

    final body = settings.printRequestData
        ? _requestBodyPayload(request, useRedaction)
        : null;

    logger.logData(
      HttpRequestLog(
        request.url.toString(),
        method: request.method,
        url: request.url.toString(),
        path: request.url.path,
        headers: headers,
        settings: settings,
        body: body,
      ),
    );
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final isErrorResponse =
        response.statusCode >= 400 && response.statusCode < 600;
    if (!isErrorResponse && !_shouldProcessResponse(response)) return response;
    if (isErrorResponse && !_shouldProcessError(response)) return response;

    final useRedaction = settings.enableRedaction;

    final responseBody = _responseBodyPayload(
      response,
      useRedaction,
      include: isErrorResponse
          ? settings.printErrorData
          : settings.printResponseData,
    );

    final requestBody = settings.printRequestData
        ? _requestBodyPayload(response.request, useRedaction)
        : null;

    final responseData = HttpResponseData(
      baseResponse: response,
      requestData: HttpRequestData(response.request),
      response: response is Response ? response : null,
      multipartRequest: response.request is MultipartRequest
          ? response.request! as MultipartRequest
          : null,
    );

    if (isErrorResponse) {
      logger.logData(
        HttpErrorLog(
          response.request?.url.toString() ?? '',
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          settings: settings,
          statusMessage:
              settings.printErrorMessage ? response.reasonPhrase : null,
          requestHeaders: settings.printRequestHeaders
              ? _stringHeaders(response.request?.headers, useRedaction)
              : null,
          headers: settings.printErrorHeaders
              ? _stringHeaders(response.headers, useRedaction)
              : null,
          body: _errorBodyPayload(responseBody, requestBody),
          responseData: responseData,
          redactor: useRedaction ? redactor : null,
        ),
      );
    } else {
      logger.logData(
        HttpResponseLog(
          response.request?.url.toString() ?? '',
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage:
              settings.printResponseMessage ? response.reasonPhrase : null,
          requestHeaders: settings.printRequestHeaders
              ? _stringHeaders(response.request?.headers, useRedaction)
              : null,
          headers: settings.printResponseHeaders
              ? _stringHeaders(response.headers, useRedaction)
              : null,
          requestBody: requestBody,
          responseBody: responseBody,
          settings: settings,
          responseData: responseData,
          redactor: useRedaction ? redactor : null,
        ),
      );
    }

    return response;
  }

  bool _shouldProcessRequest(BaseRequest request) =>
      settings.enabled && (settings.requestFilter?.call(request) ?? true);

  bool _shouldProcessResponse(BaseResponse response) =>
      settings.enabled && (settings.responseFilter?.call(response) ?? true);

  bool _shouldProcessError(BaseResponse response) =>
      settings.enabled && (settings.errorFilter?.call(response) ?? true);

  Map<String, String>? _stringHeaders(
    Map<String, String>? headers,
    bool useRedaction,
  ) {
    if (headers == null || headers.isEmpty) return null;
    final objectHeaders =
        headers.map((key, value) => MapEntry(key, value as Object?));
    final sanitized = payload.headersOrNull(
      objectHeaders,
      enableRedaction: useRedaction,
    );
    return sanitized
        ?.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  Map<String, dynamic>? _requestBodyPayload(
    BaseRequest? request,
    bool useRedaction,
  ) {
    if (request == null) return null;

    if (request is MultipartRequest) {
      final serialized = HttpMultipartSerializer.serialize(request);
      final sanitized = payload.body(
        serialized,
        enableRedaction: useRedaction,
      );
      final map = payload.ensureMap(sanitized);
      return map.isEmpty ? null : map;
    }

    if (request is Request) {
      if (request.body.isEmpty) return null;
      final sanitized = payload.body(
        request.body,
        enableRedaction: useRedaction,
        normalizer: _decodeJsonGracefully,
      );
      final map = payload.ensureMap(sanitized);
      return map.isEmpty ? null : map;
    }

    return null;
  }

  Object? _responseBodyPayload(
    BaseResponse response,
    bool useRedaction, {
    required bool include,
  }) {
    if (!include) return null;
    if (response is! Response || response.body.isEmpty) return null;

    return payload.body(
      response.body,
      enableRedaction: useRedaction,
      normalizer: _decodeJsonGracefully,
    );
  }

  Map<String, dynamic> _errorBodyPayload(
    Object? responseBody,
    Map<String, dynamic>? requestBody,
  ) {
    final payloadMap = <String, dynamic>{};
    final responseMap = payload.ensureMap(responseBody);
    if (responseMap.isNotEmpty) {
      payloadMap['response'] = responseMap;
    }

    if (requestBody != null && requestBody.isNotEmpty) {
      payloadMap['request'] = requestBody;
    }

    return payloadMap;
  }

  Object? _decodeJsonGracefully(Object? value) {
    if (value is! String) return value;
    if (value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }
}
