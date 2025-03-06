import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/data.dart';

class ISpectifyHttpLogger extends InterceptorContract {
  ISpectifyHttpLogger({ISpectify? iSpectify}) {
    _iSpectify = iSpectify ?? ISpectify();
  }

  late ISpectify _iSpectify;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    final message = '${request.url}';
    _iSpectify.logCustom(
      HttpRequestLog(
        message,
        method: request.method,
        url: request.url.toString(),
        path: request.url.path,
        headers: request.headers,
        body: (request is Request) ? request.body : null,
      ),
    );
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final message = '${response.request?.url}';
    Map<String, dynamic>? body;

    if (response is Response) {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.request is MultipartRequest) {
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
      _iSpectify.logCustom(
        HttpErrorLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          requestHeaders: response.request?.headers,
          headers: response.headers,
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
      _iSpectify.logCustom(
        HttpResponseLog(
          message,
          method: response.request?.method,
          url: response.request?.url.toString(),
          path: response.request?.url.path,
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          requestHeaders: response.request?.headers,
          headers: response.headers,
          requestBody: body ?? {},
          responseBody: response,
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

const encoder = JsonEncoder.withIndent('  ');

class HttpRequestLog extends ISpectiyData {
  HttpRequestLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.headers,
    required this.body,
  }) : super(
          title: getKey,
          key: getKey,
          pen: AnsiPen()..xterm(219),
          additionalData: {
            'method': method,
            'url': url,
            'path': path,
            'headers': headers,
            'body': body,
          },
        );

  final String method;
  final String url;
  final String path;
  final Map<String, dynamic> headers;
  final Object? body;

  static const getKey = 'http-request';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    try {
      if (headers.isNotEmpty) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}

class HttpResponseLog extends ISpectiyData {
  HttpResponseLog(
    super.message, {
    required this.responseData,
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.requestBody,
    required this.responseBody,
  }) : super(
          key: getKey,
          title: getKey,
          pen: AnsiPen()..xterm(46),
          additionalData: responseData?.toJson,
          // additionalData: {
          //   'method': method,
          //   'url': url,
          //   'path': path,
          //   'status_code': statusCode,
          //   'status_message': statusMessage,
          //   'request_headers': requestHeaders,
          //   'headers': headers,
          //   'request_body': requestBody,
          //   'response_body': responseBody,
          // },
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
  final HttpResponseData? responseData;

  static const getKey = 'http-response';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    msg += '\nStatus: $statusCode';

    try {
      if (headers?.isNotEmpty ?? false) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}

class HttpErrorLog extends ISpectiyData {
  HttpErrorLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.body,
    required this.responseData,
  }) : super(
          key: getKey,
          pen: AnsiPen()..red(),
          additionalData: responseData?.toJson,
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final HttpResponseData? responseData;

  static const getKey = 'http-error';

  @override
  String get textMessage {
    var msg = '[$method] $message';

    msg += '\nStatus: $statusCode';

    try {
      if (headers?.isNotEmpty ?? false) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}
