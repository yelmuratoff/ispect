import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/observers/route_extension.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';

class ISpectNavigationFlowActionsSheet {
  const ISpectNavigationFlowActionsSheet({
    required this.log,
    required this.transition,
    required this.items,
  });

  final RouteLog? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;

    return ISpectShareSheet.show(
      context,
      icon: Icons.route_rounded,
      actionsBuilder: (sheetContext) => [
        if (shareCallback != null)
          ISpectSheetActionButton(
            icon: Icons.share_rounded,
            label: context.ispectL10n.shareLogFull,
            onPressed: () {
              Navigator.of(sheetContext).pop();
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
                onShare: shareCallback,
              );
            },
          ),
        ISpectSheetActionButton(
          icon: Icons.copy_rounded,
          label: context.ispectL10n.copyToClipboardTruncated,
          onPressed: () {
            Navigator.of(sheetContext).pop();
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
    );
  }
}
