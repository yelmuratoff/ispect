import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/default_curl_redactor.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/share_sheet.dart';
import 'package:ispect/src/features/http_composer/controllers/http_composer_controller.dart';
import 'package:ispect/src/features/http_composer/presentation/screens/http_composer_screen.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_log_bottom_sheet.dart';

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

/// Canonical HTTP reason phrases whose code already implies success. Showing
/// them next to the green status badge in the header adds no information.
const _canonicalSuccessReasons = <int, String>{
  200: 'OK',
  201: 'Created',
  202: 'Accepted',
  203: 'Non-Authoritative Information',
  204: 'No Content',
  205: 'Reset Content',
  206: 'Partial Content',
};

bool _isRedundantReason(int? code, String reason) {
  if (code == null) return false;
  final canonical = _canonicalSuccessReasons[code];
  return canonical != null &&
      canonical.toLowerCase() == reason.trim().toLowerCase();
}

/// Status / size summary for a transaction's response or error section,
/// e.g. `1.2 KB` or `Not Found · 84 B`. Empty when nothing notable is reported.
///
/// The status code and duration are intentionally omitted — both already show
/// in the header. The reason phrase is dropped when it is the canonical phrase
/// for a successful code (`200 OK`, `201 Created`, …) since it only restates
/// the badge; non-standard and error reasons are kept because they carry
/// detail the code alone does not.
String transactionStatusSummary(NetworkTransaction tx) {
  final parts = <String>[];
  final code = tx.statusCode;
  if (tx.statusMessage case final reason?) {
    if (!_isRedundantReason(code, reason)) parts.add(reason);
  } else if (code != null) {
    parts.add('$code');
  }
  if (tx.responseContentLength case final size?) {
    parts.add(formatBytes(size));
  }
  return parts.join(' · ');
}

/// Content type / size summary for a transaction's request section,
/// e.g. `application/json · 532 B`. Empty when nothing is reported.
String transactionRequestSummary(NetworkTransaction tx) {
  final parts = <String>[];
  if (tx.requestContentType case final type?) parts.add(type);
  if (tx.requestContentLength case final size?) parts.add(formatBytes(size));
  return parts.join(' · ');
}

/// Whether the expanded card has any inline detail worth a panel — a response
/// or request summary, or an error. A body-less request collapses to just the
/// action buttons instead of empty `Response`/`Request` rows.
bool transactionHasInlineDetails(NetworkTransaction tx) =>
    (tx.response != null && transactionStatusSummary(tx).isNotEmpty) ||
    tx.error != null ||
    transactionRequestSummary(tx).isNotEmpty;

/// URL to render in a collapsed transaction row.
///
/// With [compact] true, strips the scheme and authority (host:port) so a
/// shared base like `https://api.example.com` drops out, leaving the path and
/// query that identify the endpoint. Returns [url] unchanged when it is empty,
/// relative (no authority), unparseable, or has no path.
String transactionListUrl(String? url, {required bool compact}) {
  if (url == null || url.isEmpty) return '';
  if (!compact) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority || uri.path.isEmpty) return url;
  return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
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
  bool compactDetailChips = false,
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

  final canEditResend = ISpect.senders.isNotEmpty &&
      HttpComposerController.seedFromLog(tx.request) != null;
  if (canEditResend) {
    void openComposer() => HttpComposerScreen.openFromLog(context, tx.request);
    widgets.addAll([
      const Gap(4),
      if (useDesktopStyle)
        SmallActionIcon(
          icon: Icons.api_rounded,
          color: color,
          tooltip: l10n.composerEditAndResend,
          onPressed: openComposer,
        )
      else
        SquareIconButton(
          icon: Icons.api_rounded,
          color: color,
          tooltip: l10n.composerEditAndResend,
          onPressed: openComposer,
        ),
    ]);
  }

  if (onOpenRequestDetail != null) {
    widgets.addAll([
      const Gap(4),
      DetailChip(
        label: l10n.httpRequest,
        color: color,
        icon: compactDetailChips
            ? Icons.arrow_upward_rounded
            : Icons.open_in_new_rounded,
        iconOnly: compactDetailChips,
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
        icon: compactDetailChips
            ? Icons.arrow_downward_rounded
            : Icons.open_in_new_rounded,
        iconOnly: compactDetailChips,
        onTap: onOpenResponseDetail,
      ),
    ]);
  }
  return widgets;
}
