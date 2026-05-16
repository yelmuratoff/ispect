import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/common/widgets/ispect_icon_badge.dart';

/// Shows a tips sheet with helpful hints about the logs screen.
class ISpectOnboardingDialog {
  /// Shows the tips sheet as an adaptive bottom-sheet/dialog.
  static Future<void> show(BuildContext context) => showISpectSheet<void>(
        context,
        topOnlyRadius: true,
        routeSettings: const RouteSettings(name: 'ISpect Tips Sheet'),
        builder: (sheetContext, _) =>
            _OnboardingSheet(isDesktop: sheetContext.screenSize.isDesktop),
      );
}

class _OnboardingSheet extends StatelessWidget {
  const _OnboardingSheet({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = ISpectLocalization.of(context);
    final hints = <_HintData>[
      _HintData(Icons.search_rounded, l10n.tipSearchLogs),
      _HintData(Icons.touch_app_rounded, l10n.tipLongPress),
      _HintData(Icons.filter_alt_rounded, l10n.tipFilter),
      _HintData(Icons.open_in_full_rounded, l10n.tipExpand),
      _HintData(Icons.alt_route_rounded, l10n.tipNavigationFlow),
      _HintData(Icons.ios_share_rounded, l10n.tipShareSession),
      _HintData(Icons.import_export_rounded, l10n.tipReverseLogs),
      if (isDesktop) _HintData(Icons.keyboard_rounded, l10n.tipKeyboard),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ISpectDragHandle(),
          const Gap(8),
          ISpectBottomSheetHeader(
            title: l10n.tips,
            icon: Icons.tips_and_updates_outlined,
          ),
          const Gap(12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hints.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (_, index) => _HintRow(
                icon: hints[index].icon,
                text: hints[index].text,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.gotIt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintData {
  const _HintData(this.icon, this.text);
  final IconData icon;
  final String text;
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ISpectBorderedSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ISpectIconBadge(icon: icon, size: ISpectIconBadgeSize.small),
            const Gap(10),
            Expanded(
              child: Text(
                text,
                style: context.appTheme.textTheme.bodyMedium?.copyWith(
                  color: context.appTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}
