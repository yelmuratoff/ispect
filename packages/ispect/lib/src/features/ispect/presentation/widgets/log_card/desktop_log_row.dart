import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';

/// A sticky table header row for the desktop log table.
class DesktopLogTableHeader extends StatelessWidget {
  const DesktopLogTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.08);
    final labelColor = onSurface.withValues(alpha: 0.45);
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 24),
            const Gap(8),
            SizedBox(
              width: 120,
              child: Text(
                'TYPE',
                style: labelStyle.copyWith(color: labelColor),
              ),
            ),
            const Gap(8),
            SizedBox(
              width: 140,
              child: Text(
                'TIME',
                style: labelStyle.copyWith(color: labelColor),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                'MESSAGE',
                style: labelStyle.copyWith(color: labelColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact, single-line log row optimized for desktop/web layouts.
///
/// Displays log entries in a table-like format with columns:
/// [accent bar] [icon] [type] [timestamp] [message] [actions]
///
/// Desktop UX features:
/// - Zebra striping for readability
/// - Hover highlight
/// - Tooltip on truncated message
/// - Right-click context menu
class DesktopLogRow extends StatefulWidget {
  const DesktopLogRow({
    required this.icon,
    required this.color,
    required this.data,
    required this.isSelected,
    required this.onTap,
    this.index = 0,
    this.observer,
    this.onShareTap,
    super.key,
  });

  final ISpectLogData data;
  final IconData icon;
  final Color color;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onShareTap;
  final ISpectNavigatorObserver? observer;

  @override
  State<DesktopLogRow> createState() => _DesktopLogRowState();
}

class _DesktopLogRowState extends State<DesktopLogRow> {
  bool _isHovered = false;

  String get _message {
    final msg = widget.data.isHttpLog
        ? widget.data.httpLogText
        : widget.data.textMessage;
    return msg ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.06);

    // Zebra striping
    final isOdd = widget.index.isOdd;
    final zebraColor = isOdd ? onSurface.withValues(alpha: 0.015) : cardColor;

    final bgColor = widget.isSelected
        ? widget.color.withValues(alpha: 0.1)
        : _isHovered
            ? onSurface.withValues(alpha: 0.04)
            : zebraColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: borderColor),
              left: BorderSide(
                color: widget.isSelected
                    ? widget.color
                    : widget.color.withValues(alpha: 0.3),
                width: widget.isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: widget.color),
                const Gap(8),
                SizedBox(
                  width: 120,
                  child: Text(
                    widget.data.key ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Gap(8),
                SizedBox(
                  width: 140,
                  child: Text(
                    widget.data.formattedTime,
                    maxLines: 1,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Gap(12),
                // Message with tooltip on hover
                Expanded(
                  child: Tooltip(
                    message: _message.length > 80 ? _message : '',
                    waitDuration: const Duration(milliseconds: 500),
                    child: Text(
                      _message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Actions (visible on hover or selected)
                if (_isHovered || widget.isSelected) ...[
                  const Gap(8),
                  _DesktopRowActions(
                    color: widget.color,
                    data: widget.data,
                    observer: widget.observer,
                    onShareTap: widget.onShareTap,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    Offset position,
  ) async {
    final l10n = context.ispectL10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final action = await showMenu<_ContextAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _ContextAction.copyMessage,
          height: 36,
          child: _ContextMenuRow(
            icon: Icons.content_copy_rounded,
            label: l10n.copy,
          ),
        ),
        PopupMenuItem(
          value: _ContextAction.share,
          height: 36,
          child:
              _ContextMenuRow(icon: Icons.share_rounded, label: l10n.share),
        ),
        if (widget.data.curlCommand != null)
          PopupMenuItem(
            value: _ContextAction.copyCurl,
            height: 36,
            child: _ContextMenuRow(
              icon: Icons.terminal_rounded,
              label: l10n.copyAsCurl,
            ),
          ),
        PopupMenuItem(
          value: _ContextAction.openDetail,
          height: 36,
          child: _ContextMenuRow(
            icon: Icons.open_in_full_rounded,
            label: l10n.expandLogs,
          ),
        ),
      ],
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case _ContextAction.copyMessage:
        copyClipboard(context, value: _message);
      case _ContextAction.share:
        widget.onShareTap?.call();
      case _ContextAction.copyCurl:
        final curl = widget.data.curlCommand;
        if (curl != null) copyClipboard(context, value: curl);
      case _ContextAction.openDetail:
        JsonScreen(
          data: widget.data.toJson(),
          truncatedData: widget.data.toJson(truncated: true),
        ).push(context);
    }
  }
}

enum _ContextAction { copyMessage, share, copyCurl, openDetail }

class _ContextMenuRow extends StatelessWidget {
  const _ContextMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16),
          const Gap(10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );
}

class _DesktopRowActions extends StatelessWidget {
  const _DesktopRowActions({
    required this.color,
    required this.data,
    required this.observer,
    required this.onShareTap,
  });

  final Color color;
  final ISpectLogData data;
  final ISpectNavigatorObserver? observer;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data is RouteLog && observer != null)
            _DesktopActionIcon(
              icon: Icons.compare_arrows_rounded,
              color: color,
              tooltip: context.ispectL10n.navigationFlow,
              onPressed: () => ISpectNavigationFlowScreen(
                observer: observer!,
                log: data as RouteLog,
              ).push(context),
            ),
          _DesktopActionIcon(
            icon: Icons.share_rounded,
            color: color,
            tooltip: context.ispectL10n.share,
            onPressed: onShareTap,
          ),
          if (data.curlCommand != null)
            _DesktopActionIcon(
              icon: Icons.terminal_rounded,
              color: color,
              tooltip: context.ispectL10n.copyAsCurl,
              onPressed: () =>
                  copyClipboard(context, value: data.curlCommand!),
            ),
          _DesktopActionIcon(
            icon: Icons.open_in_full_rounded,
            color: color,
            tooltip: context.ispectL10n.expandLogs,
            onPressed: () => JsonScreen(
              data: data.toJson(),
              truncatedData: data.toJson(truncated: true),
            ).push(context),
          ),
        ],
      );
}

class _DesktopActionIcon extends StatelessWidget {
  const _DesktopActionIcon({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 15,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
}
