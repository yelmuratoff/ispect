import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const Gap(8),
          Text(l10n.tips),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HintRow(
            icon: Icons.search_rounded,
            text: l10n.tipSearchLogs,
          ),
          const Gap(12),
          _HintRow(
            icon: Icons.touch_app_rounded,
            text: l10n.tipLongPress,
          ),
          const Gap(12),
          _HintRow(
            icon: Icons.filter_alt_rounded,
            text: l10n.tipFilter,
          ),
          const Gap(12),
          _HintRow(
            icon: Icons.open_in_full_rounded,
            text: l10n.tipExpand,
          ),
          if (isDesktop) ...[
            const Gap(12),
            _HintRow(
              icon: Icons.keyboard_rounded,
              text: l10n.tipKeyboard,
            ),
          ],
        ],
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
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      );
}
