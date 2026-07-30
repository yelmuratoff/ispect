import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';

class ISpectShareLogBottomSheet {
  const ISpectShareLogBottomSheet({
    required this.data,
    required this.truncatedData,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

  Future<void> show(BuildContext context) {
    final options = context.iSpect.options;
    final shareCallback = options.onShare;
    final metadataProvider = options.metadataProvider;
    final controller = ExportController(
      availableFormats: ExportFormat.values,
      onShare: shareCallback,
    );

    return ISpectExportSheet.show(
      context,
      controller: controller,
      contentBuilder: (format, {required action, redactKeys}) async {
        final metadata = await metadataProvider?.call();
        return buildContent(
          data: data,
          truncatedData: truncatedData,
          format: format,
          action: action,
          redactKeys: redactKeys,
          metadata: metadata,
        );
      },
    );
  }

  @visibleForTesting
  static String buildContent({
    required Map<String, dynamic> data,
    required Map<String, dynamic> truncatedData,
    required ExportFormat format,
    required ExportAction action,
    Set<String>? redactKeys,
    bool enableRedaction = true,
    ISpectMetadata? metadata,
    RedactionService? redactionService,
    DiagnosticResourceLimits? resourceLimits,
  }) {
    final limits = (resourceLimits ??
        ISpect.loggerIfInitialized?.options.resourceLimits ??
        DiagnosticResourceLimits.balanced)
      ..validate();
    final source = action == ExportAction.copy ? truncatedData : data;
    final maxDepth = action == ExportAction.copy
        ? _minimum(10, limits.maxTraversalDepth)
        : limits.maxTraversalDepth;
    final maxIterableSize = action == ExportAction.copy
        ? _minimum(100, limits.maxCollectionItems)
        : limits.maxCollectionItems;
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    final preparedEnvelope = LogExportOutput.boundJsonValue(
      _buildEnvelope(
        source,
        metadata,
        redactionActive: redactionActive,
        resourceLimits: limits,
      ),
      resourceLimits: limits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
    );

    var redactedEnvelope = preparedEnvelope;
    if (redactionActive) {
      try {
        redactedEnvelope = ISpectRedaction.resolveService(
          service: redactionService,
          sensitiveKeys: redactKeys,
        ).redactEnvelopeForExport(
          preparedEnvelope,
          rootValueKeys: const {'key'},
        );
      } catch (_) {
        redactedEnvelope = null;
      }
    }

    final boundedEnvelope = LogExportOutput.boundJsonValue(
      redactedEnvelope,
      resourceLimits: limits,
      replaceOversizedStrings: redactionActive,
    );
    final outboundData = boundedEnvelope is Map<String, Object?>
        ? Map<String, dynamic>.from(boundedEnvelope)
        : <String, dynamic>{
            'diagnostic': defaultPlaceholder,
          };

    return _formatSingleLog(
      outboundData,
      format: format,
      maxDepth: maxDepth,
      maxIterableSize: maxIterableSize,
      resourceLimits: limits,
    );
  }

  static Map<String, Object?> _buildEnvelope(
    Map<String, dynamic> source,
    ISpectMetadata? metadata, {
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final boundedSource = LogExportOutput.boundJsonValue(
      source,
      resourceLimits: resourceLimits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
    );
    final envelope = boundedSource is Map<String, Object?>
        ? Map<String, Object?>.from(boundedSource)
        : <String, Object?>{
            'diagnostic': defaultPlaceholder,
          };
    if (metadata == null) return envelope;

    final metadataMap = _boundedMetadata(
      metadata,
      redactionActive: redactionActive,
      resourceLimits: resourceLimits,
    );
    if (metadataMap.isNotEmpty) {
      envelope[ISpectMetadata.exportKey] = metadataMap;
    }
    return envelope;
  }

  static Map<String, Object?> _boundedMetadata(
    ISpectMetadata metadata, {
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final result = <String, Object?>{};
    if (metadata.extra case final extra?) {
      final boundedExtra = LogExportOutput.boundJsonValue(
        extra,
        resourceLimits: resourceLimits,
        preserveTypes: redactionActive,
        replaceOversizedStrings: redactionActive,
      );
      if (boundedExtra is Map<String, Object?>) {
        result.addAll(boundedExtra);
      }
    }

    if (metadata.appName != null) result['appName'] = metadata.appName;
    if (metadata.appVersion != null) {
      result['appVersion'] = metadata.appVersion;
    }
    if (metadata.buildNumber != null) {
      result['buildNumber'] = metadata.buildNumber;
    }
    if (metadata.environment != null) {
      result['environment'] = metadata.environment;
    }
    if (metadata.device != null) result['device'] = metadata.device;
    if (metadata.os != null) result['os'] = metadata.os;
    if (metadata.osVersion != null) {
      result['osVersion'] = metadata.osVersion;
    }
    if (metadata.locale != null) result['locale'] = metadata.locale;
    return result;
  }

  static String _formatSingleLog(
    Map<String, dynamic> logData, {
    required ExportFormat format,
    required DiagnosticResourceLimits resourceLimits,
    int maxDepth = 500,
    int maxIterableSize = 10000,
  }) {
    final prettyJson = JsonTruncator.pretty(
      _jsonCompatible(logData),
      maxDepth: maxDepth,
      maxIterableSize: maxIterableSize,
      maxStringLength: resourceLimits.maxCapturedValueBytes,
    );

    switch (format) {
      case ExportFormat.json:
        return _fitsOutput(prettyJson, resourceLimits)
            ? prettyJson
            : jsonEncode({
                'diagnostic': LogExportOutput.truncatedMarker,
              });
      case ExportFormat.text:
        return LogExportOutput.truncateUtf8(
          prettyJson,
          maxBytes: _maxSingleLogOutputBytes(resourceLimits),
        );
      case ExportFormat.markdown:
        return _formatMarkdown(prettyJson, resourceLimits);
      case ExportFormat.csv:
        return _formatCsv(logData, resourceLimits);
    }
  }

  static String _formatMarkdown(
    String prettyJson,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final maxOutputBytes = _maxSingleLogOutputBytes(resourceLimits);
    final fence = _safeMarkdownFence(prettyJson, maxOutputBytes);
    if (fence == null) return _markdownFallback;

    final prefix = '# Log Entry\n\n${fence}json\n';
    final suffix = '\n$fence\n';
    final framingBytes =
        LogExportOutput.utf8Length(prefix) + LogExportOutput.utf8Length(suffix);
    if (framingBytes > maxOutputBytes) return _markdownFallback;

    final body = LogExportOutput.truncateUtf8(
      prettyJson,
      maxBytes: maxOutputBytes - framingBytes,
    );
    return '$prefix$body$suffix';
  }

  static String? _safeMarkdownFence(String value, int maxOutputBytes) {
    var longestRun = 0;
    var currentRun = 0;
    for (final codeUnit in value.codeUnits) {
      if (codeUnit == 0x60) {
        currentRun++;
        if (currentRun > longestRun) longestRun = currentRun;
      } else {
        currentRun = 0;
      }
    }

    final fenceLength = longestRun < 3 ? 3 : longestRun + 1;
    if (fenceLength * 2 + 32 > maxOutputBytes) return null;
    return ''.padLeft(fenceLength, '`');
  }

  static String _formatCsv(
    Map<String, dynamic> logData,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final maxOutputBytes = _maxSingleLogOutputBytes(resourceLimits);
    const header = 'Key,Value\n';
    final output = StringBuffer(header);
    var outputBytes = LogExportOutput.utf8Length(header);
    for (final entry in logData.entries) {
      final row = '${LogExporter.escapeCsvValue(entry.key)},'
          '${LogExporter.escapeCsvValue(_csvValue(entry.value, resourceLimits))}\n';
      final remaining = maxOutputBytes - outputBytes;
      final rowBytes = LogExportOutput.utf8Length(row, limit: remaining);
      if (rowBytes > remaining) {
        const markerKey = 'diagnostic';
        const markerRow = '$markerKey,${LogExportOutput.truncatedMarker}\n';
        final markerBytes = LogExportOutput.utf8Length(markerRow);
        if (markerBytes <= remaining) output.write(markerRow);
        break;
      }
      output.write(row);
      outputBytes += rowBytes;
    }
    return output.toString();
  }

  static String _csvValue(
    Object? value,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final compatible = _jsonCompatible(value);
    final String text;
    if (compatible == null) {
      text = '';
    } else if (compatible is String) {
      text = compatible;
    } else if (compatible is bool || compatible is num) {
      text = compatible.toString();
    } else {
      try {
        text = jsonEncode(compatible);
      } catch (_) {
        return JsonValueNormalizer.unprintableValue;
      }
    }
    return LogExportOutput.truncateUtf8(
      text,
      maxBytes: resourceLimits.maxCapturedValueBytes,
    );
  }

  static Object? _jsonCompatible(Object? value) {
    if (value is double && !value.isFinite) return value.toString();
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, child) => MapEntry(key, _jsonCompatible(child)),
      );
    }
    if (value is Map<String, Object?>) {
      return value.map(
        (key, child) => MapEntry(key, _jsonCompatible(child)),
      );
    }
    if (value is List<Object?>) {
      return value.map(_jsonCompatible).toList(growable: false);
    }
    return value;
  }

  static bool _fitsOutput(
    String value,
    DiagnosticResourceLimits resourceLimits,
  ) =>
      LogExportOutput.utf8Length(
        value,
        limit: _maxSingleLogOutputBytes(resourceLimits),
      ) <=
      _maxSingleLogOutputBytes(resourceLimits);

  static int _maxSingleLogOutputBytes(
    DiagnosticResourceLimits resourceLimits,
  ) =>
      _minimum(
        resourceLimits.maxLogRecordBytes,
        resourceLimits.maxExportDocumentBytes,
      );

  static int _minimum(int first, int second) => first < second ? first : second;

  static const String _markdownFallback = '# Log Entry\n\n```json\n'
      '{"diagnostic":"${LogExportOutput.truncatedMarker}"}\n'
      '```\n';
}
