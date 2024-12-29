import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

class TalkerHttpLogger extends InterceptorContract {
  TalkerHttpLogger({ISpectiy? iSpectify}) {
    _talker = iSpectify ?? ISpectiy();
  }

  late ISpectiy _talker;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    final message = '${request.url}';
    _talker.logCustom(HttpRequestLog(message, request: request));
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final message = '${response.request?.url}';

    if (response.statusCode >= 400 && response.statusCode < 600) {
      _talker.logCustom(HttpErrorLog(message, response: response));
    } else {
      _talker.logCustom(HttpResponseLog(message, response: response));
    }

    return response;
  }
}

const encoder = JsonEncoder.withIndent('  ');

class HttpRequestLog extends ISpectifyLog {
  HttpRequestLog(
    super.title, {
    required this.request,
  });

  final BaseRequest request;

  @override
  AnsiPen get pen => (AnsiPen()..xterm(219));

  @override
  String get key => ISpectifyLogType.httpRequest.key;

  @override
  String generateTextMessage({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    var msg = '[$title] [${request.method}] $message';

    final headers = request.headers;

    try {
      if (headers.isNotEmpty) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      // TODO: add handling can`t convert
    }
    return msg;
  }
}

class HttpResponseLog extends ISpectifyLog {
  HttpResponseLog(
    super.title, {
    required this.response,
  });

  final BaseResponse response;

  @override
  AnsiPen get pen => (AnsiPen()..xterm(46));

  @override
  String get key => ISpectifyLogType.httpResponse.key;

  @override
  String generateTextMessage({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    var msg = '[$title] [${response.request?.method}] $message';

    final headers = response.request?.headers;

    msg += '\nStatus: ${response.statusCode}';

    try {
      if (headers?.isNotEmpty ?? false) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      // TODO: add handling can`t convert
    }
    return msg;
  }
}

class HttpErrorLog extends ISpectifyLog {
  HttpErrorLog(
    super.title, {
    required this.response,
  });

  final BaseResponse response;

  @override
  AnsiPen get pen => AnsiPen()..red();

  @override
  String get key => ISpectifyLogType.httpError.key;

  @override
  String generateTextMessage({TimeFormat timeFormat = TimeFormat.timeAndSeconds}) {
    var msg = '[$title] [${response.request?.method}] $message';

    final headers = response.request?.headers;

    msg += '\nStatus: ${response.statusCode}';

    try {
      if (headers?.isNotEmpty ?? false) {
        final prettyHeaders = encoder.convert(headers);
        msg += '\nHeaders: $prettyHeaders';
      }
    } catch (_) {
      // TODO: add handling can`t convert
    }
    return msg;
  }
}
