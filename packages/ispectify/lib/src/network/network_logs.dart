import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/enums/log_type.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/network/network_log_options.dart';
import 'package:ispectify/src/truncator.dart';
import 'package:ispectify/src/utils/string_extension.dart';

Map<String, dynamic>? _metadata(Map<String, Object?> source) {
  if (source.isEmpty) return null;
  return Map<String, dynamic>.from(source);
}

String _composeNetworkMessage(
  String header,
  List<String? Function()> sections,
) {
  final buffer = StringBuffer(header);
  for (final build in sections) {
    final content = build();
    if (content != null && content.isNotEmpty) {
      buffer.write('\n$content');
    }
  }
  return buffer.toString().truncate() ?? '';
}

String? _prettySection({
  required bool enabled,
  required String label,
  required Object? value,
  bool skipEmptyMap = false,
}) {
  if (!enabled || value == null) return null;
  if (skipEmptyMap && value is Map && value.isEmpty) return null;
  final formatted = JsonTruncatorService.pretty(value);
  return '$label: $formatted';
}

class NetworkRequestLog extends ISpectLogData {
  NetworkRequestLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.settings,
    Map<String, dynamic>? headers,
    this.body,
    String? logKey,
    Map<String, dynamic>? metadata,
    AnsiPen? pen,
  })  : headers = headers == null ? null : Map.unmodifiable(headers),
        logKey = logKey ?? ISpectLogType.httpRequest.key,
        super(
          key: logKey ?? ISpectLogType.httpRequest.key,
          title: logKey ?? ISpectLogType.httpRequest.key,
          pen: pen ??
              settings.requestPen ??
              ISpectLogType.httpRequest.defaultPen,
          additionalData: metadata ??
              _metadata(
                {
                  if (method != null) 'method': method,
                  if (url != null) 'url': url,
                  if (path != null) 'path': path,
                  if (headers != null) 'headers': headers,
                  if (body != null) 'body': body,
                },
              ),
        );

  final String? method;
  final String? url;
  final String? path;
  final Map<String, dynamic>? headers;
  final Object? body;
  final NetworkLogPrintOptions settings;
  final String logKey;

  @override
  String get textMessage {
    final header = '[${method ?? '-'}] ${message ?? ''}';
    return _composeNetworkMessage(
      header,
      [
        () => _prettySection(
              enabled: settings.printRequestData && body != null,
              label: 'Data',
              value: body,
            ),
        () => _prettySection(
              enabled: settings.printRequestHeaders &&
                  (headers?.isNotEmpty ?? false),
              label: 'Headers',
              value: headers,
              skipEmptyMap: true,
            ),
      ],
    );
  }
}

class NetworkResponseLog extends ISpectLogData {
  NetworkResponseLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.settings,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? requestBody,
    this.responseBody,
    String? logKey,
    Map<String, dynamic>? metadata,
    AnsiPen? pen,
  })  : requestHeaders =
            requestHeaders == null ? null : Map.unmodifiable(requestHeaders),
        headers = headers == null ? null : Map.unmodifiable(headers),
        requestBody =
            requestBody == null ? null : Map.unmodifiable(requestBody),
        logKey = logKey ?? ISpectLogType.httpResponse.key,
        super(
          key: logKey ?? ISpectLogType.httpResponse.key,
          title: logKey ?? ISpectLogType.httpResponse.key,
          pen: pen ??
              settings.responsePen ??
              ISpectLogType.httpResponse.defaultPen,
          additionalData: metadata ??
              _metadata(
                {
                  if (method != null) 'method': method,
                  if (url != null) 'url': url,
                  if (path != null) 'path': path,
                  if (statusCode != null) 'statusCode': statusCode,
                  if (statusMessage != null) 'statusMessage': statusMessage,
                  if (requestHeaders != null) 'requestHeaders': requestHeaders,
                  if (headers != null) 'headers': headers,
                  if (requestBody != null) 'requestBody': requestBody,
                  if (responseBody != null) 'responseBody': responseBody,
                },
              ),
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
  final NetworkLogPrintOptions settings;
  final String logKey;

  @override
  String get textMessage {
    final header = '[$logKey] [${method ?? '-'}] ${message ?? ''}';
    return _composeNetworkMessage(
      header,
      [
        () => statusCode != null ? 'Status: $statusCode' : null,
        () => settings.printResponseMessage && statusMessage != null
            ? 'Message: $statusMessage'
            : null,
        () => _prettySection(
              enabled: settings.printResponseData && responseBody != null,
              label: 'Data',
              value: responseBody,
            ),
        () => _prettySection(
              enabled: settings.printResponseHeaders &&
                  (headers?.isNotEmpty ?? false),
              label: 'Headers',
              value: headers,
              skipEmptyMap: true,
            ),
      ],
    );
  }
}

class NetworkErrorLog extends ISpectLogData {
  NetworkErrorLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required this.statusCode,
    required this.statusMessage,
    required this.settings,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
    Object? capturedException,
    StackTrace? capturedStackTrace,
    String? logKey,
    Map<String, dynamic>? metadata,
    AnsiPen? pen,
  })  : requestHeaders =
            requestHeaders == null ? null : Map.unmodifiable(requestHeaders),
        headers = headers == null ? null : Map.unmodifiable(headers),
        body = body == null ? null : Map.unmodifiable(body),
        logKey = logKey ?? ISpectLogType.httpError.key,
        super(
          key: logKey ?? ISpectLogType.httpError.key,
          title: logKey ?? ISpectLogType.httpError.key,
          pen: pen ?? settings.errorPen ?? ISpectLogType.httpError.defaultPen,
          logLevel: LogLevel.error,
          exception: capturedException,
          stackTrace: capturedStackTrace,
          additionalData: metadata ??
              _metadata(
                {
                  if (method != null) 'method': method,
                  if (url != null) 'url': url,
                  if (path != null) 'path': path,
                  if (statusCode != null) 'statusCode': statusCode,
                  if (statusMessage != null) 'statusMessage': statusMessage,
                  if (requestHeaders != null) 'requestHeaders': requestHeaders,
                  if (headers != null) 'headers': headers,
                  if (body != null) 'body': body,
                  if (capturedException != null)
                    'exception': '$capturedException',
                  if (capturedStackTrace != null)
                    'stackTrace': '$capturedStackTrace',
                },
              ),
        );

  final String? method;
  final String? url;
  final String? path;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? body;
  final NetworkLogPrintOptions settings;
  final String logKey;

  @override
  String get textMessage {
    final header = '[${method ?? '-'}] ${message ?? ''}';
    return _composeNetworkMessage(
      header,
      [
        () => statusCode != null ? 'Status: $statusCode' : null,
        () => settings.printErrorMessage && statusMessage != null
            ? 'Message: $statusMessage'
            : null,
        () => _prettySection(
              enabled: settings.printErrorData && (body?.isNotEmpty ?? false),
              label: 'Data',
              value: body,
              skipEmptyMap: true,
            ),
        () => _prettySection(
              enabled:
                  settings.printErrorHeaders && (headers?.isNotEmpty ?? false),
              label: 'Headers',
              value: headers,
              skipEmptyMap: true,
            ),
      ],
    );
  }
}
