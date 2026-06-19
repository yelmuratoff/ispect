import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';

class TransactionDetails extends StatelessWidget {
  const TransactionDetails({
    required this.tx,
    required this.color,
    super.key,
  });

  final NetworkTransaction tx;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ISpect.read(context).theme;
    final l10n = ISpectLocalization.of(context);
    final statusSummary = transactionStatusSummary(tx);
    final requestSummary = transactionRequestSummary(tx);

    // Response/Error first (most relevant for debugging), request last. Rows
    // with nothing to add beyond the header are dropped so a body-less request
    // doesn't expand into empty labels.
    final sections = <Widget>[
      if (tx.response != null && statusSummary.isNotEmpty)
        _DetailSection(
          label: l10n.httpResponse,
          icon: Icons.arrow_downward_rounded,
          color: theme.getTypeColor(
                context,
                key: ISpectLogType.httpResponse.key,
              ) ??
              color,
          meta: statusSummary,
        ),
      if (tx.error != null)
        _DetailSection(
          label: l10n.error,
          icon: Icons.error_outline_rounded,
          color: theme.getTypeColor(
                context,
                key: ISpectLogType.httpError.key,
              ) ??
              color,
          meta: statusSummary,
          // Transport errors carry no HTTP status, so fall back to the
          // error message to keep some inline detail.
          message: tx.statusCode == null ? tx.error!.message ?? '' : '',
        ),
      if (requestSummary.isNotEmpty)
        _DetailSection(
          label: l10n.httpRequest,
          icon: Icons.arrow_upward_rounded,
          color: theme.getTypeColor(
                context,
                key: ISpectLogType.httpRequest.key,
              ) ??
              color,
          meta: requestSummary,
        ),
    ];

    if (sections.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appTheme.textColor.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(
          Radius.circular(ISpectConstants.standardBorderRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const Gap(6),
              sections[i],
            ],
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
    this.meta = '',
    this.message = '',
  });

  final String label;
  final IconData icon;
  final Color color;

  /// Status / size summary shown next to the label; hidden when empty.
  final String meta;

  /// Optional detail line below the label; hidden when empty.
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
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const Gap(6),
                      Flexible(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appTheme.textColor
                                .withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appTheme.textColor.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}
