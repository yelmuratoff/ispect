import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/core/res/json_color.dart';

class SlowBadge extends StatelessWidget {
  const SlowBadge({required this.durationMs, super.key});

  final int durationMs;

  @override
  Widget build(BuildContext context) {
    final text = durationMs < 1000
        ? 'Slow: ${durationMs}ms'
        : 'Slow: ${(durationMs / 1000).toStringAsFixed(1)}s';
    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: JsonColors.statusWarning.withValues(alpha: 0.12),
        radius: ISpectConstants.smallBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: JsonColors.statusWarningDark,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
