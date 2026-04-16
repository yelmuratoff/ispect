import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/network/network_log_options.dart';
import 'package:ispectify/src/utils/json_truncator.dart';
import 'package:ispectify/src/utils/string_extension.dart';

/// Key used to store the request ID in [ISpectLogData.additionalData].
const String kRequestIdKey = 'request-id';

Map<String, dynamic>? _metadata(Map<String, Object?> source) {
  if (source.isEmpty) return null;
  return Map<String, dynamic>.from(source);
}

/// Injects [requestId] into [base] metadata if non-null.
Map<String, dynamic>? _withRequestId(
  Map<String, dynamic>? base,
  String? requestId,
) {
  if (requestId == null) return base;
  if (base == null) return {kRequestIdKey: requestId};
  return {...base, kRequestIdKey: requestId};
}

String _composeNetworkMessage(
  String header,
  List<String?> sections,
) {
  final buffer = StringBuffer(header);
  for (final content in sections) {
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
  final formatted = JsonTruncator.pretty(value);
  return '$label: $formatted';
}

/// Builds the textMessage for a [NetworkRequestLog].
String _buildRequestText({
  required String? method,
  required String? message,
  required NetworkLogPrintOptions settings,
  required Object? body,
  required Map<String, dynamic>? headers,
}) =>
    _composeNetworkMessage(
      '[${method ?? '-'}] ${message ?? ''}',
      [
        _prettySection(
          enabled: settings.printRequestData && body != null,
          label: 'Data',
          value: body,
        ),
        _prettySection(
          enabled:
              settings.printRequestHeaders && (headers?.isNotEmpty ?? false),
          label: 'Headers',
          value: headers,
          skipEmptyMap: true,
        ),
      ],
    );

/// Builds the textMessage for a [NetworkResponseLog].
String _buildResponseText({
  required String? method,
  required String? message,
  required NetworkLogPrintOptions settings,
  required int? statusCode,
  required String? statusMessage,
  required Object? responseBody,
  required Map<String, dynamic>? headers,
}) =>
    _composeNetworkMessage(
      '[${method ?? '-'}] ${message ?? ''}',
      [
        if (statusCode != null) 'Status: $statusCode',
        if (settings.printResponseMessage && statusMessage != null)
          'Message: $statusMessage',
        _prettySection(
          enabled: settings.printResponseData && responseBody != null,
          label: 'Data',
          value: responseBody,
        ),
        _prettySection(
          enabled:
              settings.printResponseHeaders && (headers?.isNotEmpty ?? false),
          label: 'Headers',
          value: headers,
          skipEmptyMap: true,
        ),
      ],
    );

/// Builds the textMessage for a [NetworkErrorLog].
String _buildErrorText({
  required String? method,
  required String? message,
  required NetworkLogPrintOptions settings,
  required int? statusCode,
  required String? statusMessage,
  required Map<String, dynamic>? body,
  required Map<String, dynamic>? headers,
}) =>
    _composeNetworkMessage(
      '[${method ?? '-'}] ${message ?? ''}',
      [
        if (statusCode != null) 'Status: $statusCode',
        if (settings.printErrorMessage && statusMessage != null)
          'Message: $statusMessage',
        _prettySection(
          enabled: settings.printErrorData && (body?.isNotEmpty ?? false),
          label: 'Data',
          value: body,
          skipEmptyMap: true,
        ),
        _prettySection(
          enabled: settings.printErrorHeaders && (headers?.isNotEmpty ?? false),
          label: 'Headers',
          value: headers,
          skipEmptyMap: true,
        ),
      ],
    );

/// Common base for network log entries (request, response, error).
///
/// Extracts shared fields and constructor logic. The common metadata fields
/// (`method`, `url`, `path`) are auto-included — subclasses only provide
/// their specific extra entries via [extraMetadata].
abstract base class BaseNetworkLog extends ISpectLogData {
  BaseNetworkLog(
    super.message, {
    required this.method,
    required this.url,
    required this.path,
    required String defaultLogKey,
    required AnsiPen defaultPen,
    required String textMessage,
    this.requestId,
    String? logKey,
    AnsiPen? pen,
    super.logLevel,
    super.exception,
    super.stackTrace,
    Map<String, dynamic>? metadata,
    Map<String, Object?> extraMetadata = const {},
  })  : logKey = logKey ?? defaultLogKey,
        _textMessage = textMessage,
        super(
          key: logKey ?? defaultLogKey,
          pen: pen ?? defaultPen,
          additionalData: _withRequestId(
            metadata ??
                _metadata({
                  if (method != null) 'method': method,
                  if (url != null) 'url': url,
                  if (path != null) 'path': path,
                  ...extraMetadata,
                }),
            requestId,
          ),
        );

  /// Unique ID correlating this log with related request/response/error.
  final String? requestId;

  final String? method;
  final String? url;
  final String? path;
  final String logKey;

  final String _textMessage;

  @override
  String get textMessage => _textMessage;
}

base class NetworkRequestLog extends BaseNetworkLog {
  NetworkRequestLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required NetworkLogPrintOptions settings,
    super.requestId,
    Map<String, dynamic>? headers,
    this.body,
    super.logKey,
    super.metadata,
    super.pen,
    String? textMessage,
  })  : headers = headers == null ? null : Map.unmodifiable(headers),
        super(
          defaultLogKey: ISpectLogType.httpRequest.key,
          defaultPen:
              settings.requestPen ?? ISpectLogType.httpRequest.defaultPen,
          textMessage: textMessage ??
              _buildRequestText(
                method: method,
                message: message?.toString(),
                settings: settings,
                body: body,
                headers: headers,
              ),
          extraMetadata: {
            if (headers != null) 'headers': headers,
            if (body != null) 'body': body,
          },
        );

  final Map<String, dynamic>? headers;
  final Object? body;
}

base class NetworkResponseLog extends BaseNetworkLog {
  NetworkResponseLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required this.statusCode,
    required this.statusMessage,
    required NetworkLogPrintOptions settings,
    super.requestId,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? requestBody,
    this.responseBody,
    super.logKey,
    super.metadata,
    super.pen,
    String? textMessage,
  })  : requestHeaders =
            requestHeaders == null ? null : Map.unmodifiable(requestHeaders),
        headers = headers == null ? null : Map.unmodifiable(headers),
        requestBody =
            requestBody == null ? null : Map.unmodifiable(requestBody),
        super(
          defaultLogKey: ISpectLogType.httpResponse.key,
          defaultPen:
              settings.responsePen ?? ISpectLogType.httpResponse.defaultPen,
          textMessage: textMessage ??
              _buildResponseText(
                method: method,
                message: message?.toString(),
                settings: settings,
                statusCode: statusCode,
                statusMessage: statusMessage,
                responseBody: responseBody,
                headers: headers,
              ),
          extraMetadata: {
            if (statusCode != null) 'statusCode': statusCode,
            if (statusMessage != null) 'statusMessage': statusMessage,
            if (requestHeaders != null) 'requestHeaders': requestHeaders,
            if (headers != null) 'headers': headers,
            if (requestBody != null) 'requestBody': requestBody,
            if (responseBody != null) 'responseBody': responseBody,
          },
        );

  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? requestBody;
  final Object? responseBody;
}

base class NetworkErrorLog extends BaseNetworkLog {
  NetworkErrorLog(
    super.message, {
    required super.method,
    required super.url,
    required super.path,
    required this.statusCode,
    required this.statusMessage,
    required NetworkLogPrintOptions settings,
    super.requestId,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
    Object? capturedException,
    StackTrace? capturedStackTrace,
    super.logKey,
    super.metadata,
    super.pen,
    String? textMessage,
  })  : requestHeaders =
            requestHeaders == null ? null : Map.unmodifiable(requestHeaders),
        headers = headers == null ? null : Map.unmodifiable(headers),
        body = body == null ? null : Map.unmodifiable(body),
        super(
          defaultLogKey: ISpectLogType.httpError.key,
          defaultPen: settings.errorPen ?? ISpectLogType.httpError.defaultPen,
          logLevel: LogLevel.error,
          exception: capturedException,
          stackTrace: capturedStackTrace,
          textMessage: textMessage ??
              _buildErrorText(
                method: method,
                message: message?.toString(),
                settings: settings,
                statusCode: statusCode,
                statusMessage: statusMessage,
                body: body,
                headers: headers,
              ),
          extraMetadata: {
            if (statusCode != null) 'statusCode': statusCode,
            if (statusMessage != null) 'statusMessage': statusMessage,
            if (requestHeaders != null) 'requestHeaders': requestHeaders,
            if (headers != null) 'headers': headers,
            if (body != null) 'body': body,
            if (capturedException != null) 'exception': '$capturedException',
            if (capturedStackTrace != null) 'stackTrace': '$capturedStackTrace',
          },
        );

  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? body;
}
