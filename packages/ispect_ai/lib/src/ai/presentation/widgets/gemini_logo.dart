import 'package:flutter/material.dart';
import 'package:ispect_ai/src/ai/presentation/widgets/ai_painter.dart';

class AiLoaderWidget extends StatelessWidget {
  const AiLoaderWidget({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(
        child: Center(child: _AiLoader()),
      );
}

class _AiLoader extends StatefulWidget {
  const _AiLoader();

  @override
  State<_AiLoader> createState() => _AiLoaderState();
}

class _AiLoaderState extends State<_AiLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.rotate(
          angle: _controller.value * 2 * 3.1416,
          child: child,
        ),
        child: CustomPaint(
          size: const Size(50, 50),
          painter: AiLoaderPainter(),
        ),
      );
}
