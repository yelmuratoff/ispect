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
        initialChildSize: 0.25,
        maxChildSize: 0.35,
        topOnlyRadius: true,
        builder: (context, _) => SafeArea(
          child: _InfoDescription(controller: controller),
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
          ),
        ),
      ],
    );
  }
}
