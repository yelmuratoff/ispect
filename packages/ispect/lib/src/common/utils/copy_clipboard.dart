import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';

/// Copies the given `value` to the clipboard and displays a toast notification.
///
/// This function sets the provided `value` as the clipboard content and then
/// triggers a toast message to notify the user that the text has been copied.
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

const int _maxClipboardLength = 100000;

void copyClipboard(
  BuildContext context, {
  required String value,
  String? title,
  bool showValue = true,
}) {
  final String truncatedValue;
  if (value.length > _maxClipboardLength) {
    // Avoid splitting a surrogate pair at the truncation boundary.
    var end = _maxClipboardLength;
    if (end > 0 &&
        value.codeUnitAt(end - 1) >= 0xD800 &&
        value.codeUnitAt(end - 1) <= 0xDBFF) {
      end--;
    }
    truncatedValue = '${value.substring(0, end)}\n... [truncated]';
  } else {
    truncatedValue = value;
  }

  unawaited(
    Clipboard.setData(ClipboardData(text: truncatedValue)).then((_) {
      if (!context.mounted) return;
      ISpectToaster.showCopiedToast(
        context,
        value: truncatedValue,
        title: title,
        showValue: showValue,
      );
    }).catchError((Object _) {
      if (!context.mounted) return;
      ISpectToaster.showErrorToast(
        context,
        title: 'Failed to copy to clipboard',
      );
    }),
  );
}
