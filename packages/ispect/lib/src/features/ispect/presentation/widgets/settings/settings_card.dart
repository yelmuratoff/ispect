// ignore_for_file: avoid_positional_boolean_parameters, inference_failure_on_function_return_type, implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// A compact toggle card that displays an icon, label and a mini switch pill.
///
/// The whole card is tappable. The pill at the bottom animates left-to-right
/// so the on/off state reads at a glance without the noise of a full
/// `SwitchListTile`.
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
    final inactiveTextColor =
        context.appTheme.textColor.withValues(alpha: 0.45);

    return Expanded(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: canEdit ? 1 : 0.45,
        child: Semantics(
          toggled: enabled,
          label: '$title ${enabled ? "enabled" : "disabled"}',
          onTap: canEdit ? () => onChanged(!enabled) : null,
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: canEdit ? () => onChanged(!enabled) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              decoration: BoxDecoration(
                color:
                    enabled ? primaryColor.withValues(alpha: 0.1) : cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                  color: enabled
                      ? primaryColor.withValues(alpha: 0.45)
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
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: enabled
                          ? primaryColor.withValues(alpha: 0.15)
                          : context.appTheme.colorScheme.onSurface
                              .withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: activeColor ?? inactiveTextColor,
                    ),
                  ),
                  const Gap(5),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTheme.textTheme.labelSmall?.copyWith(
                      color: activeColor ??
                          context.appTheme.textColor.withValues(alpha: 0.6),
                      fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 10.5,
                      height: 1.15,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const Gap(7),
                  _MiniSwitch(enabled: enabled, primaryColor: primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact, non-interactive switch pill used as the on/off indicator inside
/// `ISpectSettingsCardItem`. The parent card handles taps.
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({
    required this.enabled,
    required this.primaryColor,
  });

  final bool enabled;
  final Color primaryColor;

  static const double _trackWidth = 26;
  static const double _trackHeight = 14;
  static const double _thumbSize = 10;
  static const double _thumbPadding = 2;

  @override
  Widget build(BuildContext context) {
    final trackOff =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.18);
    final thumbOff =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.55);

    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: _trackWidth,
        height: _trackHeight,
        decoration: BoxDecoration(
          color: enabled ? primaryColor : trackOff,
          borderRadius: const BorderRadius.all(Radius.circular(_trackHeight)),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: _thumbPadding,
              left: enabled
                  ? _trackWidth - _thumbSize - _thumbPadding
                  : _thumbPadding,
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: enabled ? Colors.white : thumbOff,
                  shape: BoxShape.circle,
                  boxShadow: enabled
                      ? const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
