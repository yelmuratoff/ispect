import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';

class ISpectShareAllLogsBottomSheet {
  const ISpectShareAllLogsBottomSheet();

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;
    final controller = ExportController(
      availableFormats: ExportFormat.values,
      onShare: shareCallback,
    );

    return ISpectExportSheet.show(
      context,
      controller: controller,
      contentBuilder: (format, {required action, redactKeys}) =>
          _buildContent(format, redactKeys: redactKeys),
    );
  }

  static Future<String> _buildContent(
    ExportFormat format, {
    Set<String>? redactKeys,
  }) async {
    final logs = ISpect.logger.history;
    if (logs.isEmpty) return '';

    switch (format) {
      case ExportFormat.text:
        return LogExporter.toText(logs, redactKeys: redactKeys);
      case ExportFormat.markdown:
        return LogExporter.toMarkdown(logs, redactKeys: redactKeys);
      case ExportFormat.csv:
        return LogExporter.toCsv(logs, redactKeys: redactKeys);
      case ExportFormat.json:
        final exportData = <String, dynamic>{
          'metadata': {
            'exportedAt': DateTime.now().toIso8601String(),
            'version': '1.0.0',
            'totalLogs': logs.length,
            'platform': 'ispect',
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
}
