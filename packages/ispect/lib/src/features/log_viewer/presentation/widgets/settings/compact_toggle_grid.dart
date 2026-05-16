import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/toggle_spec.dart';

class CompactToggleGrid extends StatelessWidget {
  const CompactToggleGrid({required this.tiles, super.key});

  final List<ToggleSpec> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <List<ToggleSpec>>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(tiles.sublist(i, (i + 2).clamp(0, tiles.length)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Gap(6),
            Row(
              children: [
                Expanded(child: CompactToggleRow(spec: row[0])),
                const Gap(6),
                Expanded(
                  child: row.length > 1
                      ? CompactToggleRow(spec: row[1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CompactToggleRow extends StatelessWidget {
  const CompactToggleRow({required this.spec, super.key});

  final ToggleSpec spec;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectPrimaryColor;
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final textColor = context.appTheme.textColor;
    final outlineColor = context.ispectSubtleBorderColor;

    final disabled = !spec.canEdit;
    final enabled = spec.enabled;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Semantics(
        toggled: enabled,
        label: '${spec.title} ${enabled ? "enabled" : "disabled"}',
        onTap: disabled ? null : () => spec.onChanged(!enabled),
        child: Material(
          color: enabled ? primaryColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: InkWell(
            excludeFromSemantics: true,
            onTap: disabled ? null : () => spec.onChanged(!enabled),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: enabled
                      ? primaryColor.withValues(alpha: 0.45)
                      : outlineColor,
                  width: enabled ? 1.2 : 1,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      spec.icon,
                      size: 16,
                      color: enabled
                          ? primaryColor
                          : textColor.withValues(alpha: 0.55),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTheme.textTheme.labelMedium?.copyWith(
                          color: enabled
                              ? primaryColor
                              : textColor.withValues(alpha: 0.7),
                          fontWeight:
                              enabled ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Gap(8),
                    _CompactSwitch(
                      enabled: enabled,
                      primaryColor: primaryColor,
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
    final trackOff =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.18);
    final thumbOff =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.55);

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
