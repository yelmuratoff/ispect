import 'package:flutter/material.dart';

class SlowBadge extends StatelessWidget {
  const SlowBadge({required this.durationMs, super.key});

  final int durationMs;

  @override
  Widget build(BuildContext context) {
    final text = durationMs < 1000
        ? 'Slow: ${durationMs}ms'
        : 'Slow: ${(durationMs / 1000).toStringAsFixed(1)}s';
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0x1FFF9800),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE65100),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
