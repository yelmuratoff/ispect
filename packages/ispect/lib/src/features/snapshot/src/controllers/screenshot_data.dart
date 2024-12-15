// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/src/controllers/screenshot.dart';

class ScreenShotData extends InheritedWidget {
  const ScreenShotData({
    required super.child,
    required this.controller,
    super.key,
  });

  final ScreenshotController controller;

  @override
  bool updateShouldNotify(ScreenShotData oldWidget) =>
      oldWidget.controller != controller;
}
