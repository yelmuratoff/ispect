import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// Shows a one-time onboarding dialog when the user first opens the logs screen.
///
/// Uses a static flag to track whether the dialog has been shown this session.
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
  Widget build(BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Gap(8),
            const Text('Tips'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HintRow(
              icon: Icons.search_rounded,
              text: 'Search logs by text — searches full JSON body too',
            ),
            const Gap(12),
            const _HintRow(
              icon: Icons.touch_app_rounded,
              text: 'Long press a log card for quick actions',
            ),
            const Gap(12),
            const _HintRow(
              icon: Icons.filter_alt_rounded,
              text: 'Filter by log type using chips or settings',
            ),
            const Gap(12),
            const _HintRow(
              icon: Icons.open_in_full_rounded,
              text: 'Tap expand to view full JSON with search',
            ),
            if (isDesktop) ...[
              const Gap(12),
              const _HintRow(
                icon: Icons.keyboard_rounded,
                text: 'Use ↑↓ to navigate, ⏎ to open, / to search',
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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
