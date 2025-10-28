import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/_data.dart';
import 'package:ispectify_http/src/models/_models.dart';
import 'package:ispectify_http/src/settings.dart';

class ISpectHttpInterceptor extends InterceptorContract
    with BaseNetworkInterceptor {
  ISpectHttpInterceptor({
    ISpectify? logger,
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

    final message = request.url.toString();
    final useRedaction = settings.enableRedaction;

    final redactedHeaders = settings.printRequestHeaders
        ? _redactHeaders(request.headers, useRedaction)
        : null;

    final redactedBody = settings.printRequestData
        ? _processRequestBody(request, useRedaction)
        : null;

    logger.logCustom(
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
    // For error responses, defer to error filter instead of response filter
    // This prevents responseFilter from suppressing error logging
    final isErrorResponse =
        response.statusCode >= 400 && response.statusCode < 600;
    if (!isErrorResponse && !_shouldProcessResponse(response)) return response;
    if (isErrorResponse && !_shouldProcessError(response)) return response;

    final message = response.request?.url.toString() ?? '';
    final useRedaction = settings.enableRedaction;

    // Process response body if needed
    final responseBodyData = _processResponseBody(response, useRedaction);

    // Process request body for multipart requests
    final requestBodyData =
        _processMultipartRequestBody(response, useRedaction);

    // Create response data object
    final responseData = HttpResponseData(
      baseResponse: response,
      requestData: HttpRequestData(response.request),
      response: response is Response ? response : null,
      multipartRequest: response.request is MultipartRequest
          ? response.request! as MultipartRequest
          : null,
    );

    if (isErrorResponse) {
      final errorBodyMap = _processErrorBody(responseBodyData, requestBodyData);

      logger.logCustom(
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
              ? _redactHeaders(
                  response.request?.headers ?? const {},
                  useRedaction,
                )
              : null,
          headers: settings.printErrorHeaders
              ? _redactHeaders(response.headers, useRedaction)
              : null,
          body: errorBodyMap,
          responseData: responseData,
          redactor: useRedaction ? redactor : null,
        ),
      );
    } else {
      logger.logCustom(
        HttpResponseLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage:
              settings.printResponseMessage ? response.reasonPhrase : null,
          requestHeaders: settings.printRequestHeaders
              ? _redactHeaders(
                  response.request?.headers ?? const {},
                  useRedaction,
                )
              : null,
          headers: settings.printResponseHeaders
              ? _redactHeaders(response.headers, useRedaction)
              : null,
          requestBody: settings.printRequestData ? requestBodyData : null,
          responseBody: settings.printResponseData ? responseBodyData : null,
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

  /// Extracts HTTP request body with proper redaction.
  ///
  /// Delegates to [redactHeaders] from mixin for headers processing.
  Map<String, String> _redactHeaders(
    Map<String, String> headers,
    bool useRedaction,
  ) {
    final headersMap = headers.map((k, v) => MapEntry(k, v as Object?));
    final redacted = redactHeaders(headersMap, useRedaction: useRedaction);
    return redacted.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  Object? _processRequestBody(BaseRequest request, bool useRedaction) =>
      switch (request) {
        MultipartRequest() => _extractMultipartData(request, useRedaction),
        Request() => _redactRequestBody(request.body, useRedaction),
        _ => null,
      };

  Object? _processResponseBody(BaseResponse response, bool useRedaction) {
    if (response is! Response) return null;

    final shouldDecodeBody = settings.printResponseData ||
        ((response.statusCode >= 400 && response.statusCode < 600) &&
            settings.printErrorData);

    if (!shouldDecodeBody) return null;

    try {
      final decoded = jsonDecode(response.body);
      return useRedaction ? redactor.redact(decoded) : decoded;
    } catch (_) {
      return useRedaction ? redactor.redact(response.body) : response.body;
    }
  }

  Map<String, dynamic>? _processMultipartRequestBody(
    BaseResponse response,
    bool useRedaction,
  ) {
    if (response.request is! MultipartRequest || !settings.printRequestData) {
      return null;
    }

    final request = response.request! as MultipartRequest;
    return _extractMultipartData(request, useRedaction);
  }

  /// Processes error body with improved type safety using pattern matching.
  Map<String, dynamic> _processErrorBody(
    Object? responseBodyData,
    Map<String, dynamic>? requestBodyData,
  ) =>
      switch (responseBodyData) {
        null => requestBodyData ?? <String, dynamic>{},
        final Map<String, dynamic> map => _processMapErrorBody(map),
        final Map<dynamic, dynamic> map => _convertToTypedMap(map),
        final Iterable<dynamic> iter => <String, dynamic>{
            'data': _maybeRedact(iter),
          },
        final String str => <String, dynamic>{'raw': _maybeRedact(str)},
        _ => <String, dynamic>{'raw': responseBodyData.toString()},
      };

  /// Redacts data if redaction is enabled, otherwise returns original.
  Object? _maybeRedact(Object? data) =>
      maybeRedact(data, useRedaction: settings.enableRedaction);

  /// Converts untyped Map to Map<String, dynamic>.
  Map<String, dynamic> _convertToTypedMap(Map<dynamic, dynamic> map) =>
      convertToTypedMap(map);

  Map<String, dynamic> _processMapErrorBody(Map<dynamic, dynamic> data) =>
      processMapData(data, useRedaction: settings.enableRedaction);

  /// Extract multipart form data for logging
  Map<String, dynamic> _extractMultipartData(
    MultipartRequest request,
    bool useRedaction,
  ) {
    final redactedFields = useRedaction
        ? Map<String, Object?>.from(
            (redactor.redact(request.fields)! as Map).map(
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
        ? (redactor.redact(filesList)! as List).cast<Map<String, Object?>>()
        : filesList.cast<Map<String, Object?>>();

    return {
      'fields': redactedFields,
      'files': redactedFiles,
    };
  }

  /// Processes HTTP request body, attempting to parse JSON for proper formatting and redaction
  Object? _redactRequestBody(String body, bool useRedaction) {
    try {
      final jsonData = jsonDecode(body);
      return useRedaction ? redactor.redact(jsonData) : jsonData;
    } catch (_) {
      return useRedaction ? redactor.redact(body) : body;
    }
  }
}
