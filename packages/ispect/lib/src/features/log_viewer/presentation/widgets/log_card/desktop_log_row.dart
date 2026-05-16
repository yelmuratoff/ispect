import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/default_curl_redactor.dart';
import 'package:ispect/src/common/utils/severity_bar.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/slow_badge.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/column_widths.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_context_menu.dart';

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
    this.typeColumnWidth = 100,
    this.timeColumnWidth = 140,
    this.searchMatchState = SearchMatchState.none,
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
  final SearchMatchState searchMatchState;

  @override
  State<DesktopLogRow> createState() => _DesktopLogRowState();
}

class _DesktopLogRowState extends State<DesktopLogRow> {
  bool _isHovered = false;
  OverlayEntry? _tooltipOverlay;
  Timer? _tooltipTimer;
  Offset _mousePosition = Offset.zero;

  static const _tooltipDelay = Duration(milliseconds: 400);

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

  /// Single tap opens the detail panel immediately.
  void _handleTap() {
    widget.onOpenDetail?.call();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectRowCardColor;
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = context.ispectFaintBorderColor;

    // Zebra striping
    final isOdd = widget.index.isOdd;
    final zebraColor = isOdd ? onSurface.withValues(alpha: 0.015) : cardColor;

    final primaryColor = context.appTheme.colorScheme.primary;
    final isFocused = widget.searchMatchState == SearchMatchState.focused;
    final isMatch = widget.searchMatchState == SearchMatchState.match;

    final Color bgColor;
    if (isFocused) {
      bgColor = primaryColor.withValues(alpha: 0.16);
    } else if (isMatch) {
      bgColor = primaryColor.withValues(alpha: 0.08);
    } else if (widget.isSelected) {
      bgColor = widget.color.withValues(alpha: 0.16);
    } else if (_isHovered) {
      bgColor = onSurface.withValues(alpha: 0.08);
    } else {
      bgColor = zebraColor;
    }

    final semanticLabel =
        '${ISpectLogType.fromKey(widget.data.key ?? '')?.displayTitle ?? widget.data.key ?? "Log"}: $_message';
    final semanticTap = widget.onOpenDetail != null ? _handleTap : widget.onTap;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onHover: (event) => _mousePosition = event.position,
      onExit: (_) {
        setState(() => _isHovered = false);
        _cancelTooltip();
      },
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: semanticLabel,
        onTap: semanticTap,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: semanticTap,
          onSecondaryTapUp: (details) =>
              _showContextMenu(context, details.globalPosition),
          onLongPress: () => _showContextMenu(context, _mousePosition),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
                left: BorderSide(
                  color: isFocused
                      ? primaryColor
                      : isMatch
                          ? primaryColor.withValues(alpha: 0.6)
                          : widget.isSelected
                              ? widget.color
                              : widget.color.withValues(
                                  alpha: severityBar(widget.data).alpha,
                                ),
                  width: isFocused || widget.isSelected
                      ? severityBar(widget.data).width + 1
                      : severityBar(widget.data).width,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact =
                      constraints.maxWidth < kDesktopLogCompactBreakpoint;
                  final scaled = scaleColumnWidths(
                    available: constraints.maxWidth,
                    typeWidth: isCompact
                        ? kCompactTypeColumnWidth
                        : widget.typeColumnWidth,
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
                          child: _TypeFilterTarget(
                            typeKey: widget.data.key,
                            color: widget.color,
                            onTypeFilterTap: widget.onTypeFilterTap,
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
                      if (widget.data.httpStatusCode
                          case final int statusCode) ...[
                        _DesktopStatusCodeBadge(statusCode: statusCode),
                        const Gap(8),
                      ],
                      if ((widget.data.traceSlow ?? false) &&
                          widget.data.traceDurationMs != null) ...[
                        SlowBadge(durationMs: widget.data.traceDurationMs!),
                        const Gap(8),
                      ],
                      Expanded(
                        child: MouseRegion(
                          onEnter: _message.isNotEmpty
                              ? (_) => _scheduleTooltip(_message)
                              : null,
                          onExit: (_) => _cancelTooltip(),
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
      ),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    Offset position,
  ) =>
      showLogContextMenu(
        context: context,
        position: position,
        data: widget.data,
        message: _message,
        onShareTap: widget.onShareTap,
        onOpenDetail: widget.onOpenDetail ?? widget.onTap,
        onTypeFilterTap: widget.onTypeFilterTap,
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
          if (data.isRouteLog && observer != null)
            _DesktopActionIcon(
              icon: Icons.compare_arrows_rounded,
              color: color,
              tooltip: context.ispectL10n.navigationFlow,
              onPressed: () => ISpectNavigationFlowScreen(
                observer: observer!,
                log: data,
              ).push(context),
            ),
          _DesktopActionIcon(
            icon: Icons.share_rounded,
            color: color,
            tooltip: context.ispectL10n.share,
            onPressed: onShareTap,
          ),
          if (data.curlCommandWith(redactor: defaultCurlRedactor)
              case final curl?)
            _DesktopActionIcon(
              icon: Icons.terminal_rounded,
              color: color,
              tooltip: context.ispectL10n.copyAsCurl,
              onPressed: () => copyClipboard(context, value: curl),
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
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip ?? '',
        onTap: onPressed,
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            excludeFromSemantics: true,
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
        ),
      );
}

class _DesktopStatusCodeBadge extends StatelessWidget {
  const _DesktopStatusCodeBadge({required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (statusCode) {
      < 300 => (const Color(0xFF4CAF50), const Color(0xFF2E7D32)),
      < 400 => (const Color(0xFFFF9800), const Color(0xFFE65100)),
      _ => (const Color(0xFFF44336), const Color(0xFFC62828)),
    };
    return Semantics(
      container: true,
      label: 'HTTP status $statusCode',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            '$statusCode',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeFilterTarget extends StatelessWidget {
  const _TypeFilterTarget({
    required this.typeKey,
    required this.color,
    required this.onTypeFilterTap,
  });

  final String? typeKey;
  final Color color;
  final void Function(String type)? onTypeFilterTap;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTypeFilterTap != null && typeKey != null;
    final onTap = isInteractive ? () => onTypeFilterTap!(typeKey!) : null;
    final text = Text(
      typeKey ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
    if (!isInteractive) {
      return text;
    }
    return Semantics(
      button: true,
      label: 'Filter by type ${typeKey!}',
      onTap: onTap,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: onTap,
        child: text,
      ),
    );
  }
}
