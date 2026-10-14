import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';
import 'package:ispect/src/features/performance/performance.dart';

/// Wraps [child] with an [ISpectPerformanceOverlay] gated by
/// [isPerformanceTrackingEnabled]. Keeps the host's ambient [Directionality]
/// and only supplies `TextDirection.ltr` when none is inherited.
class ISpectPerformanceOverlayBuilder extends StatelessWidget {
  const ISpectPerformanceOverlayBuilder({
    required this.child,
    required this.isPerformanceTrackingEnabled,
    super.key,
    this.enableJankLogging = false,
    this.severeJankFactor = 2.0,
  });

  final Widget child;
  final bool isPerformanceTrackingEnabled;
  final bool enableJankLogging;
  final double severeJankFactor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appTheme.colorScheme;
    final useHost = context.ispectTheme.useHostColors;
    final dark = context.ispectIsDark;

    final background =
        (useHost
                ? colorScheme.surfaceContainerHighest
                : ISpectDefaultPalette.card.pick(isDark: dark)!)
            .withValues(alpha: 0.95);
    final textColor = useHost
        ? colorScheme.onSurface
        : ISpectDefaultPalette.foreground.pick(isDark: dark)!;
    final overTarget = useHost
        ? colorScheme.error
        : ISpectDefaultPalette.error.pick(isDark: dark)!;

    final overlay = ISpectPerformanceOverlay(
      enabled: isPerformanceTrackingEnabled,
      alignment: Alignment.topCenter,
      backgroundColor: background,
      textColor: textColor,
      overTargetColor: overTarget,
      enableJankLogging: enableJankLogging,
      severeJankFactor: severeJankFactor,
      child: child,
    );
    if (Directionality.maybeOf(context) != null) return overlay;
    return Directionality(textDirection: TextDirection.ltr, child: overlay);
  }
}
