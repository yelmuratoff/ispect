import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_payload_preview.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';

class TransactionDetails extends StatelessWidget {
  const TransactionDetails({required this.tx, required this.color, super.key});

  final NetworkTransaction tx;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ISpect.read(context).theme;
    final l10n = ISpectLocalization.of(context);
    final statusSummary = transactionStatusSummary(tx);
    final requestSummary = transactionRequestSummary(tx);
    final requestLog = captureISpectLogDataForEgress(tx.request);
    final responseLog = tx.response ?? tx.error;
    final capturedResponseLog = responseLog == null
        ? null
        : captureISpectLogDataForEgress(responseLog);
    final requestPayload = NetworkLogRenderer.requestPayload(tx.request);
    final responsePayload = responseLog == null
        ? null
        : NetworkLogRenderer.responsePayload(responseLog);
    final showResponse =
        tx.response != null &&
        (statusSummary.isNotEmpty || (responsePayload?.hasPreview ?? false));
    final showError = tx.error != null;
    final showRequest =
        (requestPayload?.hasPreview ?? false) ||
        (requestSummary.isNotEmpty && (showResponse || showError));

    // The request row only joins a response/error row — alone it just repeats
    // the request content type, so a plain successful call shows no panel.
    final sections = <Widget>[
      if (showResponse)
        _DetailSection(
          label: l10n.httpResponse,
          icon: Icons.arrow_downward_rounded,
          color:
              theme.getTypeColor(
                context,
                key: ISpectLogType.httpResponse.key,
              ) ??
              color,
          meta: statusSummary,
          payload: responsePayload,
          maxStringLength:
              capturedResponseLog!.resourceLimits.maxUiDiagnosticBytes,
        ),
      if (showError)
        _DetailSection(
          label: l10n.error,
          icon: Icons.error_outline_rounded,
          color:
              theme.getTypeColor(context, key: ISpectLogType.httpError.key) ??
              color,
          meta: statusSummary,
          // Transport errors carry no HTTP status, so fall back to the
          // error message to keep some inline detail.
          message: tx.statusCode == null ? tx.error!.message ?? '' : '',
          payload: responsePayload,
          maxStringLength:
              capturedResponseLog!.resourceLimits.maxUiDiagnosticBytes,
        ),
      if (showRequest)
        _DetailSection(
          label: l10n.httpRequest,
          icon: Icons.arrow_upward_rounded,
          color:
              theme.getTypeColor(context, key: ISpectLogType.httpRequest.key) ??
              color,
          meta: requestSummary,
          payload: requestPayload,
          maxStringLength: requestLog.resourceLimits.maxUiDiagnosticBytes,
        ),
    ];

    if (sections.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: context.appTheme.textColor.withValues(alpha: 0.03),
        radius: ISpectConstants.standardBorderRadius,
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
    this.payload,
    this.maxStringLength = 0,
  });

  final String label;
  final IconData icon;
  final Color color;

  /// Status / size summary shown next to the label; hidden when empty.
  final String meta;

  /// Optional detail line below the label; hidden when empty.
  final String message;
  final NetworkLogPayload? payload;
  final int maxStringLength;

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
                        color: context.appTheme.textColor.withValues(
                          alpha: 0.65,
                        ),
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
            if (payload?.hasPreview ?? false) ...[
              const Gap(6),
              NetworkPayloadPreview(
                payload: payload!,
                color: color,
                maxStringLength: maxStringLength,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
