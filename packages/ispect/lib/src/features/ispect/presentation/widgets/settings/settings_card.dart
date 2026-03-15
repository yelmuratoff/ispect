// ignore_for_file: avoid_positional_boolean_parameters, inference_failure_on_function_return_type, implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// A compact toggle card that displays an icon and label.
/// The entire card is tappable and visually changes state when toggled.
class ISpectSettingsCardItem extends StatelessWidget {
  const ISpectSettingsCardItem({
    required this.title,
    required this.enabled,
    required this.onChanged,
    required this.icon,
    super.key,
    this.canEdit = true,
  });

  final String title;
  final bool enabled;
  final Function(bool enabled) onChanged;
  final bool canEdit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    final activeColor = enabled ? primaryColor : null;
    final inactiveTextColor = context.appTheme.textColor.withValues(alpha: 0.4);

    return Expanded(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: canEdit ? 1 : 0.45,
        child: GestureDetector(
          onTap: canEdit ? () => onChanged(!enabled) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: enabled ? primaryColor.withValues(alpha: 0.1) : cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                color: enabled
                    ? primaryColor.withValues(alpha: 0.4)
                    : context.appTheme.colorScheme.onSurface
                        .withValues(alpha: 0.08),
                width: enabled ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: enabled
                        ? primaryColor.withValues(alpha: 0.15)
                        : context.appTheme.colorScheme.onSurface
                            .withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: activeColor ?? inactiveTextColor,
                  ),
                ),
                const Gap(4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTheme.textTheme.labelSmall?.copyWith(
                    color: activeColor ??
                        context.appTheme.textColor.withValues(alpha: 0.6),
                    fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
