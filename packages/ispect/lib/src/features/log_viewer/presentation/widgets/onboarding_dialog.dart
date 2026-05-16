import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// Shows a tips dialog with helpful hints about the logs screen.
class ISpectOnboardingDialog {
  /// Shows the tips dialog.
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _OnboardingContent(isDesktop: context.screenSize.isDesktop),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = ISpectLocalization.of(context);
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final bgColor = context.ispectTheme.background?.resolve(context) ??
        context.appTheme.colorScheme.surfaceContainerLowest;

    return AlertDialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.tips_and_updates_outlined,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              l10n.tips,
              style: context.appTheme.textTheme.titleLarge?.copyWith(
                color: context.appTheme.textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HintRow(
              icon: Icons.search_rounded,
              text: l10n.tipSearchLogs,
            ),
            const Gap(8),
            _HintRow(
              icon: Icons.touch_app_rounded,
              text: l10n.tipLongPress,
            ),
            const Gap(8),
            _HintRow(
              icon: Icons.filter_alt_rounded,
              text: l10n.tipFilter,
            ),
            const Gap(8),
            _HintRow(
              icon: Icons.open_in_full_rounded,
              text: l10n.tipExpand,
            ),
            const Gap(8),
            _HintRow(
              icon: Icons.alt_route_rounded,
              text: l10n.tipNavigationFlow,
            ),
            const Gap(8),
            _HintRow(
              icon: Icons.ios_share_rounded,
              text: l10n.tipShareSession,
            ),
            const Gap(8),
            _HintRow(
              icon: Icons.import_export_rounded,
              text: l10n.tipReverseLogs,
            ),
            if (isDesktop) ...[
              const Gap(8),
              _HintRow(
                icon: Icons.keyboard_rounded,
                text: l10n.tipKeyboard,
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.gotIt),
        ),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.08);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(icon, size: 16, color: primaryColor),
              ),
            ),
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
      ),
    );
  }
}
