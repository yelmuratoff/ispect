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

Map<String, dynamic>? _cloneMap(Map<String, dynamic>? source) =>
    source == null ? null : Map<String, dynamic>.from(source);

void _appendPrettySection({
  required StringBuffer buffer,
  required bool shouldPrint,
  required String label,
  required Object? value,
}) {
  if (!shouldPrint || value == null) return;
  if (value is Map && value.isEmpty) return;

  final formatted = JsonTruncatorService.pretty(value);
  buffer.write('\n$label: $formatted');
}

class NetworkRequestLog extends ISpectLogData {
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
        _logKey = logKey ?? ISpectLogType.httpRequest.key,
        super(
          key: logKey ?? ISpectLogType.httpRequest.key,
          title: logKey ?? ISpectLogType.httpRequest.key,
          pen: pen ??
              settings.requestPen ??
              ISpectLogType.httpRequest.defaultPen,
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

  Map<String, dynamic>? get headers => _cloneMap(_headers);

  Object? get body => _body;

  NetworkLogPrintOptions get settings => _settings;

  @override
  String get textMessage {
    final buffer = StringBuffer('[${method ?? '-'}] ${message ?? ''}');

    _appendPrettySection(
      buffer: buffer,
      shouldPrint: _settings.printRequestData && _body != null,
      label: 'Data',
      value: _body,
    );
    _appendPrettySection(
      buffer: buffer,
      shouldPrint:
          _settings.printRequestHeaders && (_headers?.isNotEmpty ?? false),
      label: 'Headers',
      value: _headers,
    );

    return buffer.toString().truncate() ?? '';
  }

  String get logKey => _logKey;
}

class NetworkResponseLog extends ISpectLogData {
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
        _logKey = logKey ?? ISpectLogType.httpResponse.key,
        super(
          key: logKey ?? ISpectLogType.httpResponse.key,
          title: logKey ?? ISpectLogType.httpResponse.key,
          pen: pen ??
              settings.responsePen ??
              ISpectLogType.httpResponse.defaultPen,
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

  Map<String, dynamic>? get requestHeaders => _cloneMap(_requestHeaders);

  Map<String, dynamic>? get headers => _cloneMap(_headers);

  Map<String, dynamic>? get requestBody => _cloneMap(_requestBody);

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

    _appendPrettySection(
      buffer: buffer,
      shouldPrint: _settings.printResponseData && _responseBody != null,
      label: 'Data',
      value: _responseBody,
    );
    _appendPrettySection(
      buffer: buffer,
      shouldPrint:
          _settings.printResponseHeaders && (_headers?.isNotEmpty ?? false),
      label: 'Headers',
      value: _headers,
    );

    return buffer.toString().truncate() ?? '';
  }

  String get logKey => _logKey;
}

class NetworkErrorLog extends ISpectLogData {
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
        _logKey = logKey ?? ISpectLogType.httpError.key,
        super(
          key: logKey ?? ISpectLogType.httpError.key,
          title: logKey ?? ISpectLogType.httpError.key,
          pen: pen ?? settings.errorPen ?? ISpectLogType.httpError.defaultPen,
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

  Map<String, dynamic>? get requestHeaders => _cloneMap(_requestHeaders);

  Map<String, dynamic>? get headers => _cloneMap(_headers);

  Map<String, dynamic>? get body => _cloneMap(_body);

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

    _appendPrettySection(
      buffer: buffer,
      shouldPrint: _settings.printErrorData && (_body?.isNotEmpty ?? false),
      label: 'Data',
      value: _body,
    );
    _appendPrettySection(
      buffer: buffer,
      shouldPrint:
          _settings.printErrorHeaders && (_headers?.isNotEmpty ?? false),
      label: 'Headers',
      value: _headers,
    );

    return buffer.toString().truncate() ?? '';
  }

  String get logKey => _logKey;
}
