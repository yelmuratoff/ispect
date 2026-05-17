import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

/// Rounded card surface that reflects a [SearchMatchState]: subtle highlight
/// for any matching row, stronger highlight plus glow for the focused row.
///
/// Centralises the bg/border/shadow rules that both log cards and network
/// transaction cards use so search styling stays in sync across the list.
class ISpectSearchHighlightSurface extends StatelessWidget {
  const ISpectSearchHighlightSurface({
    required this.searchMatchState,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.clipContent = true,
    super.key,
  });

  final SearchMatchState searchMatchState;
  final Widget child;
  final BorderRadius borderRadius;

  /// Whether to wrap [child] in a [ClipRRect] sized to [borderRadius]. Set to
  /// `false` when the caller already clips the inner content.
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectPrimaryColor;
    final cardColor = context.ispectRowCardColor;

    final Color effectiveBg;
    final Color effectiveBorder;
    final double borderWidth;
    final List<BoxShadow>? boxShadow;

    switch (searchMatchState) {
      case SearchMatchState.focused:
        effectiveBg = primaryColor.withValues(alpha: 0.12);
        effectiveBorder = primaryColor;
        borderWidth = 2;
        boxShadow = [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ];
      case SearchMatchState.match:
        effectiveBg = primaryColor.withValues(alpha: 0.06);
        effectiveBorder = primaryColor.withValues(alpha: 0.5);
        borderWidth = 1.5;
        boxShadow = null;
      case SearchMatchState.none:
        effectiveBg = cardColor;
        effectiveBorder = context.ispectFaintBorderColor;
        borderWidth = 1;
        boxShadow = null;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: boxShadow,
      ),
      child: clipContent
          ? ClipRRect(borderRadius: borderRadius, child: child)
          : child,
    );
  }
}
