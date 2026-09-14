import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';

/// Utility class for generating cURL commands from HTTP request data.
abstract final class CurlUtils {
  /// Generates a cURL command string from the provided request data.
  ///
  /// - [data]: A map containing request details such as 'uri', 'method',
  ///   'headers', 'data'.
  /// - [redactor]: Optional custom redaction policy. A default
  ///   [RedactionService] is used when omitted.
  /// - [enableRedaction]: Explicitly set to `false` only for controlled local
  ///   debugging when raw request values are required.
  ///
  /// With redaction enabled, the method is treated as free-form diagnostic
  /// text, the URL is passed through [RedactionService.redactUrl], header
  /// values through [RedactionService.redactHeaders], and the body through the
  /// shared network payload sanitizer before being written to the command.
  ///
  /// Returns `null` if the data is insufficient to generate a valid cURL
  /// command.
  static String? generateCurl(
    Map<String, dynamic>? data, {
    RedactionService? redactor,
    bool enableRedaction = true,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (data == null) return null;
    try {
      resourceLimits.validate();
      final redactionActive = enableRedaction && ISpectRedaction.enabled;
      final effectiveRedactor = redactionActive
          ? ISpectRedaction.resolveService(service: redactor)
          : null;
      final uriValue = data['uri'];
      final urlValue = data['url'];
      final methodValue = data['method'];
      final rawUri = uriValue is String
          ? uriValue
          : urlValue is String
              ? urlValue
              : null;
      if (rawUri == null || methodValue is! String) return null;

      final uri = _boundString(
        rawUri,
        redactionActive: redactionActive,
        resourceLimits: resourceLimits,
      );
      final boundedMethod = _boundString(
        methodValue,
        redactionActive: redactionActive,
        resourceLimits: resourceLimits,
      );
      final method = effectiveRedactor == null
          ? boundedMethod
          : NetworkMapRedactor.redactFreeTextValue(
              boundedMethod,
              effectiveRedactor,
            );
      final redactedUri =
          effectiveRedactor == null ? uri : effectiveRedactor.redactUrl(uri);
      final safeUri = _boundString(
        redactedUri,
        redactionActive: redactionActive,
        resourceLimits: resourceLimits,
      );
      final buffer = _CurlCommandBuffer(resourceLimits.maxLogRecordBytes);
      final base =
          'curl -X ${_shellEscape(method)} --url ${_shellEscape(safeUri)}';
      if (!buffer.write(base)) {
        return "curl -X '${LogExportOutput.truncatedMarker}' "
            "--url '${LogExportOutput.truncatedMarker}'";
      }

      final rawBody = LogExportOutput.boundJsonValue(
        data['data'],
        resourceLimits: resourceLimits,
        preserveTypes: redactionActive,
        replaceOversizedStrings: redactionActive,
      );
      final rawHeaders = _coerceHeaders(
        data['headers'],
        redactionActive: redactionActive,
        resourceLimits: resourceLimits,
      );
      final redactedHeaders = rawHeaders == null
          ? null
          : effectiveRedactor == null
              ? rawHeaders
              : NetworkPayloadSanitizer(
                  effectiveRedactor,
                  resourceLimits: resourceLimits,
                ).headersMap(
                  rawHeaders,
                  enableRedaction: true,
                );
      final boundedHeaders = LogExportOutput.boundJsonValue(
        redactedHeaders,
        resourceLimits: resourceLimits,
        preserveTypes: redactionActive,
        replaceOversizedStrings: redactionActive,
      );
      final headers = boundedHeaders is Map<String, Object?>
          ? boundedHeaders
          : boundedHeaders is Map
              ? Map<String, Object?>.from(boundedHeaders)
              : null;
      var truncated = false;
      if (headers != null) {
        var emittedHeaders = 0;
        for (final entry in headers.entries) {
          if (emittedHeaders >= resourceLimits.maxNetworkHeaders) {
            truncated = true;
            break;
          }
          final key = entry.key;
          final value = entry.value;
          if (rawBody != null && key.toLowerCase() == 'content-length') {
            continue;
          }
          final values = value is List<Object?> && value is! TypedData
              ? value
              : <Object?>[value];
          for (final item in values) {
            if (item == null) continue;
            if (emittedHeaders >= resourceLimits.maxNetworkHeaders) {
              truncated = true;
              break;
            }
            emittedHeaders++;
            final text = _boundedText(item, resourceLimits);
            if (!buffer.write(' -H ${_shellEscape('$key: $text')}')) {
              truncated = true;
              break;
            }
          }
          if (truncated) break;
        }
      }

      final redactedBody = rawBody == null || effectiveRedactor == null
          ? rawBody
          : NetworkPayloadSanitizer(
              effectiveRedactor,
              resourceLimits: resourceLimits,
            ).body(
              rawBody,
              enableRedaction: true,
            );
      final body = LogExportOutput.boundJsonValue(
        redactedBody,
        resourceLimits: resourceLimits,
        replaceOversizedStrings: redactionActive,
      );
      if (body != null) {
        final bodyString = body is String
            ? body
            : JsonTruncator.pretty(
                body,
                maxStringLength: resourceLimits.maxNetworkBodyBytes,
              );
        if (!buffer.write(' --data-raw ${_shellEscape(bodyString)}')) {
          truncated = true;
        }
      }
      if (truncated) {
        buffer.write(' # ${LogExportOutput.truncatedMarker}');
      }
      return buffer.toString();
    } catch (_) {
      return null;
    }
  }

  static Map<String, Object?>? _coerceHeaders(
    Object? value, {
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final bounded = LogExportOutput.boundJsonValue(
      value,
      resourceLimits: resourceLimits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
    );
    if (bounded is Map<String, Object?>) return bounded;
    if (bounded is Map) return Map<String, Object?>.from(bounded);
    return null;
  }

  static String _boundString(
    String value, {
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final bounded = LogExportOutput.boundJsonValue(
      value,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    return bounded is String ? bounded : LogExportOutput.truncatedMarker;
  }

  static String _boundedText(
    Object? value,
    DiagnosticResourceLimits resourceLimits,
  ) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is bool || value is num) return value.toString();
    final bounded = value is TypedData || value is ByteBuffer
        ? LogExportOutput.boundJsonValue(
            value,
            resourceLimits: resourceLimits,
          )
        : value;
    return JsonTruncator.pretty(
      bounded,
      maxStringLength: resourceLimits.maxCapturedValueBytes,
    );
  }

  static String _shellEscape(String value) {
    final escaped = value.replaceAll("'", r"'\''");
    return "'$escaped'";
  }
}

final class _CurlCommandBuffer {
  _CurlCommandBuffer(this.maxBytes);

  final int maxBytes;
  final StringBuffer _buffer = StringBuffer();
  int _bytes = 0;

  bool write(String value) {
    final remaining = maxBytes - _bytes;
    final bytes = LogExportOutput.utf8Length(value, limit: remaining);
    if (bytes > remaining) return false;
    _buffer.write(value);
    _bytes += bytes;
    return true;
  }

  @override
  String toString() => _buffer.toString();
}
