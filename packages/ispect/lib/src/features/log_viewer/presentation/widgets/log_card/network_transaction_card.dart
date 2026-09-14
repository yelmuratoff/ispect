import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_search_highlight_surface.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_context_menu.dart';
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
    this.useRelativeTime = false,
    super.key,
  });

  final NetworkTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final SearchMatchState searchMatchState;
  final bool useRelativeTime;

  /// Strips the scheme and host from the collapsed-row URL, leaving the path
  /// and query. The expanded details keep the full URL.
  final bool compactUrl;

  @override
  Widget build(BuildContext context) {
    void openMenu() => showLogContextMenu(
      context: context,
      position: Offset.zero,
      data: transaction.request,
      onShareTap: () => shareTransaction(context, transaction),
      onOpenDetail: onOpenResponseDetail ?? onOpenRequestDetail,
    );

    if (context.screenSize.isDesktop) {
      return NetworkTransactionDesktopRow(
        transaction: transaction,
        onTap: onTap,
        onLongPress: openMenu,
        onOpenRequestDetail: onOpenRequestDetail,
        onOpenResponseDetail: onOpenResponseDetail,
        typeColumnWidth: typeColumnWidth,
        timeColumnWidth: timeColumnWidth,
        searchMatchState: searchMatchState,
        compactUrl: compactUrl,
        useRelativeTime: useRelativeTime,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: _MobileTransactionCard(
        transaction: transaction,
        onTap: onTap,
        onLongPress: openMenu,
        onOpenRequestDetail: onOpenRequestDetail,
        onOpenResponseDetail: onOpenResponseDetail,
        searchMatchState: searchMatchState,
        compactUrl: compactUrl,
        useRelativeTime: useRelativeTime,
      ),
    );
  }
}

class _MobileTransactionCard extends StatefulWidget {
  const _MobileTransactionCard({
    required this.transaction,
    required this.onLongPress,
    this.onTap,
    this.onOpenRequestDetail,
    this.onOpenResponseDetail,
    this.searchMatchState = SearchMatchState.none,
    this.compactUrl = true,
    this.useRelativeTime = false,
  });

  final NetworkTransaction transaction;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onOpenRequestDetail;
  final VoidCallback? onOpenResponseDetail;
  final SearchMatchState searchMatchState;
  final bool compactUrl;
  final bool useRelativeTime;

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
    final displayUrl = transactionDisplayUrl(tx);

    void toggleExpanded() {
      setState(() => _expanded = !_expanded);
    }

    final openDetail =
        widget.onOpenResponseDetail ?? widget.onOpenRequestDetail;

    void handleTap() {
      widget.onTap?.call();
      (openDetail ?? toggleExpanded)();
    }

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
              container: true,
              explicitChildNodes: true,
              button: true,
              expanded: openDetail == null ? _expanded : null,
              label:
                  '${tx.method ?? "HTTP"} $displayUrl - ${tx.statusCode ?? "pending"}',
              onTap: handleTap,
              onLongPress: widget.onLongPress,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  excludeFromSemantics: true,
                  onTap: handleTap,
                  onLongPress: widget.onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _MobileHeader(
                      tx: tx,
                      color: color,
                      expanded: _expanded,
                      compactUrl: widget.compactUrl,
                      displayUrl: displayUrl,
                      useRelativeTime: widget.useRelativeTime,
                      onToggleExpanded: toggleExpanded,
                    ),
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

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.tx,
    required this.color,
    required this.expanded,
    required this.compactUrl,
    required this.displayUrl,
    required this.useRelativeTime,
    required this.onToggleExpanded,
  });

  final NetworkTransaction tx;
  final Color color;
  final bool expanded;
  final bool compactUrl;
  final String displayUrl;
  final bool useRelativeTime;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final stackMetadata = MediaQuery.textScalerOf(context).scale(12) > 18;
    final badges = <Widget>[
      if (tx.statusCode case final code?)
        StatusBadge(text: '$code', color: color),
      if (tx.duration case final duration?)
        StatusBadge(
          text: formatTransactionDuration(duration),
          color: context.appTheme.textColor.withValues(alpha: 0.5),
        ),
      if (tx.isPending)
        StatusBadge(
          text: ISpectLocalization.of(context).pending,
          color: JsonColors.statusWarning,
        ),
    ];
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MethodBadge(method: tx.method ?? 'HTTP', color: color),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        transactionListUrl(displayUrl, compact: compactUrl),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appTheme.textColor.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  context.formatLogTime(
                    tx.request.time,
                    relative: useRelativeTime,
                    absolute: _formatTime(tx.request.time),
                  ),
                  maxLines: 1,
                  style: TextStyle(
                    color: context.appTheme.textColor.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (stackMetadata && badges.isNotEmpty) ...[
                  const Gap(4),
                  Wrap(spacing: 4, runSpacing: 4, children: badges),
                ],
              ],
            ),
          ),
        ),
        if (!stackMetadata)
          for (final badge in badges) ...[const Gap(4), badge],
        Semantics(
          expanded: expanded,
          child: SquareIconButton(
            icon: expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: color,
            tooltip: expanded
                ? context.ispectL10n.collapseLogs
                : context.ispectL10n.expandLogs,
            onPressed: onToggleExpanded,
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
