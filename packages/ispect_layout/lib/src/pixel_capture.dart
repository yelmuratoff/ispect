import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utilities for turning a [RenderRepaintBoundary] into a rasterised [ui.Image]
/// and translating global pointer coordinates into the image's pixel space.
///
/// Stateless and stateless-by-design — the owning controller keeps hold of
/// the captured image, epoch, and any `ValueNotifier` surface. Keeping this
/// a bag of pure functions makes each step trivially unit-testable.
class PixelCapture {
  PixelCapture._();

  /// Captures the contents of [boundaryKey]'s [RenderRepaintBoundary] into a
  /// [ui.Image] at the current device pixel ratio and returns it along with
  /// its RGBA bytes in straight (non-premultiplied) alpha, so a sampled
  /// translucent pixel reports its true colour rather than a darkened one.
  ///
  /// Returns `null` when the boundary isn't yet mounted. Caller is
  /// responsible for [ui.Image.dispose].
  static Future<({ui.Image image, ByteData? byteData})?> capture(
    GlobalKey boundaryKey,
  ) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;

    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    return (image: image, byteData: byteData);
  }

  /// Translates a global pointer offset into the captured image's pixel
  /// space, i.e. local coordinates multiplied by the device pixel ratio.
  /// Returns [Offset.zero] when the boundary isn't yet mounted.
  static Offset globalToImagePx({
    required GlobalKey boundaryKey,
    required Offset globalOffset,
    required BuildContext context,
  }) {
    final boundaryContext = boundaryKey.currentContext;
    if (boundaryContext == null) return Offset.zero;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final boundary =
        boundaryContext.findRenderObject()! as RenderRepaintBoundary;
    return boundary.globalToLocal(globalOffset) * pixelRatio;
  }
}
