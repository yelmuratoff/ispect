import 'package:flutter/material.dart';
import 'package:performance/performance.dart';

class PerformanceOverlayBuilder extends StatelessWidget {
  final Widget child;
  final bool isPerformanceTrackingEnabled;
  final ThemeData theme;
  const PerformanceOverlayBuilder({
    required this.child,
    required this.isPerformanceTrackingEnabled,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPerformanceOverlay(
          enabled: isPerformanceTrackingEnabled,
          alignment: Alignment.topCenter,
          backgroundColor: theme.colorScheme.background,
          textColor: theme.colorScheme.onBackground,
          textBackgroundColor: theme.colorScheme.background.withOpacity(0.5),
          child: child,
        ),
      );
}
