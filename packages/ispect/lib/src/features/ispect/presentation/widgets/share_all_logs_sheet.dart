import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectShareAllLogsBottomSheet {
  const ISpectShareAllLogsBottomSheet({
    required this.controller,
  });

  final ISpectViewController controller;

  Future<void> show(BuildContext context) => showISpectSheet(
        context,
        initialChildSize: 0.25,
        maxChildSize: 0.35,
        topOnlyRadius: true,
        builder: (context, _) => SafeArea(
          child: _Content(controller: controller),
        ),
      );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.controller,
  });

  final ISpectViewController controller;

  @override
  Widget build(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ISpectDragHandle(),
        const Gap(8),
        ISpectBottomSheetHeader(
          title: context.ispectL10n.share,
          icon: Icons.ios_share_rounded,
        ),
        const Gap(16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shareCallback != null) ...[
                ISpectSheetActionButton(
                  icon: Icons.share_rounded,
                  label: '${context.ispectL10n.shareLogsFile} (JSON)',
                  onPressed: () {
                    controller.shareLogsAsFile(ISpect.logger.history);
                  },
                ),
                ISpectSheetActionButton(
                  icon: Icons.share_rounded,
                  label: '${context.ispectL10n.shareLogsFile} (txt)',
                  onPressed: () {
                    controller.shareLogsAsFile(
                      ISpect.logger.history,
                      fileType: 'txt',
                    );
                  },
                ),
              ],
              ISpectSheetActionButton(
                icon: Icons.copy_rounded,
                label: context.ispectL10n.copyAllLogs,
                onPressed: () {
                  final logs = ISpect.logger.history;
                  final logsText = logs
                      .map(
                        (log) => log.toJson(truncated: true).toString(),
                      )
                      .join('\n');
                  Navigator.of(context).pop();
                  copyClipboard(
                    context,
                    value: logsText,
                    title: context.ispectL10n.allLogsCopied,
                    showValue: false,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
