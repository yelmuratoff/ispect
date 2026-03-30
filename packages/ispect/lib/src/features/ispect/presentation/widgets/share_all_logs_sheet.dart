import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';

class ISpectShareAllLogsBottomSheet {
  const ISpectShareAllLogsBottomSheet({
    required this.controller,
    this.filteredCount,
    this.isFiltered = false,
  });

  final ISpectViewController controller;
  final int? filteredCount;
  final bool isFiltered;

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;
    final redactNotifier = ValueNotifier<bool>(true);

    return ISpectShareSheet.show(
      context,
      actionsBuilder: (sheetContext) => [
        ValueListenableBuilder<bool>(
          valueListenable: redactNotifier,
          builder: (context, redact, _) => _RedactionToggle(
            value: !redact,
            onChanged: (include) => redactNotifier.value = !include,
          ),
        ),
        if (shareCallback != null) ...[
          _ExportButton(
            icon: Icons.data_object_rounded,
            label: '${context.ispectL10n.shareLogsFile} (JSON)',
            controller: controller,
            fileType: 'json',
            redactNotifier: redactNotifier,
          ),
          _ExportButton(
            icon: Icons.text_snippet_outlined,
            label: '${context.ispectL10n.shareLogsFile} (Text)',
            controller: controller,
            fileType: 'txt',
            redactNotifier: redactNotifier,
          ),
          _ExportButton(
            icon: Icons.article_outlined,
            label: '${context.ispectL10n.shareLogsFile} (Markdown)',
            controller: controller,
            fileType: 'md',
            redactNotifier: redactNotifier,
            popAfter: true,
          ),
          _ExportButton(
            icon: Icons.table_chart_outlined,
            label: '${context.ispectL10n.shareLogsFile} (CSV)',
            controller: controller,
            fileType: 'csv',
            redactNotifier: redactNotifier,
          ),
          if (isFiltered && filteredCount != null) ...[
            const Divider(height: 1),
            _ExportButton(
              icon: Icons.filter_list_rounded,
              label: '$filteredCount filtered (JSON)',
              controller: controller,
              fileType: 'json',
              redactNotifier: redactNotifier,
            ),
          ],
        ],
        const Divider(height: 1),
        ValueListenableBuilder<bool>(
          valueListenable: redactNotifier,
          builder: (context, redact, _) => ISpectSheetActionButton(
            icon: Icons.copy_rounded,
            label: context.ispectL10n.copyAllLogs,
            onPressed: () {
              final logs = ISpect.logger.history;
              final logsText = LogExporter.toText(
                logs,
                redactKeys: redact ? defaultSensitiveKeys : null,
              );
              Navigator.of(sheetContext).pop();
              copyClipboard(
                context,
                value: logsText,
                title: context.ispectL10n.allLogsCopied,
                showValue: false,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RedactionToggle extends StatelessWidget {
  const _RedactionToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 16,
              color: onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.ispectL10n.includeSensitiveData,
                style: context.appTheme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatefulWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.controller,
    required this.fileType,
    required this.redactNotifier,
    this.popAfter = false,
  });

  final IconData icon;
  final String label;
  final ISpectViewController controller;
  final String fileType;
  final ValueNotifier<bool> redactNotifier;
  final bool popAfter;

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _exporting = false;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await widget.controller.shareLogsAsFile(
        ISpect.logger.history,
        fileType: widget.fileType,
        redactKeys: widget.redactNotifier.value ? defaultSensitiveKeys : null,
      );
      if (mounted && widget.popAfter) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exporting) {
      return _ExportingIndicator(label: widget.label);
    }
    return ISpectSheetActionButton(
      icon: widget.icon,
      label: widget.label,
      onPressed: _export,
    );
  }
}

class _ExportingIndicator extends StatelessWidget {
  const _ExportingIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: context.appTheme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: context.appTheme.textTheme.labelMedium?.copyWith(
                  color: context.appTheme.textColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
