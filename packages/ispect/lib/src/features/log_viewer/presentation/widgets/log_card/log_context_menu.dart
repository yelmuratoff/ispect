import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/default_curl_redactor.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/common/widgets/ispect_icon_badge.dart';
import 'package:ispect/src/core/localization/generated/ispect_localizations.dart';
import 'package:ispectify/ispectify.dart';

enum LogContextAction {
  copyMessage,
  share,
  copyCurl,
  openDetail,
  navigationFlow,
  showOnlyType,
  hideType,
}

Future<void> showLogContextMenu({
  required BuildContext context,
  required Offset position,
  required ISpectLogData data,
  required String message,
  VoidCallback? onShareTap,
  VoidCallback? onOpenDetail,
  VoidCallback? onNavigationFlowTap,
  void Function(String)? onTypeFilterTap,
}) async {
  final l10n = context.ispectL10n;

  final hasFilterActions = data.key != null && onTypeFilterTap != null;
  final hasNavigationFlow = onNavigationFlowTap != null;
  final logDescription =
      context.iSpect.theme.getTypeDescription(context, key: data.key);

  // Sheet sizing roughly tracks how many tiles we render.
  final tileCount = 3 // copy, share, expand always present
      +
      (data.curlCommand != null ? 1 : 0) +
      (hasNavigationFlow ? 1 : 0) +
      (hasFilterActions ? 2 : 0);
  final estimatedSize = (0.18 + 0.06 * tileCount).clamp(0.32, 0.7);

  final action = await showISpectSheet<LogContextAction>(
    context,
    initialChildSize: estimatedSize,
    maxChildSize: (estimatedSize + 0.1).clamp(0.45, 0.85),
    topOnlyRadius: true,
    builder: (context, scrollController) => SafeArea(
      child: _LogContextMenuSheet(
        hasCurl: data.curlCommand != null,
        hasNavigationFlow: hasNavigationFlow,
        hasFilterActions: hasFilterActions,
        l10n: l10n,
        subtitle: logDescription,
        scrollController: scrollController,
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case LogContextAction.copyMessage:
      copyClipboard(context, value: message, redact: true);
    case LogContextAction.share:
      onShareTap?.call();
    case LogContextAction.copyCurl:
      final curl = data.curlCommandWith(redactor: defaultCurlRedactor);
      if (curl != null) copyClipboard(context, value: curl);
    case LogContextAction.openDetail:
      onOpenDetail?.call();
    case LogContextAction.navigationFlow:
      onNavigationFlowTap?.call();
    case LogContextAction.showOnlyType:
      final key = data.key;
      if (key != null) onTypeFilterTap?.call('__show_only__$key');
    case LogContextAction.hideType:
      final key = data.key;
      if (key != null) onTypeFilterTap?.call('__hide__$key');
  }
}

class _LogContextMenuSheet extends StatelessWidget {
  const _LogContextMenuSheet({
    required this.hasCurl,
    required this.hasNavigationFlow,
    required this.hasFilterActions,
    required this.l10n,
    this.subtitle,
    this.scrollController,
  });

  final bool hasCurl;
  final bool hasNavigationFlow;
  final bool hasFilterActions;
  final ISpectGeneratedLocalization l10n;
  final String? subtitle;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ISpectDragHandle(),
          const Gap(8),
          ISpectBottomSheetHeader(
            title: l10n.actions,
            subtitle: subtitle,
            icon: Icons.more_horiz_rounded,
          ),
          const Gap(8),
          Flexible(
            child: ListView(
              controller: scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _ActionTile(
                  icon: Icons.content_copy_rounded,
                  label: l10n.copy,
                  onTap: () => Navigator.pop(
                    context,
                    LogContextAction.copyMessage,
                  ),
                ),
                _ActionTile(
                  icon: Icons.share_rounded,
                  label: l10n.share,
                  onTap: () => Navigator.pop(
                    context,
                    LogContextAction.share,
                  ),
                ),
                if (hasCurl)
                  _ActionTile(
                    icon: Icons.terminal_rounded,
                    label: l10n.copyAsCurl,
                    onTap: () => Navigator.pop(
                      context,
                      LogContextAction.copyCurl,
                    ),
                  ),
                _ActionTile(
                  icon: Icons.open_in_full_rounded,
                  label: l10n.expandLogs,
                  onTap: () => Navigator.pop(
                    context,
                    LogContextAction.openDetail,
                  ),
                ),
                if (hasNavigationFlow)
                  _ActionTile(
                    icon: Icons.compare_arrows_rounded,
                    label: l10n.navigationFlow,
                    onTap: () => Navigator.pop(
                      context,
                      LogContextAction.navigationFlow,
                    ),
                  ),
                if (hasFilterActions) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: context.appTheme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  const ISpectSectionLabel(title: 'Filter'),
                  _ActionTile(
                    icon: Icons.filter_alt_rounded,
                    label: l10n.showOnlyThisType,
                    onTap: () => Navigator.pop(
                      context,
                      LogContextAction.showOnlyType,
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.filter_alt_off_rounded,
                    label: l10n.hideThisType,
                    onTap: () => Navigator.pop(
                      context,
                      LogContextAction.hideType,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: ISpectBorderedSurface(
          onTap: onTap,
          backgroundColor: Colors.transparent,
          semanticsLabel: label,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ISpectIconBadge(icon: icon, size: ISpectIconBadgeSize.small),
              const Gap(10),
              Expanded(
                child: Text(
                  label,
                  style: context.appTheme.textTheme.bodyMedium?.copyWith(
                    color: context.appTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: context.appTheme.textColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      );
}
