import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';

class ISpectShareAllLogsBottomSheet {
  const ISpectShareAllLogsBottomSheet({
    this.logs,
    this.onShare,
    this.metadataProvider,
  });

  final List<ISpectLogData>? logs;
  final ISpectShareCallback? onShare;
  final ISpectMetadataProvider? metadataProvider;

  Future<void> show(BuildContext context) {
    final options = context.iSpect.options;
    final controller = ExportController(
      availableFormats: ExportFormat.values,
      onShare: onShare ?? options.onShare,
    );

    return ISpectExportSheet.show(
      context,
      controller: controller,
      contentBuilder: (format, {required action, redactKeys}) async {
        final metadata =
            await (metadataProvider ?? options.metadataProvider)?.call();
        return buildLogsExportContent(
          format,
          logs: logs ?? ISpect.logger.history,
          redactKeys: redactKeys,
          metadata: metadata,
        );
      },
    );
  }
}

/// Encodes the supplied log snapshot for the shared export sheet.
Future<String> buildLogsExportContent(
  ExportFormat format, {
  required List<ISpectLogData> logs,
  Set<String>? redactKeys,
  ISpectMetadata? metadata,
}) async {
  if (logs.isEmpty) return '';

  switch (format) {
    case ExportFormat.text:
      return LogExporter.toText(
        logs,
        redactKeys: redactKeys,
        metadata: metadata,
      );
    case ExportFormat.markdown:
      return LogExporter.toMarkdown(
        logs,
        redactKeys: redactKeys,
        metadata: metadata,
      );
    case ExportFormat.csv:
      return LogExporter.toCsv(logs, redactKeys: redactKeys);
    case ExportFormat.json:
      final exportData = <String, dynamic>{
        ISpectMetadata.exportKey: {
          'exportedAt': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'totalLogs': logs.length,
          'platform': 'ispect',
          ...?metadata?.toMap(),
        },
        'logs': logs.map((log) => log.toJson()).toList(growable: false),
      };
      if (redactKeys != null) {
        final redactionService = RedactionService(sensitiveKeys: redactKeys);
        final logsData = exportData['logs'];
        if (logsData is List<Map<String, dynamic>>) {
          exportData['logs'] = logsData.map((log) {
            final redacted = redactionService.redact(log);
            return redacted is Map<String, dynamic> ? redacted : log;
          }).toList(growable: false);
        }
      }
      return const JsonEncoder.withIndent('  ').convert(exportData);
  }
}
