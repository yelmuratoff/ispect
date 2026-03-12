import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
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
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _InfoDescription(controller: controller),
          ),
        ),
      );
}

class _InfoDescription extends StatelessWidget {
  const _InfoDescription({
    required this.controller,
  });

  final ISpectViewController controller;

  @override
  Widget build(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;
    if (shareCallback == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ISpectBottomSheetHeader(title: context.ispectL10n.share),
        const Gap(16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.ispectTheme.card?.resolve(context),
                ),
                onPressed: () {
                  controller.shareLogsAsFile(ISpect.logger.history);
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_rounded,
                    ),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        '${context.ispectL10n.shareLogsFile} (JSON)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.ispectTheme.card?.resolve(context),
                ),
                onPressed: () {
                  controller.shareLogsAsFile(
                    ISpect.logger.history,
                    fileType: 'txt',
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
                        '${context.ispectL10n.shareLogsFile} (txt)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
