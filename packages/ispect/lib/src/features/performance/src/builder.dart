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
  });

  final Widget child;
  final bool isPerformanceTrackingEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appTheme.colorScheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ISpectPerformanceOverlay(
        enabled: isPerformanceTrackingEnabled,
        alignment: Alignment.topCenter,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.4),
        textColor: colorScheme.onSurface,
        overTargetColor: colorScheme.error,
        child: child,
      ),
    );
  }
}
