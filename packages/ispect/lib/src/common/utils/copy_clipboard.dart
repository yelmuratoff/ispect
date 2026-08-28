import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';

/// Copies the given `value` to the clipboard and displays a toast notification.
///
/// This function sets the provided `value` as the clipboard content and then
/// triggers a toast message to notify the user that the text has been copied.
///
/// **Redaction.** Pass `redact: true` for values that may contain sensitive
/// data (HTTP bodies, headers, full log JSON). The string is then run through
/// the resolved [RedactionService]. An explicit [redactionService] takes
/// precedence over [redactKeys], which take precedence over the global policy.
/// When [redact] is `false` (the default) the bounded value is copied verbatim;
/// use this only for safe values (paths, IDs, already-redacted curl strings).
///
/// ### Example:
/// ```dart
/// copyClipboard(
///   context,
///   value: "Hello, World!",
///   title: "Copied!",
///   showValue: false,
/// );
/// ```
///
/// ### Example with redaction:
/// ```dart
/// copyClipboard(
///   context,
///   value: rawJsonBody,
///   redact: true,
/// );
/// ```

void copyClipboard(
  BuildContext? context, {
  required String value,
  String? title,
  bool showValue = true,
  bool redact = false,
  Set<String>? redactKeys,
  RedactionService? redactionService,
  DiagnosticResourceLimits? resourceLimits,
  ISpectGeneratedLocalization? l10n,
  ScaffoldMessengerState? messenger,
}) {
  final limits =
      (resourceLimits ??
            ISpect.loggerIfInitialized?.options.resourceLimits ??
            DiagnosticResourceLimits.balanced)
        ..validate();
  final prepared = LogExportOutput.boundJsonValue(
    value,
    resourceLimits: limits,
    maxBytes: limits.maxClipboardBytes,
    replaceOversizedStrings: redact,
  );
  final boundedInput = prepared is String
      ? prepared
      : LogExportOutput.truncatedMarker;
  final sanitized = redact
      ? _redactClipboardValue(
          boundedInput,
          redactionService: redactionService,
          redactKeys: redactKeys,
          resourceLimits: limits,
        )
      : boundedInput;
  final truncatedValue = LogExportOutput.truncateUtf8(
    sanitized,
    maxBytes: limits.maxClipboardBytes,
    marker: '\n... [truncated]',
  );

  final capturedL10n = l10n ?? context?.ispectL10n;
  final capturedMessenger =
      messenger ??
      (context != null ? ScaffoldMessenger.maybeOf(context) : null);

  unawaited(
    Clipboard.setData(ClipboardData(text: truncatedValue))
        .then((_) {
          ISpectToaster.showCopiedToast(
            null,
            value: truncatedValue,
            title: title,
            showValue: showValue,
            messenger: capturedMessenger,
            l10n: capturedL10n,
          );
        })
        .catchError((Object _) {
          if (capturedMessenger != null) {
            ISpectToaster.showErrorToast(
              null,
              title: 'Failed to copy to clipboard',
              messenger: capturedMessenger,
            );
          }
        }),
  );
}

String _redactClipboardValue(
  String value, {
  required RedactionService? redactionService,
  required Set<String>? redactKeys,
  required DiagnosticResourceLimits resourceLimits,
}) {
  try {
    final redacted = ISpectRedaction.resolveService(
      service: redactionService,
      sensitiveKeys: redactKeys,
    ).redactForExport(value, resourceLimits: resourceLimits);
    return redacted is String ? redacted : defaultPlaceholder;
  } on Object {
    return defaultPlaceholder;
  }
}
