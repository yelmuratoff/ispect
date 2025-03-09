import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';

/// Copies the given [value] to the clipboard and displays a toast notification.
///
/// This function sets the provided [value] as the clipboard content and then
/// triggers a toast message to notify the user that the text has been copied.
///
/// ### Parameters:
/// - [context]: The `BuildContext` required for showing the toast notification.
/// - [value]: The text to be copied to the clipboard (required).
/// - [title]: (Optional) A title for the toast notification.
/// - [showValue]: Determines whether to display the copied value in the toast.
///   - Defaults to `true`.
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
/// ### Behavior:
/// - The function first copies [value] to the system clipboard.
/// - Then, it calls `ISpectToaster.showCopiedToast` to display a notification.
///
/// **Note:** Ensure that `ISpectToaster` is properly initialized to avoid issues
/// when displaying the toast message.
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
