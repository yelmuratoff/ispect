import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Detail view widget for displaying selected log data.
class LogDetailView extends StatelessWidget {
  const LogDetailView({
    required this.activeData,
    required this.onClose,
    super.key,
  });

  final ISpectLogData activeData;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final json = activeData.toJson();
    return RepaintBoundary(
      child: JsonScreen(
        key: ValueKey(activeData.hashCode),
        data: json,
        truncatedData: activeData.toJson(truncated: true),
        onClose: onClose,
      ),
    );
  }
}
