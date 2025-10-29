import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/enums/log_type.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/network/network_log_options.dart';
import 'package:ispectify/src/truncator.dart';
import 'package:ispectify/src/utils/string_extension.dart';

Map<String, dynamic> _mapFromEntries(
  Iterable<MapEntry<String, Object?>> entries,
) {
  final data = <String, dynamic>{};
  for (final entry in entries) {
    data[entry.key] = entry.value;
  }
  return data;
}

class NetworkRequestLog extends ISpectifyData {
  NetworkRequestLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required NetworkLogPrintOptions settings,
    Map<String, dynamic>? headers,
    Object? body,
    String? logKey,
    Map<String, dynamic>? metadata,
    AnsiPen? pen,
  })  : _headers = headers,
        _body = body,
        _settings = settings,
        _logKey = logKey ?? ISpectifyLogType.httpRequest.key,
        super(
          key: logKey ?? ISpectifyLogType.httpRequest.key,
          title: logKey ?? ISpectifyLogType.httpRequest.key,
          pen: pen ?? settings.requestPen ?? ISpectifyLogType.httpRequest.defaultPen,
          additionalData: metadata ??
              _mapFromEntries(
                [
                  if (method != null) MapEntry('method', method),
                  if (url != null) MapEntry('url', url),
                  if (path != null) MapEntry('path', path),
                  if (headers != null) MapEntry('headers', headers),
                  if (body != null) MapEntry('body', body),
                ],
              ),
        );

  final String? method;
  final String? url;
  final String? path;

  final Map<String, dynamic>? _headers;
  final Object? _body;
  final NetworkLogPrintOptions _settings;
  final String _logKey;

  Map<String, dynamic>? get headers {
    final headers = _headers;
    return headers == null ? null : Map<String, dynamic>.from(headers);
  }

  Object? get body => _body;

  NetworkLogPrintOptions get settings => _settings;

  @override
  String get textMessage {
    final buffer = StringBuffer('[${method ?? '-'}] ${message ?? ''}');

    if (_settings.printRequestData && _body != null) {
      final prettyData = JsonTruncatorService.pretty(_body);
      buffer.write('\nData: $prettyData');
    }

    final headers = _headers;
    if (_settings.printRequestHeaders &&
        headers != null &&
        headers.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(headers);
      buffer.write('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncate() ?? '';
  }

  String get logKey => _logKey;
}

class NetworkResponseLog extends ISpectifyData {
  NetworkResponseLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required NetworkLogPrintOptions settings,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? requestBody,
    Object? responseBody,
    String? logKey,
    Map<String, dynamic>? metadata,
    AnsiPen? pen,
  })  : _requestHeaders = requestHeaders,
        _headers = headers,
        _requestBody = requestBody,
        _responseBody = responseBody,
        _settings = settings,
        _logKey = logKey ?? ISpectifyLogType.httpResponse.key,
        super(
          key: logKey ?? ISpectifyLogType.httpResponse.key,
          title: logKey ?? ISpectifyLogType.httpResponse.key,
          pen: pen ?? settings.responsePen ?? ISpectifyLogType.httpResponse.defaultPen,
          additionalData: metadata ??
              _mapFromEntries(
                [
                  if (method != null) MapEntry('method', method),
                  if (url != null) MapEntry('url', url),
                  if (path != null) MapEntry('path', path),
                  if (statusCode != null) MapEntry('statusCode', statusCode),
                  if (statusMessage != null)
                    MapEntry('statusMessage', statusMessage),
                  if (requestHeaders != null)
                    MapEntry('requestHeaders', requestHeaders),
                  if (headers != null) MapEntry('headers', headers),
                  if (requestBody != null) MapEntry('requestBody', requestBody),
                  if (responseBody != null)
                    MapEntry('responseBody', responseBody),
                ],
              ),
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;

  final Map<String, dynamic>? _requestHeaders;
  final Map<String, dynamic>? _headers;
  final Map<String, dynamic>? _requestBody;
  final Object? _responseBody;
  final NetworkLogPrintOptions _settings;
  final String _logKey;

  Map<String, dynamic>? get requestHeaders {
    final headers = _requestHeaders;
    return headers == null ? null : Map<String, dynamic>.from(headers);
  }

  Map<String, dynamic>? get headers {
    final headers = _headers;
    return headers == null ? null : Map<String, dynamic>.from(headers);
  }

  Map<String, dynamic>? get requestBody {
    final body = _requestBody;
    return body == null ? null : Map<String, dynamic>.from(body);
  }

  Object? get responseBody => _responseBody;

  NetworkLogPrintOptions get settings => _settings;

  @override
  String get textMessage {
    final buffer =
        StringBuffer('[$_logKey] [${method ?? '-'}] ${message ?? ''}');

    if (statusCode != null) {
      buffer.write('\nStatus: $statusCode');
    }

    if (_settings.printResponseMessage && statusMessage != null) {
      buffer.write('\nMessage: $statusMessage');
    }

    if (_settings.printResponseData && _responseBody != null) {
      final prettyData = JsonTruncatorService.pretty(_responseBody);
      buffer.write('\nData: $prettyData');
    }

    final headers = _headers;
    if (_settings.printResponseHeaders &&
        headers != null &&
        headers.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(headers);
      buffer.write('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncate() ?? '';
  }

  String get logKey => _logKey;
}

class NetworkErrorLog extends ISpectifyData {
  NetworkErrorLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required NetworkLogPrintOptions settings,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
    Object? capturedException,
    StackTrace? capturedStackTrace,
    String? logKey,
    Map<String, dynamic>? metadata,
    AnsiPen? pen,
  })  : _requestHeaders = requestHeaders,
        _headers = headers,
        _body = body,
        _settings = settings,
        _logKey = logKey ?? ISpectifyLogType.httpError.key,
        super(
          key: logKey ?? ISpectifyLogType.httpError.key,
          title: logKey ?? ISpectifyLogType.httpError.key,
          pen: pen ?? settings.errorPen ?? ISpectifyLogType.httpError.defaultPen,
          logLevel: LogLevel.error,
          exception: capturedException,
          stackTrace: capturedStackTrace,
          additionalData: metadata ??
              _mapFromEntries(
                [
                  if (method != null) MapEntry('method', method),
                  if (url != null) MapEntry('url', url),
                  if (path != null) MapEntry('path', path),
                  if (statusCode != null) MapEntry('statusCode', statusCode),
                  if (statusMessage != null)
                    MapEntry('statusMessage', statusMessage),
                  if (requestHeaders != null)
                    MapEntry('requestHeaders', requestHeaders),
                  if (headers != null) MapEntry('headers', headers),
                  if (body != null) MapEntry('body', body),
                  if (capturedException != null)
                    MapEntry('exception', '$capturedException'),
                  if (capturedStackTrace != null)
                    MapEntry('stackTrace', '$capturedStackTrace'),
                ],
              ),
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;

  final Map<String, dynamic>? _requestHeaders;
  final Map<String, dynamic>? _headers;
  final Map<String, dynamic>? _body;
  final NetworkLogPrintOptions _settings;
  final String _logKey;

  Map<String, dynamic>? get requestHeaders {
    final headers = _requestHeaders;
    return headers == null ? null : Map<String, dynamic>.from(headers);
  }

  Map<String, dynamic>? get headers {
    final headers = _headers;
    return headers == null ? null : Map<String, dynamic>.from(headers);
  }

  Map<String, dynamic>? get body {
    final bodyData = _body;
    return bodyData == null ? null : Map<String, dynamic>.from(bodyData);
  }

  NetworkLogPrintOptions get settings => _settings;

  @override
  String get textMessage {
    final buffer = StringBuffer('[${method ?? '-'}] ${message ?? ''}');

    if (statusCode != null) {
      buffer.write('\nStatus: $statusCode');
    }

    if (_settings.printErrorMessage && statusMessage != null) {
      buffer.write('\nMessage: $statusMessage');
    }

    final bodyData = _body;
    if (_settings.printErrorData && bodyData != null && bodyData.isNotEmpty) {
      final prettyData = JsonTruncatorService.pretty(bodyData);
      buffer.write('\nData: $prettyData');
    }

    final headers = _headers;
    if (_settings.printErrorHeaders && headers != null && headers.isNotEmpty) {
      final prettyHeaders = JsonTruncatorService.pretty(headers);
      buffer.write('\nHeaders: $prettyHeaders');
    }

    return buffer.toString().truncate() ?? '';
  }

  String get logKey => _logKey;
}
