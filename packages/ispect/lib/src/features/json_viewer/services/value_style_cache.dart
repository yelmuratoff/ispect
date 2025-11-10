import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart';

/// Small helper to cache computed value style and tap interaction decision
/// for a given value + style + builder combination.
class ValueStyleCache {
  PropertyOverrides? _cachedValueStyle;
  bool? _cachedHasInteraction;

  void invalidate() {
    _cachedValueStyle = null;
    _cachedHasInteraction = null;
  }

  PropertyOverrides resolveValueStyle({
    required Object? value,
    required TextStyle defaultStyle,
    required StyleBuilder? styleBuilder,
  }) =>
      _cachedValueStyle ??= styleBuilder?.call(value, defaultStyle) ??
          PropertyOverrides(style: defaultStyle);

  bool resolveHasInteraction({
    required bool isRoot,
    required PropertyOverrides valueStyle,
  }) =>
      _cachedHasInteraction ??= isRoot || valueStyle.onTap != null;
}
