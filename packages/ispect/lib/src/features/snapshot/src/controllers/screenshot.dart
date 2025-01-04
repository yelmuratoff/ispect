// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScreenshotController {
  final GlobalKey _containerKey = GlobalKey();

  Future<Uint8List> capture({
    double pixelRatio = 1,
    Duration delay = const Duration(milliseconds: 20),
  }) =>
      Future.delayed(delay, () async {
        final renderObject = _containerKey.currentContext?.findRenderObject();

        if (renderObject is! RenderRepaintBoundary) {
          FlutterError.reportError(_noRenderObject());
          throw Exception('Could not take screenshot');
        } else {
          final image = await renderObject.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          return byteData!.buffer.asUint8List();
        }
      });

  FlutterErrorDetails _noRenderObject() => FlutterErrorDetails(
        exception: Exception(
          '_containerKey.currentContext is null. '
          "Thus we can't create a screenshot",
        ),
        library: 'feedback',
        context: ErrorDescription(
          'Tried to find a context to use it to create a screenshot',
        ),
      );
}

class Screenshot extends StatelessWidget {
  const Screenshot({
    required this.child,
    required this.controller,
    super.key,
  });

  final Widget child;
  final ScreenshotController controller;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: controller._containerKey,
        child: child,
      );
}
