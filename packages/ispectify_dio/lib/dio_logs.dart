import 'dart:convert';

import 'package:ispectify/ispectify.dart';
import 'ispectify_dio.dart';

const _encoder = JsonEncoder.withIndent('  ');

class DioRequestLog extends ISpectifyLog {
  DioRequestLog(
    super.message, {
    required this.settings,
    required this.method,
    required this.url,
    required this.path,
    required this.headers,
    required this.body,
  }) : super(
          title: getKey,
          key: getKey,
          pen: settings.requestPen ?? (AnsiPen()..xterm(219)),
          data: {
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
  final ISpectifyDioLoggerSettings settings;

  static const getKey = 'http-request';

  @override
  String get textMessage {
    var msg = '[$title] [$method] $message';

    final data = body;

    try {
      if (settings.printRequestData && data != null) {
        final prettyData = _encoder.convert(data);
        msg += '\nData: $prettyData';
      }
      if (settings.printRequestHeaders && headers.isNotEmpty) {
        final prettyHeaders = _encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}

class DioResponseLog extends ISpectifyLog {
  DioResponseLog(
    super.message, {
    required this.settings,
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
          pen: settings.responsePen ?? (AnsiPen()..xterm(46)),
          data: {
            'method': method,
            'url': url,
            'path': path,
            'status_code': statusCode,
            'status_message': statusMessage,
            'request_headers': requestHeaders,
            'headers': headers,
            'request_body': requestBody,
            'response_body': responseBody,
          },
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
  final ISpectifyDioLoggerSettings settings;

  static const getKey = 'http-response';

  @override
  String get textMessage {
    var msg = '[$title] [$method] $message';

    final responseMessage = statusMessage;
    final data = responseBody;
    final headers = this.headers ?? {};

    msg += '\nStatus: $statusCode';

    if (settings.printResponseMessage && responseMessage != null) {
      msg += '\nMessage: $responseMessage';
    }

    try {
      if (settings.printResponseData && data != null) {
        final prettyData = _encoder.convert(data);
        msg += '\nData: $prettyData';
      }
      if (settings.printResponseHeaders && headers.isNotEmpty) {
        final prettyHeaders = _encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      return msg;
    }
    return msg;
  }
}

class DioErrorLog extends ISpectifyLog {
  DioErrorLog(
    super.title, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.requestHeaders,
    required this.headers,
    required this.body,
    required this.settings,
  }) : super(
          key: getKey,
          title: getKey,
          pen: settings.errorPen ?? (AnsiPen()..red()),
          data: {
            'method': method,
            'url': url,
            'path': path,
            'status_code': statusCode,
            'status_message': statusMessage,
            'request_headers': requestHeaders,
            'headers': headers,
            'body': body,
          },
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final ISpectifyDioLoggerSettings settings;

  static const getKey = 'http-error';

  @override
  String get textMessage {
    var msg = '[$title] [$method] $message';

    final responseMessage = statusMessage;

    final data = body;
    final headers = this.headers ?? {};

    if (statusCode != null) {
      msg += '\nStatus: $statusCode';
    }

    if (settings.printErrorMessage && responseMessage != null) {
      msg += '\nMessage: $responseMessage';
    }

    if (settings.printErrorData && data != null) {
      msg += '\nData: $data';
    }
    if (settings.printErrorHeaders && (headers.isNotEmpty)) {
      msg += '\nHeaders: $headers';
    }
    return msg;
  }
}
