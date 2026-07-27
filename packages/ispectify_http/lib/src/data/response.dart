import 'dart:convert';
import 'dart:typed_data';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/src/data/request.dart';
import 'package:ispectify_http/src/utils/multipart_serializer.dart';

const _bodyNotPrepared = _BodyNotPrepared();

class HttpResponseData {
  HttpResponseData({
    required this.response,
    required this.baseResponse,
    required this.requestData,
    required this.multipartRequest,
    Object? preDecodedBody = _bodyNotPrepared,
  }) : _preDecodedBody = preDecodedBody;

  final BaseResponse baseResponse;
  final Response? response;
  final MultipartRequest? multipartRequest;
  final HttpRequestData requestData;

  /// Optional prepared body to avoid repeated bounded byte decoding.
  /// When provided, [toJson] snapshots this value instead of inspecting
  /// [response.bodyBytes].
  final Object? _preDecodedBody;

  Object? get preDecodedBody =>
      identical(_preDecodedBody, _bodyNotPrepared) ? null : _preDecodedBody;

  Map<String, dynamic> toJson({
    bool includeData = true,
    bool includeHeaders = true,
    bool includeMessage = true,
    bool includeRequestData = true,
    bool includeRequestHeaders = true,
    bool redactionActive = false,
  }) {
    final resp = response;
    final multipart = multipartRequest;
    final payload = includeData && resp != null
        ? _preparePayload(resp, redactionActive: redactionActive)
        : null;
    final request = baseResponse.request;
    final uriSnapshot =
        request == null ? null : NetworkUriSnapshot.fromUri(request.url);
    return <String, dynamic>{
      // --- Status: first thing you check ---
      NetworkJsonKeys.statusCode: baseResponse.statusCode,
      if (includeMessage)
        NetworkJsonKeys.statusMessage: baseResponse.reasonPhrase,

      // --- Identity ---
      NetworkJsonKeys.method: request?.method,
      NetworkJsonKeys.url: uriSnapshot?.url,

      // --- Payload ---
      if (includeHeaders) NetworkJsonKeys.headers: baseResponse.headers,
      if (payload != null) NetworkJsonKeys.body: payload.body,
      if (payload != null)
        NetworkJsonKeys.bodyBytes: payload.bodyBytes.toString(),
      NetworkJsonKeys.contentLength: baseResponse.contentLength,

      // --- Redirects ---
      NetworkJsonKeys.isRedirect: baseResponse.isRedirect,

      // --- Behaviour ---
      NetworkJsonKeys.persistentConnection: baseResponse.persistentConnection,

      // --- Multipart (if applicable) ---
      if (includeRequestData && multipart != null)
        NetworkJsonKeys.multipartRequest: HttpMultipartSerializer.serialize(
          multipart,
          redactionActive: redactionActive,
        ),

      // --- Original request (reference) ---
      NetworkJsonKeys.request: requestData.toJson(
        includeData: includeRequestData,
        includeHeaders: includeRequestHeaders,
        redactionActive: redactionActive,
      ),
    };
  }

  static void redact(
    Map<String, dynamic> map,
    RedactionService redactor, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  }) {
    NetworkMapRedactor.redactMethod(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactUrl(map, redactor);
    NetworkMapRedactor.redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.statusMessage,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    final redactedHeaders = NetworkMapRedactor.redactHeaders(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    if (redactedHeaders != null) {
      map[NetworkJsonKeys.headers] =
          redactedHeaders.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    NetworkMapRedactor.redactMultipart(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    NetworkMapRedactor.redactData(
      map,
      redactor,
      key: NetworkJsonKeys.body,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );

    final requestMap = map[NetworkJsonKeys.request];
    if (requestMap is Map<String, dynamic>) {
      HttpRequestData.redact(
        requestMap,
        redactor,
        ignoredValues: ignoredValues,
        ignoredKeys: ignoredKeys,
      );
    }
  }

  _PreparedHttpBody _preparePayload(
    Response response, {
    required bool redactionActive,
  }) {
    try {
      final bytes = response.bodyBytes;
      final prepared = identical(_preDecodedBody, _bodyNotPrepared)
          ? _decodeBody(
              bytes,
              response.headers,
              redactionActive: redactionActive,
            )
          : LogExportOutput.boundJsonValue(
              _preDecodedBody,
              maxBytes: httpCaptureBodyMaxBytes,
              replaceOversizedStrings: redactionActive,
            );
      return (body: prepared, bodyBytes: bytes.lengthInBytes);
    } on Object {
      return (
        body: LogExportOutput.truncatedMarker,
        bodyBytes: baseResponse.contentLength ?? 0,
      );
    }
  }

  static Object? _decodeBody(
    Uint8List bytes,
    Map<String, String> headers, {
    required bool redactionActive,
  }) {
    if (bytes.isEmpty) return null;
    final oversized = bytes.lengthInBytes > httpCaptureBodyMaxBytes;
    if (oversized && redactionActive) {
      return LogExportOutput.truncatedMarker;
    }

    final markerBytes = LogExportOutput.utf8Length(
      LogExportOutput.truncatedMarker,
    );
    final prefixBytes =
        oversized ? httpCaptureBodyMaxBytes - markerBytes : bytes.lengthInBytes;
    final decoded = _decodePrefix(
      bytes,
      _encodingFor(headers),
      prefixBytes,
      recoverTruncatedCodePoint: oversized,
    );
    final withMarker =
        oversized ? '$decoded${LogExportOutput.truncatedMarker}' : decoded;
    final bounded = LogExportOutput.boundJsonValue(
      withMarker,
      maxBytes: httpCaptureBodyMaxBytes,
      replaceOversizedStrings: redactionActive,
    );
    return NetworkPayloadSanitizer.decodeJsonGracefully(bounded);
  }

  static Encoding _encodingFor(Map<String, String> headers) {
    final rawContentType = headers['content-type'];
    if (rawContentType == null) return latin1;
    final contentType = MediaType.parse(rawContentType);
    final charset = contentType.parameters['charset'];
    if (charset != null) {
      return Encoding.getByName(charset) ??
          (throw const FormatException('Unsupported response charset'));
    }
    if (contentType.type == 'application' && contentType.subtype == 'json') {
      return utf8;
    }
    return latin1;
  }

  static String _decodePrefix(
    Uint8List bytes,
    Encoding encoding,
    int end, {
    required bool recoverTruncatedCodePoint,
  }) {
    Object? lastError;
    final attempts = recoverTruncatedCodePoint ? 4 : 1;
    for (var removed = 0; removed < attempts && end - removed >= 0; removed++) {
      try {
        return encoding.decode(
          Uint8List.sublistView(bytes, 0, end - removed),
        );
      } on FormatException catch (error) {
        lastError = error;
      }
    }
    if (lastError case final FormatException error) throw error;
    throw const FormatException('Unable to decode response body');
  }
}

typedef _PreparedHttpBody = ({Object? body, int bodyBytes});

final class _BodyNotPrepared {
  const _BodyNotPrepared();
}
