// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/src/controllers/feedback_controller.dart';

class FeedbackData extends InheritedWidget {
  const FeedbackData({
    required super.child,
    required this.controller,
    super.key,
  });

  final FeedbackController controller;

  @override
  bool updateShouldNotify(FeedbackData oldWidget) =>
      oldWidget.controller != controller;
}
