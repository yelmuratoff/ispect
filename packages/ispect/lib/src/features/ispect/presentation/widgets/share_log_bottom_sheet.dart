import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';

class ISpectShareLogBottomSheet {
  const ISpectShareLogBottomSheet({
    required this.data,
    required this.truncatedData,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;

    return ISpectShareSheet.show(
      context,
      actionsBuilder: (sheetContext) => [
        if (shareCallback != null)
          ISpectSheetActionButton(
            icon: Icons.share_rounded,
            label: context.ispectL10n.shareLogFull,
            onPressed: () {
              final valueToShare = JsonTruncatorService.pretty(
                data,
                maxDepth: 500,
                maxIterableSize: 10000,
              );
              Navigator.of(sheetContext).pop();
              LogsFileFactory.downloadFile(
                valueToShare,
                fileName: 'ispect_log',
                onShare: shareCallback,
              );
            },
          ),
        ISpectSheetActionButton(
          icon: Icons.copy_rounded,
          label: context.ispectL10n.copyToClipboardTruncated,
          onPressed: () {
            final valueToShare = JsonTruncatorService.pretty(
              truncatedData,
            );
            Navigator.of(sheetContext).pop();
            copyClipboard(
              context,
              value: valueToShare,
            );
          },
        ),
      ],
    );
  }
}
