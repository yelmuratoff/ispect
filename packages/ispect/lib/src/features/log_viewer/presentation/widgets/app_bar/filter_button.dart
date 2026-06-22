import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/desktop_metrics.dart';
import 'package:ispect/src/common/utils/squircle.dart';

class ISpectFilterButton extends StatelessWidget {
  const ISpectFilterButton({
    required this.hasActiveState,
    required this.onPressed,
    this.activeFilterCount = 0,
    super.key,
  });

  final bool hasActiveState;

  /// Number of explicitly-selected filters (e.g. log type chips).
  final int activeFilterCount;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectPrimaryColor;
    final cardColor = context.ispectCardColor;
    final size = context.ispectSquareControlSize;
    final hasCount = activeFilterCount > 0;
    final badgeLabel =
        activeFilterCount > 9 ? '9+' : activeFilterCount.toString();

    return Tooltip(
      message: context.ispectL10n.filters,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color:
              hasActiveState ? primaryColor.withValues(alpha: 0.12) : cardColor,
          shape: ISpectSquircle.border(),
          child: Semantics(
            button: true,
            label: context.ispectL10n.filters,
            onTap: onPressed,
            child: InkWell(
              excludeFromSemantics: true,
              customBorder: ISpectSquircle.border(),
              onTap: onPressed,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: hasActiveState
                        ? primaryColor
                        : context.appTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                  ),
                  if (hasCount)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _FilterCountBadge(
                        label: badgeLabel,
                        color: primaryColor,
                      ),
                    )
                  else if (hasActiveState)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 6, height: 6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterCountBadge extends StatelessWidget {
  const _FilterCountBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Container(
      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(7)),
        border: Border.all(
          color: context.appTheme.scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: onColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
