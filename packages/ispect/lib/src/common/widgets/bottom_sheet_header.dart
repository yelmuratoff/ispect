import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_icon_badge.dart';

/// Title block shared by bottom sheets and dialogs: optional icon badge,
/// title, optional subtitle.
class _HeaderTitleSection extends StatelessWidget {
  const _HeaderTitleSection({
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textColor = context.appTheme.textColor;
    return Row(
      children: [
        if (icon != null) ...[
          ISpectIconBadge(icon: icon!),
          const Gap(12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.appTheme.textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: context.appTheme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reusable header widget for bottom sheets with icon, title, subtitle,
/// and close button.
class ISpectBottomSheetHeader extends StatelessWidget {
  const ISpectBottomSheetHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: _HeaderTitleSection(
                title: title,
                subtitle: subtitle,
                icon: icon,
              ),
            ),
            IconButton(
              onPressed: onClose ?? () => Navigator.pop(context),
              tooltip: context.ispectL10n.close,
              style: IconButton.styleFrom(
                backgroundColor: context.appTheme.colorScheme.onSurface
                    .withValues(alpha: 0.06),
                shape: const CircleBorder(),
              ),
              icon: Icon(
                Icons.close_rounded,
                color: context.appTheme.textColor.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ],
        ),
      );
}

/// Dialog title row mirroring [ISpectBottomSheetHeader] without a close
/// button (dialogs surface dismissal through action buttons instead).
class ISpectDialogHeader extends StatelessWidget {
  const ISpectDialogHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => _HeaderTitleSection(
        title: title,
        subtitle: subtitle,
        icon: icon,
      );
}

/// A small drag indicator bar for bottom sheets.
class ISpectDragHandle extends StatelessWidget {
  const ISpectDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    // Drag handle only makes sense for phone bottom sheets, not dialogs.
    // Keep equivalent top spacing for dialogs.
    if (!context.screenSize.isPhone) return const SizedBox(height: 16);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appTheme.colorScheme.onSurface.withValues(
              alpha: 0.2,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          child: const SizedBox(width: 36, height: 4),
        ),
      ),
    );
  }
}

/// An uppercase section label for grouping content in sheets.
class ISpectSectionLabel extends StatelessWidget {
  const ISpectSectionLabel({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          title.toUpperCase(),
          style: context.appTheme.textTheme.labelSmall?.copyWith(
            color: context.appTheme.textColor.withValues(alpha: 0.45),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );
}

/// A styled action button for bottom sheets (icon + label chip).
class ISpectSheetActionButton extends StatelessWidget {
  const ISpectSheetActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final cardColor = context.ispectCardColor;
    final primaryColor = context.ispectPrimaryColor;
    final disabledAlpha = disabled ? 0.4 : 1.0;

    return Opacity(
      opacity: disabledAlpha,
      child: Material(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Semantics(
          button: true,
          label: label,
          onTap: onPressed,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onPressed,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: context.ispectSubtleBorderColor),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: primaryColor),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        label,
                        style: context.appTheme.textTheme.labelMedium?.copyWith(
                          color: context.appTheme.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
