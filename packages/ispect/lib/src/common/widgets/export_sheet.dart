import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
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
                    if (controller.state == ExportState.exporting)
                      const _LoadingIndicator()
                    else
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
                child: Switch.adaptive(
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

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ISpectSheetActionButton(
            icon: Icons.download_rounded,
            label: context.ispectL10n.downloadLogsFile,
            onPressed: () async {
              await controller.download(contentBuilder);
              if (!context.mounted) return;
              final path = controller.resultPath;
              if (path.isNotEmpty) {
                final message = kIsWeb
                    ? context.ispectL10n.downloadLogsFile
                    : context.ispectL10n.logsFileSaved(path);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }
            },
          ),
          if (controller.canShare)
            ISpectSheetActionButton(
              icon: Icons.share_rounded,
              label: context.ispectL10n.share,
              onPressed: () => controller.share(contentBuilder),
            ),
          ISpectSheetActionButton(
            icon: Icons.copy_rounded,
            label: context.ispectL10n.copyToClipboardTruncated,
            onPressed: () => controller.copy(context, contentBuilder),
          ),
        ],
      );
}

// ── Loading indicator ─────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
        ),
      ),
    );
  }
}
