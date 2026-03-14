import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// A unified share bottom sheet that displays a header and a list of action
/// buttons in a consistent layout.
///
/// Use this widget to show share/copy/export actions. Pass [actions] to
/// customise the available operations.
class ISpectShareSheet extends StatelessWidget {
  const ISpectShareSheet({
    required this.actions,
    super.key,
    this.icon = Icons.ios_share_rounded,
  });

  final IconData icon;
  final List<Widget> actions;

  /// Shows the share sheet using [showISpectSheet].
  static Future<void> show(
    BuildContext context, {
    required List<Widget> actions,
    IconData icon = Icons.ios_share_rounded,
  }) =>
      showISpectSheet(
        context,
        initialChildSize: 0.25,
        maxChildSize: 0.35,
        topOnlyRadius: true,
        builder: (context, _) => SafeArea(
          child: ISpectShareSheet(
            icon: icon,
            actions: actions,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ISpectDragHandle(),
          const Gap(8),
          ISpectBottomSheetHeader(
            title: context.ispectL10n.share,
            icon: icon,
          ),
          const Gap(16),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ),
        ],
      );
}
