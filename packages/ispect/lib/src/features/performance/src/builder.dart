import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/performance/performance.dart';

/// Wraps [child] with an [ISpectPerformanceOverlay] gated by
/// [isPerformanceTrackingEnabled]. Pins the overlay to `TextDirection.ltr`
/// so its placement is independent of the ambient directionality.
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ISpectPerformanceOverlay(
        enabled: isPerformanceTrackingEnabled,
        alignment: Alignment.topCenter,
        backgroundColor:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        textColor: colorScheme.onSurface,
        overTargetColor: colorScheme.error,
        enableJankLogging: enableJankLogging,
        severeJankFactor: severeJankFactor,
        child: child,
      ),
    );
  }
}
