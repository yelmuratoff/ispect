import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';

/// Proportionally scale type/time column widths so they never overflow.
/// Both columns shrink equally when space is tight.
({double typeWidth, double timeWidth}) _scaleColumnWidths({
  required double available,
  required double typeWidth,
  required double timeWidth,
}) {
  final totalColumns = typeWidth + timeWidth;
  if (totalColumns <= 0) return (typeWidth: typeWidth, timeWidth: timeWidth);

  // Columns should use at most half the available width
  final maxForColumns = available * 0.5;
  if (totalColumns > maxForColumns) {
    final scale = maxForColumns / totalColumns;
    return (typeWidth: typeWidth * scale, timeWidth: timeWidth * scale);
  }
  return (typeWidth: typeWidth, timeWidth: timeWidth);
}

/// A sticky table header row for the desktop log table.
class DesktopLogTableHeader extends StatelessWidget {
  const DesktopLogTableHeader({
    super.key,
    this.backgroundColor,
    this.sortColumn,
    this.sortDirection,
    this.onSortTap,
    this.typeColumnWidth = 140,
    this.timeColumnWidth = 140,
    this.onColumnResize,
  });

  final Color? backgroundColor;
  final int? sortColumn;
  final int? sortDirection;
  final void Function(int column)? onSortTap;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final void Function(int column, double delta)? onColumnResize;

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
        color: backgroundColor ?? context.appTheme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 480;
          final scaled = _scaleColumnWidths(
            available: constraints.maxWidth,
            typeWidth: isCompact ? 40 : typeColumnWidth,
            timeWidth: isCompact ? 0 : timeColumnWidth,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const Gap(8),
                _SortableColumnHeader(
                  label: 'TYPE',
                  width: scaled.typeWidth,
                  columnIndex: 0,
                  isActive: sortColumn == 0,
                  isAscending: sortDirection == 0,
                  onTap: onSortTap,
                  labelStyle: labelStyle,
                  labelColor: labelColor,
                  onResize: onColumnResize,
                ),
                const Gap(8),
                if (!isCompact) ...[
                  _SortableColumnHeader(
                    label: 'TIME',
                    width: scaled.timeWidth,
                    columnIndex: 1,
                    isActive: sortColumn == 1,
                    isAscending: sortDirection == 0,
                    onTap: onSortTap,
                    labelStyle: labelStyle,
                    labelColor: labelColor,
                    onResize: onColumnResize,
                  ),
                  const Gap(12),
                ],
                Expanded(
                  child: _SortableColumnHeader(
                    label: 'MESSAGE',
                    columnIndex: 2,
                    isActive: sortColumn == 2,
                    isAscending: sortDirection == 0,
                    onTap: onSortTap,
                    labelStyle: labelStyle,
                    labelColor: labelColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SortableColumnHeader extends StatelessWidget {
  const _SortableColumnHeader({
    required this.label,
    required this.columnIndex,
    required this.isActive,
    required this.isAscending,
    required this.labelStyle,
    required this.labelColor,
    this.width,
    this.onTap,
    this.onResize,
  });

  final String label;
  final int columnIndex;
  final double? width;
  final bool isActive;
  final bool isAscending;
  final void Function(int column)? onTap;
  final TextStyle labelStyle;
  final Color labelColor;
  final void Function(int column, double delta)? onResize;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.7);

    Widget header = MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap != null ? () => onTap!(columnIndex) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: labelStyle.copyWith(
                  color: isActive ? activeColor : labelColor,
                ),
              ),
            ),
            const Gap(2),
            Icon(
              isActive
                  ? (isAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 12,
              color: isActive ? activeColor : labelColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );

    if (width != null) {
      header = SizedBox(
        width: width,
        child: Row(
          children: [
            Expanded(child: header),
            if (onResize != null)
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) =>
                      onResize!(columnIndex, details.delta.dx),
                  child: SizedBox(
                    width: 12,
                    height: 20,
                    child: Center(
                      child: Container(
                        width: 2,
                        height: 14,
                        decoration: BoxDecoration(
                          color: labelColor.withValues(alpha: 0.3),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(1)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return header;
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
    this.onOpenDetail,
    this.onTypeFilterTap,
    this.useRelativeTime = false,
    this.typeColumnWidth = 140,
    this.timeColumnWidth = 140,
    super.key,
  });

  final ISpectLogData data;
  final IconData icon;
  final Color color;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onShareTap;
  final void Function(String type)? onTypeFilterTap;
  final ISpectNavigatorObserver? observer;
  final bool useRelativeTime;
  final double typeColumnWidth;
  final double timeColumnWidth;

  @override
  State<DesktopLogRow> createState() => _DesktopLogRowState();
}

class _DesktopLogRowState extends State<DesktopLogRow> {
  bool _isHovered = false;
  OverlayEntry? _tooltipOverlay;
  Timer? _tooltipTimer;
  Timer? _singleClickTimer;
  Offset _mousePosition = Offset.zero;

  static const _tooltipDelay = Duration(milliseconds: 400);
  static const _doubleClickWindow = Duration(milliseconds: 250);

  String get _message {
    final msg = widget.data.isHttpLog
        ? widget.data.httpLogText
        : widget.data.textMessage;
    return msg ?? '';
  }

  String get _displayTime {
    if (widget.useRelativeTime) {
      final l10n = context.ispectL10n;
      return ISpectDateTimeFormatter(widget.data.time).relativeFormat(
        justNow: l10n.relativeJustNow,
        secondsAgo: l10n.relativeSecondsAgo,
        minutesAgo: l10n.relativeMinutesAgo,
        hoursAgo: l10n.relativeHoursAgo,
      );
    }
    return widget.data.formattedTime;
  }

  void _scheduleTooltip(String text) {
    _cancelTooltip();
    if (text.isEmpty) return;

    _tooltipTimer = Timer(_tooltipDelay, () {
      if (!mounted) return;
      _showOverlayTooltip(text);
    });
  }

  void _showOverlayTooltip(String text) {
    _removeTooltip();

    // Capture position at the moment of showing
    final position = _mousePosition;
    final overlay = Overlay.of(context);
    _tooltipOverlay = OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        const tooltipMaxWidth = 400.0;

        // Position near cursor
        var left = position.dx + 12;
        var top = position.dy - 32;

        // Keep tooltip within screen bounds
        if (left + tooltipMaxWidth > screenSize.width - 8) {
          left = position.dx - tooltipMaxWidth - 12;
        }
        if (top < 8) {
          top = position.dy + 20;
        }

        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Container(
                constraints: const BoxConstraints(maxWidth: tooltipMaxWidth),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  text,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_tooltipOverlay!);
  }

  void _cancelTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _removeTooltip();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay?.dispose();
    _tooltipOverlay = null;
  }

  /// Handle tap with manual double-click detection to avoid the ~300ms delay
  /// that Flutter adds when both onTap and onDoubleTap are on the same
  /// GestureDetector.
  void _handleTap() {
    if (_singleClickTimer != null) {
      // Second tap within window → double click
      _singleClickTimer!.cancel();
      _singleClickTimer = null;
      widget.onOpenDetail?.call();
    } else {
      // First tap → schedule single click
      _singleClickTimer = Timer(_doubleClickWindow, () {
        _singleClickTimer = null;
        widget.onTap();
      });
    }
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _singleClickTimer?.cancel();
    _removeTooltip();
    super.dispose();
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
      onHover: (event) => _mousePosition = event.position,
      onExit: (_) {
        setState(() => _isHovered = false);
        _cancelTooltip();
      },
      child: GestureDetector(
        onTap: widget.onOpenDetail != null ? _handleTap : widget.onTap,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 480;
                final scaled = _scaleColumnWidths(
                  available: constraints.maxWidth,
                  typeWidth: isCompact ? 40 : widget.typeColumnWidth,
                  timeWidth: isCompact ? 0 : widget.timeColumnWidth,
                );
                return Row(
                  children: [
                    Icon(widget.icon, size: 16, color: widget.color),
                    const Gap(8),
                    // Type column
                    SizedBox(
                      width: scaled.typeWidth,
                      child: MouseRegion(
                        cursor: widget.onTypeFilterTap != null
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        onEnter: (_) {
                          final desc =
                              ISpect.read(context).theme.getTypeDescription(
                                    context,
                                    key: widget.data.key,
                                  );
                          if (desc != null) _scheduleTooltip(desc);
                        },
                        onExit: (_) => _cancelTooltip(),
                        child: GestureDetector(
                          onTap: widget.onTypeFilterTap != null &&
                                  widget.data.key != null
                              ? () => widget.onTypeFilterTap!(widget.data.key!)
                              : null,
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
                      ),
                    ),
                    const Gap(8),
                    if (!isCompact) ...[
                      SizedBox(
                        width: scaled.timeWidth,
                        child: Text(
                          _displayTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const Gap(12),
                    ],
                    // Message - takes remaining space
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, messageConstraints) {
                          final messageStyle = TextStyle(
                            color: onSurface.withValues(alpha: 0.75),
                            fontSize: 12,
                          );
                          final textSpan = TextSpan(
                            text: _message,
                            style: messageStyle,
                          );
                          final tp = TextPainter(
                            text: textSpan,
                            maxLines: 1,
                            textDirection: TextDirection.ltr,
                          )..layout(
                              maxWidth: messageConstraints.maxWidth,
                            );
                          final isOverflowing = tp.didExceedMaxLines;
                          tp.dispose();

                          return MouseRegion(
                            onEnter: isOverflowing
                                ? (_) => _scheduleTooltip(_message)
                                : null,
                            onExit:
                                isOverflowing ? (_) => _cancelTooltip() : null,
                            child: Text(
                              _message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: messageStyle,
                            ),
                          );
                        },
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
                        onOpenDetail: widget.onOpenDetail ?? widget.onTap,
                      ),
                    ],
                  ],
                );
              },
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
          child: _ContextMenuRow(icon: Icons.share_rounded, label: l10n.share),
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
        if (widget.data.key != null) ...[
          const PopupMenuDivider(height: 8),
          PopupMenuItem(
            value: _ContextAction.showOnlyType,
            height: 36,
            child: _ContextMenuRow(
              icon: Icons.filter_alt_rounded,
              label: l10n.showOnlyThisType,
            ),
          ),
          PopupMenuItem(
            value: _ContextAction.hideType,
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
      case _ContextAction.copyMessage:
        copyClipboard(context, value: _message);
      case _ContextAction.share:
        widget.onShareTap?.call();
      case _ContextAction.copyCurl:
        final curl = widget.data.curlCommand;
        if (curl != null) copyClipboard(context, value: curl);
      case _ContextAction.openDetail:
        (widget.onOpenDetail ?? widget.onTap).call();
      case _ContextAction.showOnlyType:
        widget.onTypeFilterTap?.call('__show_only__${widget.data.key!}');
      case _ContextAction.hideType:
        widget.onTypeFilterTap?.call('__hide__${widget.data.key!}');
    }
  }
}

enum _ContextAction {
  copyMessage,
  share,
  copyCurl,
  openDetail,
  showOnlyType,
  hideType,
}

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
    required this.onOpenDetail,
  });

  final Color color;
  final ISpectLogData data;
  final ISpectNavigatorObserver? observer;
  final VoidCallback? onShareTap;
  final VoidCallback onOpenDetail;

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
              onPressed: () => copyClipboard(context, value: data.curlCommand!),
            ),
          _DesktopActionIcon(
            icon: Icons.open_in_full_rounded,
            color: color,
            tooltip: context.ispectL10n.expandLogs,
            onPressed: onOpenDetail,
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
