import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
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
    final primaryColor = context.ispectPrimaryColor;
    final outlineColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final format in controller.availableFormats)
            Builder(
              builder: (context) {
                final isSelected = controller.selectedFormat == format;
                return ChoiceChip(
                  label: Text(
                    format.label,
                    style: TextStyle(
                      color: isSelected ? primaryColor : null,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  avatar: Icon(
                    format.icon,
                    size: 16,
                    color: isSelected ? primaryColor : null,
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor.withValues(alpha: 0.18),
                  side: BorderSide(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.7)
                        : outlineColor,
                    width: isSelected ? 1.4 : 1,
                  ),
                  showCheckmark: false,
                  onSelected: (_) => controller.selectFormat(format),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
        ],
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
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final capturedL10n = context.ispectL10n;
                      final onOpenFile = context.iSpect.options.onOpenFile;

                      _closeSheet(context);

                      unawaited(
                        ISpectToaster.showLoadingToast(
                          null,
                          title: capturedL10n.downloadLogsFile,
                          messenger: messenger,
                        ),
                      );

                      await controller.download(contentBuilder);
                      final path = controller.resultPath;
                      if (path.isEmpty) return;

                      if (kIsWeb) {
                        unawaited(
                          ISpectToaster.showInfoToast(
                            null,
                            title: capturedL10n.downloadLogsFile,
                            messenger: messenger,
                          ),
                        );
                      } else {
                        final SnackBarAction action;
                        if (onOpenFile != null) {
                          action = SnackBarAction(
                            label: capturedL10n.openPath,
                            onPressed: () {
                              onOpenFile(path).catchError((Object error) {
                                assert(() {
                                  debugPrint('Failed to open file: $error');
                                  return true;
                                }());
                              });
                            },
                          );
                        } else {
                          action = SnackBarAction(
                            label: capturedL10n.copyPath,
                            onPressed: () {
                              copyClipboard(
                                null,
                                value: path,
                                messenger: messenger,
                                l10n: capturedL10n,
                              );
                            },
                          );
                        }
                        final fileName = path.split(RegExp(r'[/\\]')).last;
                        unawaited(
                          ISpectToaster.showInfoToast(
                            null,
                            title: capturedL10n.logsFileSaved(fileName),
                            duration: const Duration(seconds: 6),
                            messenger: messenger,
                            l10n: capturedL10n,
                            action: action,
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
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final capturedL10n = context.ispectL10n;
                      controller.copy(context, contentBuilder);
                      _closeSheet(context);
                      unawaited(
                        ISpectToaster.showCopiedToast(
                          null,
                          value: '',
                          showValue: false,
                          messenger: messenger,
                          l10n: capturedL10n,
                        ),
                      );
                    },
            ),
          ],
        ),
      ],
    );
  }
}
