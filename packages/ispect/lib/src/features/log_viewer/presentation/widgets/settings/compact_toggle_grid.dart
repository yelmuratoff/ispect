import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/toggle_spec.dart';

class SettingsTileGrid extends StatelessWidget {
  const SettingsTileGrid({
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  static const double _gap = ISpectConstants.standardGap;

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final fitsTwo =
            constraints.maxWidth >=
            ISpectConstants.settingsTileMinWidth * 2 + _gap;
        final tileWidth = fitsTwo
            ? (constraints.maxWidth - _gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    ),
  );
}

class CompactToggleGrid extends StatelessWidget {
  const CompactToggleGrid({
    required this.tiles,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  final List<ToggleSpec> tiles;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SettingsTileGrid(
    padding: padding,
    children: [for (final spec in tiles) CompactToggleRow(spec: spec)],
  );
}

class CompactToggleRow extends StatelessWidget {
  const CompactToggleRow({required this.spec, super.key});

  final ToggleSpec spec;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectPrimaryColor;
    final cardColor = context.ispectRowCardColor;
    final textColor = context.appTheme.textColor;

    final disabled = !spec.canEdit;
    final enabled = spec.enabled;
    final onTap = disabled ? null : () => spec.onChanged(!enabled);

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Semantics(
        toggled: enabled,
        label: spec.title,
        onTap: onTap,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: ISpectBorderedSurface(
            onTap: onTap,
            backgroundColor: enabled
                ? primaryColor.withValues(alpha: 0.1)
                : cardColor,
            borderColor: enabled ? primaryColor.withValues(alpha: 0.45) : null,
            borderWidth: enabled ? 1.2 : 1,
            borderRadius: const BorderRadius.all(
              Radius.circular(ISpectConstants.largeBorderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  spec.icon,
                  size: 16,
                  color: enabled
                      ? primaryColor
                      : textColor.withValues(alpha: 0.55),
                ),
                const Gap(10),
                Expanded(
                  child: Text(
                    spec.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTheme.textTheme.labelMedium?.copyWith(
                      color: enabled
                          ? primaryColor
                          : textColor.withValues(alpha: 0.7),
                      fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Gap(8),
                _CompactSwitch(enabled: enabled, primaryColor: primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({required this.enabled, required this.primaryColor});

  final bool enabled;
  final Color primaryColor;

  static const double _trackWidth = 24;
  static const double _trackHeight = 13;
  static const double _thumbSize = 9;
  static const double _thumbPadding = 2;

  @override
  Widget build(BuildContext context) {
    final trackOff = context.appTheme.colorScheme.onSurface.withValues(
      alpha: 0.18,
    );
    final thumbOff = context.appTheme.colorScheme.onSurface.withValues(
      alpha: 0.55,
    );

    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
              duration: const Duration(milliseconds: 180),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
