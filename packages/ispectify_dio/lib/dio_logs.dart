import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'ispectify_dio.dart';

const _encoder = JsonEncoder.withIndent('  ');

class DioRequestLog extends ISpectifyLog {
  DioRequestLog(
    super.message, {
    required this.requestOptions,
    required this.settings,
  });

  final RequestOptions requestOptions;
  final ISpectifyDioLoggerSettings settings;

  @override
  AnsiPen get pen => settings.requestPen ?? (AnsiPen()..xterm(219));

  @override
  String get key => ISpectifyLogType.httpRequest.key;

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    var msg = '[$title] [${requestOptions.method}] $message';

    final data = requestOptions.data;
    final headers = requestOptions.headers;

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
      // TODO: add handling can`t convert
    }
    return msg;
  }
}

class DioResponseLog extends ISpectifyLog {
  DioResponseLog(
    super.message, {
    required this.response,
    required this.settings,
  });

  final Response<dynamic> response;
  final ISpectifyDioLoggerSettings settings;

  @override
  AnsiPen get pen => settings.responsePen ?? (AnsiPen()..xterm(46));

  @override
  String get key => ISpectifyLogType.httpResponse.key;

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    var msg = '[$title] [${response.requestOptions.method}] $message';

    final responseMessage = response.statusMessage;
    final data = response.data;
    final headers = response.headers.map;

    msg += '\nStatus: ${response.statusCode}';

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
      // TODO: add handling can`t convert
    }
    return msg;
  }
}

class DioErrorLog extends ISpectifyLog {
  DioErrorLog(
    super.title, {
    required this.dioException,
    required this.settings,
  });

  final DioException dioException;
  final ISpectifyDioLoggerSettings settings;

  @override
  AnsiPen get pen => settings.errorPen ?? (AnsiPen()..red());

  @override
  String get key => ISpectifyLogType.httpError.key;

  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    var msg = '[$title] [${dioException.requestOptions.method}] $message';

    final responseMessage = dioException.message;
    final statusCode = dioException.response?.statusCode;
    final data = dioException.response?.data;
    final headers = dioException.response?.headers;

    if (statusCode != null) {
      msg += '\nStatus: ${dioException.response?.statusCode}';
    }

    if (settings.printErrorMessage && responseMessage != null) {
      msg += '\nMessage: $responseMessage';
    }

    if (settings.printErrorData && data != null) {
      final prettyData = _encoder.convert(data);
      msg += '\nData: $prettyData';
    }
    if (settings.printErrorHeaders && !(headers?.isEmpty ?? true)) {
      final prettyHeaders = _encoder.convert(headers!.map);
      msg += '\nHeaders: $prettyHeaders';
    }
    return msg;
  }
}
