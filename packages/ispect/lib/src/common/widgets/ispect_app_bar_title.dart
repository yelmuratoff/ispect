import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/desktop_metrics.dart';
import 'package:ispect/src/common/utils/screen_size.dart';

/// Wraps an AppBar title so every `Text` inside scales down on desktop.
///
/// Callers keep writing their natural font sizes; scaling is applied via
/// `MediaQuery.textScaler` so the call site stays free of conditionals.
class ISpectAppBarTitle extends StatelessWidget {
  const ISpectAppBarTitle({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.screenSize.isDesktop) return child;
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: _MultipliedTextScaler(
          base: mediaQuery.textScaler,
          factor: ISpectDesktopMetrics.titleScale,
        ),
      ),
      child: child,
    );
  }
}

/// Composes the inherited [TextScaler] with an additional multiplier so the
/// user's accessibility scaling is preserved on top of our desktop tweak.
class _MultipliedTextScaler extends TextScaler {
  const _MultipliedTextScaler({required this.base, required this.factor});

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;
}
