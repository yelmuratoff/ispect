import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'zoom_painter.dart';

class ZoomOverlayWidget extends StatelessWidget {
  const ZoomOverlayWidget({
    super.key,
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
  });

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: overlaySize,
      height: overlaySize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.inverseSurface,
          width: 2.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12.0,
            color: Colors.black45,
            offset: Offset(0.0, 8.0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              isComplex: true,
              willChange: true,
              painter: ZoomPainter(
                image: image,
                imageOffset: imageOffset,
                overlaySize: overlaySize,
                zoomScale: zoomScale,
                pixelRatio: pixelRatio,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ZoomLevelIndicator(zoomScale: zoomScale),
            ),
          ),
        ],
      ),
    );
  }
}
