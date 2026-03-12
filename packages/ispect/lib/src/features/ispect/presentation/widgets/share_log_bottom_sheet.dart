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
        initialChildSize: 0.3,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _InfoDescription(data: data, truncatedData: truncatedData),
          ),
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
      children: [
        ISpectBottomSheetHeader(title: context.ispectL10n.share),
        const Gap(16),
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shareCallback != null)
                SizedBox(
                  height: 40,
                  child: FilledButton(
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.share_rounded,
                        ),
                        const Gap(8),
                        Flexible(
                          child: Text(
                            context.ispectL10n.shareLogFull,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height: 40,
                child: FilledButton(
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                      ),
                      const Gap(8),
                      Flexible(
                        child: Text(
                          context.ispectL10n.copyToClipboardTruncated,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
