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
  final truncatedValue = value.length > _maxClipboardLength
      ? '${value.substring(0, _maxClipboardLength)}\n... [truncated]'
      : value;

  Clipboard.setData(ClipboardData(text: truncatedValue));

  ISpectToaster.showCopiedToast(
    context,
    value: truncatedValue,
    title: title,
    showValue: showValue,
  );
}
