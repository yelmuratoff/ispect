import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_search_highlight_surface.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_desktop_row.dart';
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

  /// Strips the scheme and host from the collapsed-row URL, leaving the path
  /// and query. The expanded details keep the full URL.
  final bool compactUrl;

  @override
  Widget build(BuildContext context) {
    if (context.screenSize.isDesktop) {
      return NetworkTransactionDesktopRow(
        transaction: transaction,
        onTap: onTap,
        onOpenRequestDetail: onOpenRequestDetail,
        onOpenResponseDetail: onOpenResponseDetail,
        typeColumnWidth: typeColumnWidth,
        timeColumnWidth: timeColumnWidth,
        searchMatchState: searchMatchState,
        compactUrl: compactUrl,
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
        compactUrl: compactUrl,
      ),
    );
  }
}

class _MobileTransactionCard extends StatefulWidget {
  const _MobileTransactionCard({
    required this.transaction,
    this.onTap,
    this.onOpenRequestDetail,
    this.onOpenResponseDetail,
    this.searchMatchState = SearchMatchState.none,
    this.compactUrl = true,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final SearchMatchState searchMatchState;
  final bool compactUrl;

  @override
  State<_MobileTransactionCard> createState() => _MobileTransactionCardState();
}

class _MobileTransactionCardState extends State<_MobileTransactionCard> {
  bool _expanded = false;

  NetworkTransaction get tx => widget.transaction;

  @override
  Widget build(BuildContext context) {
    final color = transactionColor(tx);
    final accentColor = color.withValues(alpha: _expanded ? 0.9 : 0.7);

    return ISpectSearchHighlightSurface(
      searchMatchState: widget.searchMatchState,
      child: AnimatedContainer(
        duration: ISpectMotion.short,
        curve: ISpectMotion.standardCurve,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: _expanded ? 5 : 3),
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
                    compactUrl: widget.compactUrl,
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: ISpectMotion.short,
              curve: ISpectMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (transactionHasInlineDetails(tx)) ...[
                            TransactionDetails(tx: tx, color: color),
                            const Gap(8),
                          ],
                          Row(
                            children: buildActionWidgets(
                              context: context,
                              tx: tx,
                              color: color,
                              useDesktopStyle: false,
                              onOpenRequestDetail: widget.onOpenRequestDetail,
                              onOpenResponseDetail: widget.onOpenResponseDetail,
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
    );
  }
}

/// Collapsed header for mobile — badges + chevron only, no action buttons.
class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.tx,
    required this.color,
    required this.expanded,
    required this.compactUrl,
  });

  final NetworkTransaction tx;
  final Color color;
  final bool expanded;
  final bool compactUrl;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MethodBadge(
                      method: tx.method ?? 'HTTP',
                      color: color,
                    ),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        transactionListUrl(tx.url, compact: compactUrl),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              context.appTheme.textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
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
                    color: context.appTheme.textColor.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
