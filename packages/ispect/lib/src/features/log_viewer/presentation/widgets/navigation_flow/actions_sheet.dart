import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/observers/route_extension.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';
import 'package:ispectify/ispectify.dart';

class ISpectNavigationFlowActionsSheet {
  const ISpectNavigationFlowActionsSheet({
    required this.log,
    required this.transition,
    required this.items,
  });

  final ISpectLogData? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;
    final controller = ExportController(
      availableFormats: ExportFormat.values,
      onShare: shareCallback,
    );

    return ISpectExportSheet.show(
      context,
      controller: controller,
      icon: Icons.route_rounded,
      contentBuilder: (format, {required action, redactKeys}) => Future.value(
        buildContent(
          transition: transition,
          items: items,
          format: format,
          action: action,
          redactKeys: redactKeys,
        ),
      ),
    );
  }

  @visibleForTesting
  static String buildContent({
    required RouteTransition? transition,
    required List<RouteTransition> items,
    required ExportFormat format,
    required ExportAction action,
    Set<String>? redactKeys,
  }) {
    final isTruncated = action == ExportAction.copy;
    final String rawText;
    if (transition == null) {
      rawText = items.transitionsText();
    } else {
      rawText = items.transitionsToId(
        transition.id,
        isTruncated: isTruncated,
      );
    }

    final text = redactKeys == null
        ? rawText
        : RedactionService.redactExportString(rawText, redactKeys);

    switch (format) {
      case ExportFormat.json:
      case ExportFormat.text:
      case ExportFormat.csv:
        return text;
      case ExportFormat.markdown:
        return '# Navigation Flow\n\n```\n$text\n```\n';
    }
  }
}
