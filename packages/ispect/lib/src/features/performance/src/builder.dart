import 'package:flutter/material.dart';
import 'package:ispect/src/features/performance/performance.dart';

/// A widget that wraps a [child] with a [CustomPerformanceOverlay]
/// when performance tracking is enabled.
///
/// This builder provides a simple way to conditionally enable an overlay that
/// displays frame performance metrics (e.g., FPS, frame timing bars).
///
/// It also applies visual styling for the overlay based on the provided [theme].
///
/// The overlay uses a fixed [TextDirection.ltr] to avoid being affected by the
/// ambient directionality, ensuring consistent placement and rendering.
///
/// Typically used near the top of the widget tree to wrap the main app content.
///
/// Example usage:
/// ```dart
/// PerformanceOverlayBuilder(
///   isPerformanceTrackingEnabled: true,
///   theme: Theme.of(context),
///   child: MyAppView(),
/// )
/// ```
///
/// See also:
/// - [CustomPerformanceOverlay], which this builder configures and displays.
class PerformanceOverlayBuilder extends StatelessWidget {
  /// Creates a [PerformanceOverlayBuilder].
  ///
  /// - [child] is the content to wrap with the performance overlay.
  /// - [isPerformanceTrackingEnabled] determines whether the overlay is shown.
  /// - [theme] is used to derive overlay colors from the current theme context.
  const PerformanceOverlayBuilder({
    required this.child,
    required this.isPerformanceTrackingEnabled,
    required this.theme,
    super.key,
  });

  /// The widget to display beneath the performance overlay.
  final Widget child;

  /// Whether performance tracking and overlay display is enabled.
  final bool isPerformanceTrackingEnabled;

  /// The theme used to style overlay elements.
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPerformanceOverlay(
          enabled: isPerformanceTrackingEnabled,
          alignment: Alignment.topCenter,
          backgroundColor: theme.colorScheme.surface,
          textColor: theme.colorScheme.onSurface,
          textBackgroundColor:
              theme.colorScheme.surface.withAlpha(0x80), // 50% opacity
          child: child,
        ),
      );
}
