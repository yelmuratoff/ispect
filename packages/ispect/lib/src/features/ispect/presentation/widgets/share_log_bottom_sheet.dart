import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectShareLogBottomSheet {
  const ISpectShareLogBottomSheet({
    required this.data,
    required this.truncatedData,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

  Future<void> show(BuildContext context) => showISpectSheet(
        context,
        initialChildSize: 0.25,
        maxChildSize: 0.35,
        topOnlyRadius: true,
        builder: (context, _) => SafeArea(
          child: _InfoDescription(data: data, truncatedData: truncatedData),
        ),
      );
}

class _InfoDescription extends StatelessWidget {
  const _InfoDescription({
    required this.data,
    required this.truncatedData,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

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
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
                      Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
                    copyClipboard(
                      context,
                      value: valueToShare,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
