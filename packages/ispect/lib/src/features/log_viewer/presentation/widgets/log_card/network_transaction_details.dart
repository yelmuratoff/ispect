import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

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
