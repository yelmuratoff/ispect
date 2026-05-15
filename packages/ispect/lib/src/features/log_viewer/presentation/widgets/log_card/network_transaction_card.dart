import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_details.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';

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
    this.searchMatchState = SearchMatchState.none,
    super.key,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final SearchMatchState searchMatchState;

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
        searchMatchState: searchMatchState,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: _MobileTransactionCard(
        transaction: transaction,
        onTap: onTap,
        onOpenRequestDetail: onOpenRequestDetail,
        onOpenResponseDetail: onOpenResponseDetail,
        searchMatchState: searchMatchState,
      ),
    );
  }
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
    this.searchMatchState = SearchMatchState.none,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final SearchMatchState searchMatchState;

  @override
  State<_MobileTransactionCard> createState() => _MobileTransactionCardState();
}

class _MobileTransactionCardState extends State<_MobileTransactionCard> {
  bool _expanded = false;

  NetworkTransaction get tx => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final color = transactionColor(tx);

    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final accentColor = color.withValues(alpha: _expanded ? 0.9 : 0.5);
    final primaryColor = context.appTheme.colorScheme.primary;
    final isFocused = widget.searchMatchState == SearchMatchState.focused;
    final isMatch = widget.searchMatchState == SearchMatchState.match;

    final Color effectiveBg;
    final Color effectiveBorder;
    final double borderWidth;
    final List<BoxShadow>? boxShadow;

    if (isFocused) {
      effectiveBg = primaryColor.withValues(alpha: 0.12);
      effectiveBorder = primaryColor;
      borderWidth = 2;
      boxShadow = [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.25),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (isMatch) {
      effectiveBg = primaryColor.withValues(alpha: 0.06);
      effectiveBorder = primaryColor.withValues(alpha: 0.5);
      borderWidth = 1.5;
      boxShadow = null;
    } else {
      effectiveBg = cardColor;
      effectiveBorder =
          context.appTheme.colorScheme.onSurface.withValues(alpha: 0.06);
      borderWidth = 1;
      boxShadow = null;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: boxShadow,
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
              Semantics(
                button: true,
                expanded: _expanded,
                label:
                    '${tx.method ?? "HTTP"} ${tx.url ?? ""} — ${tx.statusCode ?? "pending"}',
                onTap: () {
                  setState(() => _expanded = !_expanded);
                  widget.onTap?.call();
                },
                child: GestureDetector(
                  excludeFromSemantics: true,
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
                            TransactionDetails(tx: tx, color: color),
                            const Gap(8),
                            Row(
                              children: buildActionWidgets(
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
                    MethodBadge(
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
            StatusBadge(text: '$code', color: color),
          ],
          if (tx.duration case final duration?) ...[
            const Gap(4),
            StatusBadge(
              text: formatTransactionDuration(duration),
              color: context.appTheme.textColor.withValues(alpha: 0.5),
            ),
          ],
          if (tx.isPending) ...[
            const Gap(4),
            StatusBadge(
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
    this.searchMatchState = SearchMatchState.none,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final SearchMatchState searchMatchState;

  @override
  State<_DesktopTransactionRow> createState() => _DesktopTransactionRowState();
}

class _DesktopTransactionRowState extends State<_DesktopTransactionRow> {
  bool _isHovered = false;
  bool _expanded = false;

  NetworkTransaction get tx => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final color = transactionColor(tx);
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.06);
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    final primaryColor = context.appTheme.colorScheme.primary;
    final isFocused = widget.searchMatchState == SearchMatchState.focused;
    final isMatch = widget.searchMatchState == SearchMatchState.match;

    final Color bgColor;
    if (isFocused) {
      bgColor = primaryColor.withValues(alpha: 0.16);
    } else if (isMatch) {
      bgColor = primaryColor.withValues(alpha: 0.08);
    } else if (_isHovered) {
      bgColor = onSurface.withValues(alpha: 0.06);
    } else {
      bgColor = color.withValues(alpha: 0.03);
    }

    final Color leftBorderColor;
    if (isFocused) {
      leftBorderColor = primaryColor;
    } else if (isMatch) {
      leftBorderColor = primaryColor.withValues(alpha: 0.6);
    } else {
      leftBorderColor = color;
    }
    final leftBorderWidth = isFocused ? 3.0 : 2.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: borderColor),
            left: BorderSide(color: leftBorderColor, width: leftBorderWidth),
          ),
        ),
        child: Column(
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              label:
                  '${tx.method ?? "HTTP"} ${tx.url ?? ""} — ${tx.statusCode ?? "pending"}',
              onTap: () {
                setState(() => _expanded = !_expanded);
                widget.onTap?.call();
              },
              child: GestureDetector(
                excludeFromSemantics: true,
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
                          MethodBadge(
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
                            DesktopStatusBadge(statusCode: code),
                          ],
                          if (tx.duration case final d?) ...[
                            const Gap(8),
                            DurationBadge(duration: d),
                          ],
                          if (tx.isPending) ...[
                            const Gap(8),
                            PendingBadge(
                              label: ISpectLocalization.of(context).pending,
                            ),
                          ],
                          if (_isHovered) ...[
                            const Gap(8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: buildActionWidgets(
                                context: context,
                                tx: tx,
                                color: color,
                                useDesktopStyle: true,
                                onOpenRequestDetail: widget.onOpenRequestDetail,
                                onOpenResponseDetail:
                                    widget.onOpenResponseDetail,
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
                        child: TransactionDetails(tx: tx, color: color),
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
