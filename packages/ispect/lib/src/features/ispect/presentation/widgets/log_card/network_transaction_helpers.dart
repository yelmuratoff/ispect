import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/default_curl_redactor.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_log_bottom_sheet.dart';

Color transactionColor(NetworkTransaction tx) {
  if (tx.isError) return const Color(0xFFF44336);
  if (tx.isPending) return const Color(0xFFFF9800);
  final code = tx.statusCode;
  if (code != null && code >= 400) return const Color(0xFFF44336);
  return const Color(0xFF4CAF50);
}

String formatTransactionDuration(Duration duration) {
  if (duration.inMilliseconds < 1000) {
    return '${duration.inMilliseconds}ms';
  }
  return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
}

void shareTransaction(BuildContext context, NetworkTransaction tx) {
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
          if (!context.mounted) return;
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
          if (!context.mounted) return;
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
List<Widget> buildActionWidgets({
  required BuildContext context,
  required NetworkTransaction tx,
  required Color color,
  required bool useDesktopStyle,
  VoidCallback? onOpenRequestDetail,
  VoidCallback? onOpenResponseDetail,
}) {
  final l10n = ISpectLocalization.of(context);
  final widgets = <Widget>[];

  final redactedCurl =
      tx.request.curlCommandWith(redactor: defaultCurlRedactor);
  if (useDesktopStyle) {
    widgets.add(
      SmallActionIcon(
        icon: Icons.share_rounded,
        color: color,
        tooltip: l10n.share,
        onPressed: () => shareTransaction(context, tx),
      ),
    );
    if (redactedCurl != null) {
      widgets.addAll([
        const Gap(4),
        SmallActionIcon(
          icon: Icons.terminal_rounded,
          color: color,
          tooltip: l10n.copyAsCurl,
          onPressed: () => copyClipboard(context, value: redactedCurl),
        ),
      ]);
    }
  } else {
    widgets.add(
      SquareIconButton(
        icon: Icons.share_rounded,
        color: color,
        tooltip: l10n.share,
        onPressed: () => shareTransaction(context, tx),
      ),
    );
    if (redactedCurl != null) {
      widgets.addAll([
        const Gap(4),
        SquareIconButton(
          icon: Icons.terminal_rounded,
          color: color,
          tooltip: l10n.copyAsCurl,
          onPressed: () => copyClipboard(context, value: redactedCurl),
        ),
      ]);
    }
  }

  if (onOpenRequestDetail != null) {
    widgets.addAll([
      const Gap(4),
      DetailChip(
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
      DetailChip(
        label: l10n.httpResponse,
        color: color,
        onTap: onOpenResponseDetail,
      ),
    ]);
  }
  return widgets;
}
