import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/column_widths.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_details.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';

/// Desktop variant of [NetworkTransactionCard] — table-row layout with
/// inline expandable details and hover-only action buttons.
class NetworkTransactionDesktopRow extends StatefulWidget {
  const NetworkTransactionDesktopRow({
    required this.transaction,
    required this.typeColumnWidth,
    required this.timeColumnWidth,
    this.onTap,
    this.onOpenRequestDetail,
    this.onOpenResponseDetail,
    this.searchMatchState = SearchMatchState.none,
    this.compactUrl = true,
    super.key,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final SearchMatchState searchMatchState;
  final bool compactUrl;

  @override
  State<NetworkTransactionDesktopRow> createState() =>
      _NetworkTransactionDesktopRowState();
}

class _NetworkTransactionDesktopRowState
    extends State<NetworkTransactionDesktopRow> {
  bool _isHovered = false;
  bool _expanded = false;

  NetworkTransaction get tx => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final color = transactionColor(tx);
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = context.ispectFaintBorderColor;
    final cardColor = context.ispectRowCardColor;

    final primaryColor = context.ispectPrimaryColor;
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
                      final width = constraints.maxWidth;
                      final canShowHoverActions =
                          width >= kHoverActionsMinWidth;
                      final isCompact = width < kDesktopLogCompactBreakpoint;
                      final compactDetailChips =
                          width < kFullChipLabelsMinWidth;
                      final scaled = scaleColumnWidths(
                        available: width,
                        typeWidth: isCompact
                            ? kCompactTypeColumnWidth
                            : widget.typeColumnWidth,
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
                              transactionListUrl(
                                tx.url,
                                compact: widget.compactUrl,
                              ),
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
                          if (_isHovered && canShowHoverActions) ...[
                            const Gap(8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: buildActionWidgets(
                                context: context,
                                tx: tx,
                                color: color,
                                useDesktopStyle: true,
                                compactDetailChips: compactDetailChips,
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
              duration: ISpectMotion.short,
              curve: ISpectMotion.standardCurve,
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
