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
void copyClipboard(
  BuildContext context, {
  required String value,
  String? title,
  bool showValue = true,
}) {
  // Copy the text to the clipboard.
  Clipboard.setData(ClipboardData(text: value));

  // Show a toast notification indicating the copy action.
  ISpectToaster.showCopiedToast(
    context,
    value: value,
    title: title,
    showValue: showValue,
  );
}
