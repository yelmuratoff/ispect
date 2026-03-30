import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';

class ISpectShareAllLogsBottomSheet {
  const ISpectShareAllLogsBottomSheet({
    required this.controller,
    this.filteredCount,
    this.isFiltered = false,
  });

  final ISpectViewController controller;
  final int? filteredCount;
  final bool isFiltered;

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;

    return ISpectShareSheet.show(
      context,
      actionsBuilder: (sheetContext) => [
        if (shareCallback != null) ...[
          ISpectSheetActionButton(
            icon: Icons.data_object_rounded,
            label: '${context.ispectL10n.shareLogsFile} (JSON)',
            onPressed: () {
              controller.shareLogsAsFile(ISpect.logger.history);
            },
          ),
          ISpectSheetActionButton(
            icon: Icons.text_snippet_outlined,
            label: '${context.ispectL10n.shareLogsFile} (Text)',
            onPressed: () {
              controller.shareLogsAsFile(
                ISpect.logger.history,
                fileType: 'txt',
              );
            },
          ),
          ISpectSheetActionButton(
            icon: Icons.article_outlined,
            label: '${context.ispectL10n.shareLogsFile} (Markdown)',
            onPressed: () {
              controller.shareLogsAsFile(
                ISpect.logger.history,
                fileType: 'md',
              );
              Navigator.of(sheetContext).pop();
            },
          ),
          ISpectSheetActionButton(
            icon: Icons.table_chart_outlined,
            label: '${context.ispectL10n.shareLogsFile} (CSV)',
            onPressed: () {
              controller.shareLogsAsFile(
                ISpect.logger.history,
                fileType: 'csv',
              );
            },
          ),
          if (isFiltered && filteredCount != null) ...[
            const Divider(height: 1),
            ISpectSheetActionButton(
              icon: Icons.filter_list_rounded,
              label: '$filteredCount filtered (JSON)',
              onPressed: () {
                controller.shareLogsAsFile(ISpect.logger.history);
              },
            ),
          ],
        ],
        const Divider(height: 1),
        ISpectSheetActionButton(
          icon: Icons.copy_rounded,
          label: context.ispectL10n.copyAllLogs,
          onPressed: () {
            final logs = ISpect.logger.history;
            final logsText = LogExporter.toText(
              logs,
              redactKeys: defaultSensitiveKeys,
            );
            Navigator.of(sheetContext).pop();
            copyClipboard(
              context,
              value: logsText,
              title: context.ispectL10n.allLogsCopied,
              showValue: false,
            );
          },
        ),
      ],
    );
  }
}
