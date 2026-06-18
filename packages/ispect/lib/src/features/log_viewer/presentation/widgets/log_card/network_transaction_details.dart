import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
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
    final requestSummary = transactionRequestSummary(tx);
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
                meta: transactionStatusSummary(tx),
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
                meta: transactionStatusSummary(tx),
                // Transport errors carry no HTTP status, so fall back to the
                // error message to keep some inline detail.
                message: tx.statusCode == null ? tx.error!.message ?? '' : '',
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
              meta: requestSummary.isEmpty ? l10n.noData : requestSummary,
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
                                .withValues(alpha: 0.5),
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
                      color: context.appTheme.textColor.withValues(alpha: 0.6),
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
