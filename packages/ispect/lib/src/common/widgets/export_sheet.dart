import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// A unified bottom sheet for exporting / sharing / copying log data.
///
/// All export-related UI in the app should go through this sheet so that
/// format selection, redaction, and action buttons are consistent.
///
/// The sheet sizes itself to fit its content automatically via [showISpectSheet].
class ISpectExportSheet extends StatelessWidget {
  const ISpectExportSheet({
    required this.controller,
    required this.contentBuilder,
    this.icon = Icons.ios_share_rounded,
    super.key,
  });

  final ExportController controller;
  final ExportContentBuilder contentBuilder;
  final IconData icon;

  /// Shows the export sheet sized to its content.
  static Future<void> show(
    BuildContext context, {
    required ExportController controller,
    required ExportContentBuilder contentBuilder,
    IconData icon = Icons.ios_share_rounded,
  }) =>
      showISpectSheet(
        context,
        topOnlyRadius: true,
        builder: (sheetContext, _) => ISpectExportSheet(
          controller: controller,
          contentBuilder: contentBuilder,
          icon: icon,
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ISpectDragHandle(),
              const Gap(8),
              ISpectBottomSheetHeader(
                title: context.ispectL10n.share,
                icon: icon,
              ),
              const Gap(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.availableFormats.length > 1)
                      _FormatChips(controller: controller),
                    if (controller.showRedaction)
                      _RedactionToggle(controller: controller),
                    const Gap(8),
                    _ActionButtons(
                      controller: controller,
                      contentBuilder: contentBuilder,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Format chips ──────────────────────────────────────────────────────────

class _FormatChips extends StatelessWidget {
  const _FormatChips({required this.controller});
  final ExportController controller;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final format in controller.availableFormats)
            ChoiceChip(
              label: Text(format.label),
              avatar: Icon(format.icon, size: 16),
              selected: controller.selectedFormat == format,
              selectedColor: primaryColor.withValues(alpha: 0.15),
              showCheckmark: false,
              onSelected: (_) => controller.selectFormat(format),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ── Redaction toggle ──────────────────────────────────────────────────────

class _RedactionToggle extends StatelessWidget {
  const _RedactionToggle({required this.controller});
  final ExportController controller;

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
                child: Switch(
                  value: !controller.redact,
                  onChanged: (_) => controller.toggleRedaction(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.controller,
    required this.contentBuilder,
  });

  final ExportController controller;
  final ExportContentBuilder contentBuilder;

  void _closeSheet(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is ModalBottomSheetRoute) {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExporting = controller.state == ExportState.exporting;
    final l10n = context.ispectL10n;

    // Capture messenger before async gap.
    final messenger = ScaffoldMessenger.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExporting)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ISpectSheetActionButton(
              icon: Icons.download_rounded,
              label: l10n.downloadLogsFile,
              onPressed: isExporting
                  ? null
                  : () async {
                      await controller.download(contentBuilder);
                      final path = controller.resultPath;
                      if (path.isEmpty) return;
                      if (!context.mounted) return;
                      _closeSheet(context);
                      if (kIsWeb) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.downloadLogsFile),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.logsFileSaved(path)),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 6),
                            action: SnackBarAction(
                              label: l10n.copyPath,
                              onPressed: () {
                                copyClipboard(context, value: path);
                              },
                            ),
                          ),
                        );
                      }
                    },
            ),
            if (controller.canShare)
              ISpectSheetActionButton(
                icon: Icons.share_rounded,
                label: l10n.share,
                onPressed: isExporting
                    ? null
                    : () async {
                        await controller.share(contentBuilder);
                        if (!context.mounted) return;
                        _closeSheet(context);
                      },
              ),
            ISpectSheetActionButton(
              icon: Icons.copy_rounded,
              label: l10n.copyToClipboardTruncated,
              onPressed: isExporting
                  ? null
                  : () {
                      controller.copy(context, contentBuilder);
                      _closeSheet(context);
                    },
            ),
          ],
        ),
      ],
    );
  }
}
