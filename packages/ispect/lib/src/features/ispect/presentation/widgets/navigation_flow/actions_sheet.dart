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
      contentBuilder: (format, {required action, redactKeys}) {
        final isTruncated = action == ExportAction.copy;
        final String text;
        if (transition == null) {
          text = items.transitionsText();
        } else {
          text = items.transitionsToId(
            transition!.id,
            isTruncated: isTruncated,
          );
        }

        switch (format) {
          case ExportFormat.json:
            return Future.value(text);
          case ExportFormat.text:
            return Future.value(text);
          case ExportFormat.markdown:
            return Future.value(
              '# Navigation Flow\n\n```\n$text\n```\n',
            );
          case ExportFormat.csv:
            return Future.value(text);
        }
      },
    );
  }
}
