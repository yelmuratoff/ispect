import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispectify/ispectify.dart';

enum LogContextAction {
  copyMessage,
  share,
  copyCurl,
  openDetail,
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
  void Function(String)? onTypeFilterTap,
}) async {
  final l10n = context.ispectL10n;
  final overlay =
      Overlay.of(context).context.findRenderObject()! as RenderBox;

  final action = await showMenu<LogContextAction>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        value: LogContextAction.copyMessage,
        height: 36,
        child: _ContextMenuRow(
          icon: Icons.content_copy_rounded,
          label: l10n.copy,
        ),
      ),
      PopupMenuItem(
        value: LogContextAction.share,
        height: 36,
        child:
            _ContextMenuRow(icon: Icons.share_rounded, label: l10n.share),
      ),
      if (data.curlCommand != null)
        PopupMenuItem(
          value: LogContextAction.copyCurl,
          height: 36,
          child: _ContextMenuRow(
            icon: Icons.terminal_rounded,
            label: l10n.copyAsCurl,
          ),
        ),
      PopupMenuItem(
        value: LogContextAction.openDetail,
        height: 36,
        child: _ContextMenuRow(
          icon: Icons.open_in_full_rounded,
          label: l10n.expandLogs,
        ),
      ),
      if (data.key != null && onTypeFilterTap != null) ...[
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: LogContextAction.showOnlyType,
          height: 36,
          child: _ContextMenuRow(
            icon: Icons.filter_alt_rounded,
            label: l10n.showOnlyThisType,
          ),
        ),
        PopupMenuItem(
          value: LogContextAction.hideType,
          height: 36,
          child: _ContextMenuRow(
            icon: Icons.filter_alt_off_rounded,
            label: l10n.hideThisType,
          ),
        ),
      ],
    ],
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case LogContextAction.copyMessage:
      copyClipboard(context, value: message);
    case LogContextAction.share:
      onShareTap?.call();
    case LogContextAction.copyCurl:
      final curl = data.curlCommand;
      if (curl != null) copyClipboard(context, value: curl);
    case LogContextAction.openDetail:
      onOpenDetail?.call();
    case LogContextAction.showOnlyType:
      final key = data.key;
      if (key != null) onTypeFilterTap?.call('__show_only__$key');
    case LogContextAction.hideType:
      final key = data.key;
      if (key != null) onTypeFilterTap?.call('__hide__$key');
  }
}

class _ContextMenuRow extends StatelessWidget {
  const _ContextMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const Gap(10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );
}
