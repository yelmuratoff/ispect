import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/observers/route_extension.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectNavigationFlowActionsSheet {
  const ISpectNavigationFlowActionsSheet({
    required this.log,
    required this.transition,
    required this.items,
  });

  final RouteLog? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

  Future<void> show(BuildContext context) => showISpectSheet(
        context,
        initialChildSize: 0.25,
        maxChildSize: 0.35,
        topOnlyRadius: true,
        builder: (context, _) => SafeArea(
          child: _ActionsContent(
            log: log,
            transition: transition,
            items: items,
          ),
        ),
      );
}

class _ActionsContent extends StatelessWidget {
  const _ActionsContent({
    required this.log,
    required this.transition,
    required this.items,
  });

  final RouteLog? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ISpectDragHandle(),
          const Gap(8),
          ISpectBottomSheetHeader(
            title: context.ispectL10n.share,
            icon: Icons.route_rounded,
          ),
          const Gap(16),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (context.iSpect.options.onShare != null)
                    ISpectSheetActionButton(
                      icon: Icons.share_rounded,
                      label: context.ispectL10n.shareLogFull,
                      onPressed: () {
                        Navigator.of(context).pop();
                        final String text;
                        if (transition == null) {
                          text = items.transitionsText();
                        } else {
                          text = items.transitionsToId(
                            transition!.id,
                            isTruncated: false,
                          );
                        }
                        LogsFileFactory.downloadFile(
                          text,
                          fileName: 'ispect_navigation_flow',
                          onShare: context.iSpect.options.onShare,
                        );
                      },
                    ),
                  ISpectSheetActionButton(
                    icon: Icons.copy_rounded,
                    label: context.ispectL10n.copyToClipboardTruncated,
                    onPressed: () {
                      Navigator.of(context).pop();
                      final String text;
                      if (transition == null) {
                        text = items.transitionsText();
                      } else {
                        text = items.transitionsToId(transition!.id);
                      }
                      copyClipboard(
                        context,
                        value: text,
                        showValue: false,
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
