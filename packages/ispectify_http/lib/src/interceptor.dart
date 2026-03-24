import 'dart:developer' as developer;

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
    ISpectHttpInterceptorSettings settings =
        const ISpectHttpInterceptorSettings(),
    RedactionService? redactor,
  })  : _settings = settings,
        _logger = logger ?? ISpectLogger() {
    if (redactor != null) this.redactor = redactor;
  }

  final ISpectLogger _logger;

  @override
  ISpectLogger get logger => _logger;

  /// Current settings for this interceptor.
  ///
  /// Use [configure] for partial updates. The settings object itself is
  /// immutable — updates replace the entire instance.
  ISpectHttpInterceptorSettings get settings => _settings;
  ISpectHttpInterceptorSettings _settings;

  final RequestIdGenerator _requestIdGenerator = RequestIdGenerator();

  /// Tracks request IDs using [Expando] — auto-cleaned by GC when the
  /// [BaseRequest] is collected, avoiding memory leaks and hashCode collisions.
  final Expando<String> _requestIds = Expando<String>('ispect_rid');

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
    bool? enableRedaction,
    AnsiPen? requestPen,
    AnsiPen? responsePen,
    AnsiPen? errorPen,
    RedactionService? redactor,
  }) {
    _settings = _settings.copyWith(
      printRequestData: printRequestData,
      printRequestHeaders: printRequestHeaders,
      printResponseData: printResponseData,
      printErrorData: printErrorData,
      printErrorHeaders: printErrorHeaders,
      printErrorMessage: printErrorMessage,
      printResponseHeaders: printResponseHeaders,
      printResponseMessage: printResponseMessage,
      enableRedaction: enableRedaction,
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

    final requestId = _requestIdGenerator.next();
    _requestIds[request] = requestId;

    try {
      final useRedaction = settings.enableRedaction;

      final headers = settings.printRequestHeaders
          ? _stringHeaders(request.headers, useRedaction)
          : null;

      final body = settings.printRequestData
          ? _requestBodyPayload(request, useRedaction)
          : null;

      final (:url, :path) = redactUrlAndPath(
        request.url,
        useRedaction: useRedaction,
      );
      logger.logData(
        HttpRequestLog(
          url,
          method: request.method,
          url: url,
          path: path,
          requestId: requestId,
          headers: headers,
          settings: settings,
          body: body,
        ),
      );
    } catch (e, st) {
      developer.log(
        'Failed to log HTTP request: $e',
        name: 'ISpectHttpInterceptor',
        error: e,
        stackTrace: st,
      );
    }
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

    final requestId =
        response.request != null ? _requestIds[response.request!] : null;

    try {
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
        preDecodedBody: responseBody,
      );

      if (isErrorResponse) {
        final requestUrl = response.request?.url;
        final errorUrl = requestUrl != null
            ? redactUrlAndPath(requestUrl, useRedaction: useRedaction)
            : (url: '', path: '');
        logger.logData(
          HttpErrorLog(
            errorUrl.url,
            method: response.request?.method,
            url: errorUrl.url,
            path: errorUrl.path,
            requestId: requestId,
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
        final responseUrl = response.request?.url;
        final resp = responseUrl != null
            ? redactUrlAndPath(responseUrl, useRedaction: useRedaction)
            : (url: '', path: '');
        logger.logData(
          HttpResponseLog(
            resp.url,
            method: response.request?.method,
            url: resp.url,
            path: resp.path,
            requestId: requestId,
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
    } catch (e, st) {
      developer.log(
        'Failed to log HTTP response: $e',
        name: 'ISpectHttpInterceptor',
        error: e,
        stackTrace: st,
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
      return bodyAsMap(
        HttpMultipartSerializer.serialize(request),
        useRedaction: useRedaction,
      );
    }

    if (request is Request) {
      if (request.body.isEmpty) return null;
      return bodyAsMap(
        request.body,
        useRedaction: useRedaction,
        normalizer: _decodeJsonGracefully,
      );
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

  static Object? _decodeJsonGracefully(Object? value) =>
      NetworkPayloadSanitizer.decodeJsonGracefully(value);
}
