import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_log_bottom_sheet.dart';

/// Displays a grouped HTTP transaction (request + response/error).
///
/// Adapts between mobile card style and desktop table-row style
/// based on screen size.
class NetworkTransactionCard extends StatelessWidget {
  const NetworkTransactionCard({
    required this.transaction,
    this.onTap,
    this.onOpenRequestDetail,
    this.onOpenResponseDetail,
    this.typeColumnWidth = 100,
    this.timeColumnWidth = 140,
    super.key,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final double typeColumnWidth;
  final double timeColumnWidth;

  @override
  Widget build(BuildContext context) {
    if (context.screenSize.isDesktop) {
      return _DesktopTransactionRow(
        transaction: transaction,
        onTap: onTap,
        onOpenRequestDetail: onOpenRequestDetail,
        onOpenResponseDetail: onOpenResponseDetail,
        typeColumnWidth: typeColumnWidth,
        timeColumnWidth: timeColumnWidth,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: _MobileTransactionCard(
        transaction: transaction,
        onTap: onTap,
        onOpenRequestDetail: onOpenRequestDetail,
        onOpenResponseDetail: onOpenResponseDetail,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Color _transactionColor(NetworkTransaction tx) {
  if (tx.isError) return const Color(0xFFF44336);
  if (tx.isPending) return const Color(0xFFFF9800);
  final code = tx.statusCode;
  if (code != null && code >= 400) return const Color(0xFFF44336);
  return const Color(0xFF4CAF50);
}

String _formatDuration(Duration duration) {
  if (duration.inMilliseconds < 1000) {
    return '${duration.inMilliseconds}ms';
  }
  return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
}

void _shareTransaction(BuildContext context, NetworkTransaction tx) {
  final responseLog = tx.response ?? tx.error;

  // If only request exists (pending), share directly.
  if (responseLog == null) {
    ISpectShareLogBottomSheet(
      data: tx.request.toJson(),
      truncatedData: tx.request.toJson(truncated: true),
    ).show(context);
    return;
  }

  final l10n = ISpectLocalization.of(context);
  _showTransactionShareSheet(
    context,
    request: tx.request,
    response: responseLog,
    requestLabel: l10n.httpRequest,
    responseLabel: l10n.httpResponse,
  );
}

void _showTransactionShareSheet(
  BuildContext context, {
  required ISpectLogData request,
  required ISpectLogData response,
  required String requestLabel,
  required String responseLabel,
}) {
  ISpectShareSheet.show(
    context,
    actionsBuilder: (sheetContext) => [
      ISpectSheetActionButton(
        icon: Icons.arrow_upward_rounded,
        label: requestLabel,
        onPressed: () {
          Navigator.of(sheetContext).pop();
          ISpectShareLogBottomSheet(
            data: request.toJson(),
            truncatedData: request.toJson(truncated: true),
          ).show(context);
        },
      ),
      ISpectSheetActionButton(
        icon: Icons.arrow_downward_rounded,
        label: responseLabel,
        onPressed: () {
          Navigator.of(sheetContext).pop();
          ISpectShareLogBottomSheet(
            data: response.toJson(),
            truncatedData: response.toJson(truncated: true),
          ).show(context);
        },
      ),
    ],
  );
}

/// Builds action buttons row for both mobile and desktop.
List<Widget> _buildActionWidgets({
  required BuildContext context,
  required NetworkTransaction tx,
  required Color color,
  required bool useDesktopStyle,
  VoidCallback? onOpenRequestDetail,
  VoidCallback? onOpenResponseDetail,
}) {
  final l10n = ISpectLocalization.of(context);
  final widgets = <Widget>[];

  if (useDesktopStyle) {
    widgets.add(
      _SmallActionIcon(
        icon: Icons.share_rounded,
        color: color,
        tooltip: l10n.share,
        onPressed: () => _shareTransaction(context, tx),
      ),
    );
    if (tx.request.curlCommand != null) {
      widgets.add(
        _SmallActionIcon(
          icon: Icons.terminal_rounded,
          color: color,
          tooltip: l10n.copyAsCurl,
          onPressed: () =>
              copyClipboard(context, value: tx.request.curlCommand!),
        ),
      );
    }
    if (onOpenRequestDetail != null) {
      widgets.add(
        _DetailChip(
          label: l10n.httpRequest,
          color: color,
          onTap: onOpenRequestDetail,
        ),
      );
    }
    if ((tx.response != null || tx.error != null) &&
        onOpenResponseDetail != null) {
      widgets.add(
        _DetailChip(
          label: l10n.httpResponse,
          color: color,
          onTap: onOpenResponseDetail,
        ),
      );
    }
  } else {
    widgets.add(
      SquareIconButton(
        icon: Icons.share_rounded,
        color: color,
        tooltip: l10n.share,
        onPressed: () => _shareTransaction(context, tx),
      ),
    );
    if (tx.request.curlCommand != null) {
      widgets.addAll([
        const Gap(4),
        SquareIconButton(
          icon: Icons.terminal_rounded,
          color: color,
          tooltip: l10n.copyAsCurl,
          onPressed: () =>
              copyClipboard(context, value: tx.request.curlCommand!),
        ),
      ]);
    }
    if (onOpenRequestDetail != null) {
      widgets.addAll([
        const Gap(4),
        _DetailChip(
          label: l10n.httpRequest,
          color: color,
          onTap: onOpenRequestDetail,
        ),
      ]);
    }
    if ((tx.response != null || tx.error != null) &&
        onOpenResponseDetail != null) {
      widgets.addAll([
        const Gap(4),
        _DetailChip(
          label: l10n.httpResponse,
          color: color,
          onTap: onOpenResponseDetail,
        ),
      ]);
    }
  }
  return widgets;
}

// ---------------------------------------------------------------------------
// Mobile card
// ---------------------------------------------------------------------------

class _MobileTransactionCard extends StatefulWidget {
  const _MobileTransactionCard({
    required this.transaction,
    this.onTap,
    this.onOpenRequestDetail,
    this.onOpenResponseDetail,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;

  @override
  State<_MobileTransactionCard> createState() => _MobileTransactionCardState();
}

class _MobileTransactionCardState extends State<_MobileTransactionCard> {
  bool _expanded = false;

  NetworkTransaction get tx => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final color = _transactionColor(tx);

    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.06);
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final accentColor = color.withValues(alpha: _expanded ? 0.9 : 0.5);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: _expanded ? 5 : 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _expanded = !_expanded);
                  widget.onTap?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _MobileHeader(
                    tx: tx,
                    color: color,
                    expanded: _expanded,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TransactionDetails(tx: tx, color: color),
                            const Gap(8),
                            Row(
                              children: _buildActionWidgets(
                                context: context,
                                tx: tx,
                                color: color,
                                useDesktopStyle: false,
                                onOpenRequestDetail: widget.onOpenRequestDetail,
                                onOpenResponseDetail:
                                    widget.onOpenResponseDetail,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsed header for mobile — badges + chevron only, no action buttons.
class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.tx,
    required this.color,
    required this.expanded,
  });

  final NetworkTransaction tx;
  final Color color;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          DecoratedLeadingIcon(
            icon: Icons.swap_vert_rounded,
            color: color,
          ),
          const Gap(ISpectConstants.standardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MethodBadge(
                      method: tx.method ?? 'HTTP',
                      color: color,
                    ),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        tx.url ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTime(tx.request.time),
                  maxLines: 1,
                  style: TextStyle(
                    color: context.appTheme.textColor.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (tx.statusCode case final code?) ...[
            const Gap(4),
            _StatusBadge(text: '$code', color: color),
          ],
          if (tx.duration case final duration?) ...[
            const Gap(4),
            _StatusBadge(
              text: _formatDuration(duration),
              color: context.appTheme.textColor.withValues(alpha: 0.5),
            ),
          ],
          if (tx.isPending) ...[
            const Gap(4),
            _StatusBadge(
              text: ISpectLocalization.of(context).pending,
              color: const Color(0xFFFF9800),
            ),
          ],
          const Gap(4),
          Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: color.withValues(alpha: 0.5),
          ),
        ],
      );

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Desktop row
// ---------------------------------------------------------------------------

/// Proportionally scale type/time column widths so they never overflow.
({double typeWidth, double timeWidth}) _scaleDesktopColumns({
  required double available,
  required double typeWidth,
  required double timeWidth,
}) {
  final totalColumns = typeWidth + timeWidth;
  if (totalColumns <= 0) return (typeWidth: typeWidth, timeWidth: timeWidth);
  final maxForColumns = available * 0.5;
  if (totalColumns > maxForColumns) {
    final scale = maxForColumns / totalColumns;
    return (typeWidth: typeWidth * scale, timeWidth: timeWidth * scale);
  }
  return (typeWidth: typeWidth, timeWidth: timeWidth);
}

class _DesktopTransactionRow extends StatefulWidget {
  const _DesktopTransactionRow({
    required this.transaction,
    required this.typeColumnWidth,
    required this.timeColumnWidth,
    this.onTap,
    this.onOpenRequestDetail,
    this.onOpenResponseDetail,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final double typeColumnWidth;
  final double timeColumnWidth;

  @override
  State<_DesktopTransactionRow> createState() => _DesktopTransactionRowState();
}

class _DesktopTransactionRowState extends State<_DesktopTransactionRow> {
  bool _isHovered = false;
  bool _expanded = false;

  NetworkTransaction get tx => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final color = _transactionColor(tx);
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.06);
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    final bgColor = _isHovered
        ? onSurface.withValues(alpha: 0.06)
        : color.withValues(alpha: 0.03);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: borderColor),
            left: BorderSide(color: color, width: 2),
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _expanded = !_expanded);
                widget.onTap?.call();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 480;
                    final scaled = _scaleDesktopColumns(
                      available: constraints.maxWidth,
                      typeWidth: isCompact ? 40 : widget.typeColumnWidth,
                      timeWidth: isCompact ? 0 : widget.timeColumnWidth,
                    );
                    return Row(
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 16,
                          color: color,
                        ),
                        const Gap(8),
                        SizedBox(
                          width: scaled.typeWidth,
                          child: Text(
                            'http-transaction',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Gap(8),
                        if (!isCompact) ...[
                          SizedBox(
                            width: scaled.timeWidth,
                            child: Text(
                              tx.request.formattedTime,
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
                        _MethodBadge(
                          method: tx.method ?? 'HTTP',
                          color: color,
                        ),
                        const Gap(6),
                        Expanded(
                          child: Text(
                            tx.url ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (tx.statusCode case final code?) ...[
                          const Gap(8),
                          _DesktopStatusBadge(statusCode: code),
                        ],
                        if (tx.duration case final d?) ...[
                          const Gap(8),
                          _DurationBadge(duration: d),
                        ],
                        if (tx.isPending) ...[
                          const Gap(8),
                          _PendingBadge(
                            label: ISpectLocalization.of(context).pending,
                          ),
                        ],
                        if (_isHovered) ...[
                          const Gap(8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _buildActionWidgets(
                              context: context,
                              tx: tx,
                              color: color,
                              useDesktopStyle: true,
                              onOpenRequestDetail: widget.onOpenRequestDetail,
                              onOpenResponseDetail: widget.onOpenResponseDetail,
                            ),
                          ),
                        ],
                        const Gap(4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.5),
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _TransactionDetails(tx: tx, color: color),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact text chip for opening request/response detail views.
class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: color.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SmallActionIcon extends StatelessWidget {
  const _SmallActionIcon({
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

// ---------------------------------------------------------------------------
// Shared detail content
// ---------------------------------------------------------------------------

class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({required this.tx, required this.color});

  final NetworkTransaction tx;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.iSpect.theme;
    final l10n = ISpectLocalization.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appTheme.textColor.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Response/Error FIRST (most relevant for debugging)
            if (tx.response != null)
              _DetailSection(
                label: l10n.httpResponse,
                icon: Icons.arrow_downward_rounded,
                color: theme.getTypeColor(
                      context,
                      key: ISpectLogType.httpResponse.key,
                    ) ??
                    color,
                message: tx.response!.message ?? '',
              ),
            if (tx.error != null) ...[
              if (tx.response != null) const Gap(6),
              _DetailSection(
                label: l10n.error,
                icon: Icons.error_outline_rounded,
                color: theme.getTypeColor(
                      context,
                      key: ISpectLogType.httpError.key,
                    ) ??
                    color,
                message: tx.error!.message ?? '',
              ),
            ],
            // Request LAST
            if (tx.response != null || tx.error != null) const Gap(6),
            _DetailSection(
              label: l10n.httpRequest,
              icon: Icons.arrow_upward_rounded,
              color: theme.getTypeColor(
                    context,
                    key: ISpectLogType.httpRequest.key,
                  ) ??
                  color,
              message: tx.request.message ?? '',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.label,
    required this.icon,
    required this.color,
    required this.message,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appTheme.textColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method, required this.color});

  final String method;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            method,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

class _DesktopStatusBadge extends StatelessWidget {
  const _DesktopStatusBadge({required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (statusCode) {
      < 300 => (const Color(0xFF4CAF50), const Color(0xFF2E7D32)),
      < 400 => (const Color(0xFFFF9800), const Color(0xFFE65100)),
      _ => (const Color(0xFFF44336), const Color(0xFFC62828)),
    };
    return DecoratedBox(
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
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.appTheme.textColor.withValues(alpha: 0.06),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            _formatDuration(duration),
            style: TextStyle(
              color: context.appTheme.textColor.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE65100),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
