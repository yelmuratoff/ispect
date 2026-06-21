import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';

/// Rounded-square icon container with a primary-tinted background, used across
/// sheet headers, dialog titles, action tiles, and hint rows.
class ISpectIconBadge extends StatelessWidget {
  const ISpectIconBadge({
    required this.icon,
    this.size = ISpectIconBadgeSize.medium,
    this.color,
    super.key,
  });

  final IconData icon;
  final ISpectIconBadgeSize size;

  /// Override the tint. Defaults to [BuildContext.ispectPrimaryColor].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.ispectPrimaryColor;
    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: tint.withValues(alpha: size.bgAlpha),
        radius: size.radius,
      ),
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Icon(icon, color: tint, size: size.iconSize),
      ),
    );
  }
}

/// Size presets for [ISpectIconBadge].
enum ISpectIconBadgeSize {
  /// Compact badge used inside list-like action/hint rows.
  small(radius: 8, padding: 6, iconSize: 16, bgAlpha: 0.1),

  /// Default badge used in sheet/dialog headers.
  medium(radius: 10, padding: 8, iconSize: 22, bgAlpha: 0.12);

  const ISpectIconBadgeSize({
    required this.radius,
    required this.padding,
    required this.iconSize,
    required this.bgAlpha,
  });

  final double radius;
  final double padding;
  final double iconSize;
  final double bgAlpha;
}
