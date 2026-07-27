import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';

const int _backgroundExportLogThreshold = 50;

final class _LogsExportRequest {
  const _LogsExportRequest({
    required this.format,
    required this.logs,
    required this.redactionService,
    required this.enableRedaction,
    required this.metadata,
  });

  final ExportFormat format;
  final List<ISpectLogData> logs;
  final RedactionService redactionService;
  final bool enableRedaction;
  final ISpectMetadata? metadata;
}

String _buildNonJsonExport(_LogsExportRequest request) {
  switch (request.format) {
    case ExportFormat.text:
      return LogExporter.toText(
        request.logs,
        redactionService: request.redactionService,
        enableRedaction: request.enableRedaction,
        metadata: request.metadata,
      );
    case ExportFormat.markdown:
      return LogExporter.toMarkdown(
        request.logs,
        redactionService: request.redactionService,
        enableRedaction: request.enableRedaction,
        metadata: request.metadata,
      );
    case ExportFormat.csv:
      return LogExporter.toCsv(
        request.logs,
        redactionService: request.redactionService,
        enableRedaction: request.enableRedaction,
      );
    case ExportFormat.json:
      throw ArgumentError.value(request.format, 'format');
  }
}

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
  RedactionService? redactionService,
  ISpectMetadata? metadata,
}) async {
  if (logs.isEmpty) return '';

  final effectiveRedactor = ISpectRedaction.resolveService(
    service: redactionService,
    sensitiveKeys: redactKeys,
  );
  if (format == ExportFormat.json) {
    return const LogsJsonService().exportToJson(
      logs,
      redactionService: effectiveRedactor,
      metadata: metadata,
    );
  }

  final request = _LogsExportRequest(
    format: format,
    logs: logs,
    redactionService: effectiveRedactor,
    enableRedaction: ISpectRedaction.enabled,
    metadata: metadata,
  );
  if (logs.length < _backgroundExportLogThreshold) {
    return _buildNonJsonExport(request);
  }
  if (kIsWeb) {
    await Future<void>.delayed(Duration.zero);
    return _buildNonJsonExport(request);
  }
  return compute(
    _buildNonJsonExport,
    request,
    debugLabel: 'ISpect ${format.label} export',
  );
}
