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

  late final ISpectify _logger;
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
    if (!_shouldProcessRequest(request)) return request;

    final message = request.url.toString();
    final useRedaction = settings.enableRedaction;

    final redactedHeaders = settings.printRequestHeaders
        ? _redactHeaders(request.headers, useRedaction)
        : null;

    final redactedBody = settings.printRequestData
        ? _processRequestBody(request, useRedaction)
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
          redactor: useRedaction ? _redactor : null,
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
          redactor: useRedaction ? _redactor : null,
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

  Map<String, String> _redactHeaders(
    Map<String, String> headers,
    bool useRedaction,
  ) =>
      useRedaction
          ? _redactor
              .redactHeaders(headers)
              .map((k, v) => MapEntry(k, v?.toString() ?? ''))
          : headers;

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
      return useRedaction ? _redactor.redact(decoded) : decoded;
    } catch (_) {
      return useRedaction ? _redactor.redact(response.body) : response.body;
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

  Map<String, dynamic> _processErrorBody(
    Object? responseBodyData,
    Map<String, dynamic>? requestBodyData,
  ) {
    // Early return if no response body data
    if (responseBodyData == null) {
      return requestBodyData ?? <String, dynamic>{};
    }

    // Handle Map type
    if (responseBodyData is Map) {
      return _processMapErrorBody(responseBodyData);
    }

    // Handle Iterable type
    if (responseBodyData is Iterable) {
      return _processIterableErrorBody(responseBodyData);
    }

    // Handle String type
    if (responseBodyData is String) {
      return _processStringErrorBody(responseBodyData);
    }

    // Fallback for other types
    return <String, dynamic>{'raw': responseBodyData.toString()};
  }

  Map<String, dynamic> _processMapErrorBody(Map<dynamic, dynamic> data) {
    try {
      final redacted = settings.enableRedaction ? _redactor.redact(data) : data;

      // Guard clause: if already correct type, return early
      if (redacted is Map<String, dynamic>) {
        return redacted;
      }

      // Convert to correct type
      final mapToConvert = redacted is Map ? redacted : data;
      return mapToConvert.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      // Fallback: convert original data
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
  }

  Map<String, dynamic> _processIterableErrorBody(Iterable<dynamic> data) {
    final processed = settings.enableRedaction ? _redactor.redact(data) : data;
    return <String, dynamic>{'data': processed};
  }

  Map<String, dynamic> _processStringErrorBody(String data) {
    final processed = settings.enableRedaction ? _redactor.redact(data) : data;
    return <String, dynamic>{'raw': processed};
  }

  /// Extract multipart form data for logging
  Map<String, dynamic> _extractMultipartData(
    MultipartRequest request,
    bool useRedaction,
  ) {
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

    return {
      'fields': redactedFields,
      'files': redactedFiles,
    };
  }

  /// Processes HTTP request body, attempting to parse JSON for proper formatting and redaction
  Object? _redactRequestBody(String body, bool useRedaction) {
    try {
      final jsonData = jsonDecode(body);
      return useRedaction ? _redactor.redact(jsonData) : jsonData;
    } catch (_) {
      return useRedaction ? _redactor.redact(body) : body;
    }
  }
}
