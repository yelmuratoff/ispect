import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

class ISpectFilterButton extends StatelessWidget {
  const ISpectFilterButton({
    required this.hasActiveState,
    required this.onPressed,
    super.key,
  });

  final bool hasActiveState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context);

    return Tooltip(
      message: context.ispectL10n.filters,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color:
              hasActiveState ? primaryColor.withValues(alpha: 0.12) : cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: onPressed,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: hasActiveState
                      ? primaryColor
                      : context.appTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                ),
                if (hasActiveState)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 8, height: 8),
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
