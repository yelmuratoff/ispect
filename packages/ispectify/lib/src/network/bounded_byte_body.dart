import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Decodes a bounded prefix of a network body for diagnostics.
abstract final class BoundedByteBody {
  /// Returns [bytes] decoded with [encoding] and bounded to
  /// [DiagnosticResourceLimits.maxNetworkBodyBytes].
  ///
  /// An oversized body keeps a decoded prefix followed by the truncation
  /// marker, or only the marker while redaction is active so a partial
  /// credential cannot survive at the cut. Throws [FormatException] when the
  /// prefix cannot be decoded.
  static String decode(
    Uint8List bytes,
    Encoding encoding, {
    required DiagnosticResourceLimits resourceLimits,
    required bool redactionActive,
  }) {
    if (bytes.isEmpty) return '';
    final maxBodyBytes = resourceLimits.maxNetworkBodyBytes;
    final oversized = bytes.lengthInBytes > maxBodyBytes;
    if (oversized && redactionActive) return LogExportOutput.truncatedMarker;

    final markerBytes = LogExportOutput.utf8Length(
      LogExportOutput.truncatedMarker,
    );
    final prefixBytes = oversized
        ? (maxBodyBytes - markerBytes).clamp(0, bytes.lengthInBytes)
        : bytes.lengthInBytes;
    final decoded = _decodePrefix(
      bytes,
      encoding,
      prefixBytes,
      recoverTruncatedCodePoint: oversized,
    );
    final withMarker =
        oversized ? '$decoded${LogExportOutput.truncatedMarker}' : decoded;
    final bounded = LogExportOutput.boundJsonValue(
      withMarker,
      maxBytes: maxBodyBytes,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactionActive,
    );
    return bounded is String ? bounded : JsonValueNormalizer.unprintableValue;
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
        return encoding.decode(Uint8List.sublistView(bytes, 0, end - removed));
      } on FormatException catch (error) {
        lastError = error;
      }
    }
    if (lastError case final FormatException error) throw error;
    throw const FormatException('Unable to decode body');
  }
}
