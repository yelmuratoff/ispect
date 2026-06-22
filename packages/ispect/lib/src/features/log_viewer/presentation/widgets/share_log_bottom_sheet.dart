import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';
import 'package:ispectify/ispectify.dart';

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
    ISpectMetadata? metadata,
  }) {
    final source = action == ExportAction.copy ? truncatedData : data;
    final maxDepth = action == ExportAction.copy ? 10 : 500;
    final maxIterableSize = action == ExportAction.copy ? 100 : 10000;

    var effectiveData = source;
    if (redactKeys != null) {
      final redactionService = RedactionService(sensitiveKeys: redactKeys);
      final redacted = redactionService.redact(source);
      if (redacted is Map<String, dynamic>) {
        effectiveData = redacted;
      }
    }

    if (metadata != null && !metadata.isEmpty) {
      effectiveData = {
        ...effectiveData,
        ISpectMetadata.exportKey: metadata.toMap(),
      };
    }

    return _formatSingleLog(
      effectiveData,
      format: format,
      maxDepth: maxDepth,
      maxIterableSize: maxIterableSize,
    );
  }

  static String _formatSingleLog(
    Map<String, dynamic> logData, {
    required ExportFormat format,
    int maxDepth = 500,
    int maxIterableSize = 10000,
  }) {
    final prettyJson = JsonTruncator.pretty(
      logData,
      maxDepth: maxDepth,
      maxIterableSize: maxIterableSize,
    );

    switch (format) {
      case ExportFormat.json:
        return prettyJson;
      case ExportFormat.text:
        return prettyJson;
      case ExportFormat.markdown:
        return '# Log Entry\n\n```json\n$prettyJson\n```\n';
      case ExportFormat.csv:
        final flat = logData.entries
            .map(
              (e) => '"${_escapeCsv(e.key)}","${_escapeCsv('${e.value}')}"',
            )
            .join('\n');
        return 'Key,Value\n$flat';
    }
  }

  static String _escapeCsv(String value) =>
      value.replaceAll('"', '""').replaceAll('\n', ' ');
}
