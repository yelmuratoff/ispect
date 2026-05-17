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
/// [RedactionService.redactExportString] using [redactKeys] — URL credentials,
/// `Bearer`/`Basic`/`Token` prefixes, query params and JSON fields whose keys
/// match any of [redactKeys] are replaced with `***`. When [redact] is `false`
/// (the default) the value is copied verbatim; use this only for safe values
/// (paths, IDs, already-redacted curl strings).
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

const int _maxClipboardLength = 100000;

void copyClipboard(
  BuildContext? context, {
  required String value,
  String? title,
  bool showValue = true,
  bool redact = false,
  Set<String>? redactKeys,
  ISpectGeneratedLocalization? l10n,
  ScaffoldMessengerState? messenger,
}) {
  final sanitized = redact
      ? RedactionService.redactExportString(
          value,
          redactKeys ?? defaultSensitiveKeys,
        )
      : value;

  final String truncatedValue;
  if (sanitized.length > _maxClipboardLength) {
    // Avoid splitting a surrogate pair at the truncation boundary.
    var end = _maxClipboardLength;
    if (end > 0 &&
        sanitized.codeUnitAt(end - 1) >= 0xD800 &&
        sanitized.codeUnitAt(end - 1) <= 0xDBFF) {
      end--;
    }
    truncatedValue = '${sanitized.substring(0, end)}\n... [truncated]';
  } else {
    truncatedValue = sanitized;
  }

  final capturedL10n = l10n ?? context?.ispectL10n;
  final capturedMessenger = messenger ??
      (context != null ? ScaffoldMessenger.maybeOf(context) : null);

  unawaited(
    Clipboard.setData(ClipboardData(text: truncatedValue)).then((_) {
      ISpectToaster.showCopiedToast(
        null,
        value: truncatedValue,
        title: title,
        showValue: showValue,
        messenger: capturedMessenger,
        l10n: capturedL10n,
      );
    }).catchError((Object _) {
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
