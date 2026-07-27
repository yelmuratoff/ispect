import 'dart:convert';
import 'dart:typed_data';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';

/// Leaves room for the request/response envelope around a retained body.
const httpCaptureBodyMaxBytes = LogExportOutput.maxPreparedValueBytes ~/ 2;

class HttpRequestData {
  HttpRequestData(this.requestOptions);

  final BaseRequest? requestOptions;

  Map<String, dynamic> toJson({
    bool includeData = true,
    bool includeHeaders = true,
    bool redactionActive = false,
  }) {
    final request = requestOptions;
    final uriSnapshot =
        request == null ? null : NetworkUriSnapshot.fromUri(request.url);
    return <String, dynamic>{
      // --- Identity: what & where ---
      NetworkJsonKeys.method: request?.method,
      NetworkJsonKeys.url: uriSnapshot?.url,

      // --- Payload ---
      if (includeHeaders) NetworkJsonKeys.headers: requestOptions?.headers,
      NetworkJsonKeys.encoding: switch (requestOptions) {
        final Request request => _encodingName(request),
        _ => null,
      },
      if (includeData)
        NetworkJsonKeys.data: switch (requestOptions) {
          final Request request => _boundedBody(
              request,
              redactionActive: redactionActive,
            ),
          _ => null,
        },
      NetworkJsonKeys.contentLength: _contentLength(requestOptions),

      // --- Behaviour ---
      NetworkJsonKeys.followRedirects: requestOptions?.followRedirects,
      NetworkJsonKeys.maxRedirects: requestOptions?.maxRedirects,
      NetworkJsonKeys.persistentConnection:
          requestOptions?.persistentConnection,

      // --- State ---
      NetworkJsonKeys.finalized: requestOptions?.finalized,
    };
  }

  static int? _contentLength(BaseRequest? request) {
    if (request == null || request is MultipartRequest) return null;
    try {
      return request.contentLength;
    } on Object {
      return null;
    }
  }

  static String _encodingName(Request request) {
    try {
      return request.encoding.name;
    } on Object {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  static String _boundedBody(
    Request request, {
    required bool redactionActive,
  }) {
    try {
      final bytes = request.bodyBytes;
      if (bytes.isEmpty) return '';
      final oversized = bytes.lengthInBytes > httpCaptureBodyMaxBytes;
      if (oversized && redactionActive) {
        return LogExportOutput.truncatedMarker;
      }

      final markerBytes = LogExportOutput.utf8Length(
        LogExportOutput.truncatedMarker,
      );
      final prefixBytes = oversized
          ? httpCaptureBodyMaxBytes - markerBytes
          : bytes.lengthInBytes;
      final decoded = _decodePrefix(
        bytes,
        request.encoding,
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
      return bounded is String ? bounded : JsonValueNormalizer.unprintableValue;
    } on Object {
      return LogExportOutput.truncatedMarker;
    }
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
    throw const FormatException('Unable to decode request body');
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
    NetworkMapRedactor.redactFreeText(
      map,
      redactor,
      key: NetworkJsonKeys.encoding,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
    NetworkMapRedactor.redactUrl(map, redactor);
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
    NetworkMapRedactor.redactData(
      map,
      redactor,
      ignoredValues: ignoredValues,
      ignoredKeys: ignoredKeys,
    );
  }
}
