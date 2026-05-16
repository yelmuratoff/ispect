import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

/// A rounded, subtly bordered container used as the visual shell for tiles,
/// chips, hint rows, and action cards across ISpect.
///
/// Keeps the 10px radius, neutral 0.08 alpha border, and optional ripple in
/// one place so every tile-like surface reads as one design system.
class ISpectBorderedSurface extends StatelessWidget {
  const ISpectBorderedSurface({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.semanticsLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Surface color. Defaults to [BuildContext.ispectCardColor] for tappable
  /// tiles and stays transparent when the tile is non-interactive (passes
  /// through whatever sits behind).
  final Color? backgroundColor;

  /// Border tint. Defaults to [BuildContext.ispectSubtleBorderColor].
  final Color? borderColor;

  /// Border width. Defaults to 1; bump it (e.g. 1.2) to emphasise a selected
  /// or active state.
  final double borderWidth;

  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Optional semantics label for the tap region.
  final String? semanticsLabel;

  bool get _isInteractive => onTap != null || onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final resolvedBg = backgroundColor ??
        (_isInteractive ? context.ispectCardColor : Colors.transparent);
    final resolvedBorder = borderColor ?? context.ispectSubtleBorderColor;

    final shell = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: resolvedBorder, width: borderWidth),
        borderRadius: borderRadius,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!_isInteractive) {
      return Material(
        color: resolvedBg,
        borderRadius: borderRadius,
        child: shell,
      );
    }

    final inkWell = InkWell(
      excludeFromSemantics: semanticsLabel != null,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      child: shell,
    );

    return Material(
      color: resolvedBg,
      borderRadius: borderRadius,
      child: semanticsLabel == null
          ? inkWell
          : Semantics(
              button: true,
              label: semanticsLabel,
              onTap: onTap,
              child: inkWell,
            ),
    );
  }
}
