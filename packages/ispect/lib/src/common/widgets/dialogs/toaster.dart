import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// A utility class for displaying various types of toast notifications using `SnackBar`.
///
/// Provides methods to show different types of toasts such as:
/// - **Loading Toast**
/// - **Error Toast**
/// - **Info Toast**
/// - **Success Toast**
/// - **Copied Toast** (for clipboard notifications)
///
/// Each toast is designed with a specific color scheme and layout to maintain consistency.
final class ISpectToaster {
  const ISpectToaster._();

  /// Hides the currently displayed toast notification (if any).
  ///
  /// This method removes the active `SnackBar` from the `ScaffoldMessenger`.
  static Future<void> hideToast(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Displays a loading toast with an animated circular progress indicator.
  ///
  /// - `context`: The `BuildContext` used to show the toast.
  /// - `title`: The title text displayed in the toast.
  ///
  /// The toast includes a **spinning progress indicator** next to the title.
  ///
  /// ### Example:
  /// ```dart
  /// ISpectToaster.showLoadingToast(context, title: "Loading...");
  /// ```
  static Future<void> showLoadingToast(
    BuildContext context, {
    required String title,
  }) =>
      _showToast(
        context,
        title: title,
        icon: const Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Gap(12),
          ],
        ),
        color: const Color.fromARGB(255, 49, 49, 49),
      );

  /// Displays an error toast with a red background.
  ///
  /// - `context`: The `BuildContext` used to show the toast.
  /// - `title`: The title of the error message.
  /// - `message`: (Optional) Additional details about the error.
  ///
  /// ### Example:
  /// ```dart
  /// ISpectToaster.showErrorToast(context, title: "Something went wrong");
  /// ```
  static Future<void> showErrorToast(
    BuildContext context, {
    required String title,
    String? message,
  }) =>
      _showToast(
        context,
        title: title,
        message: message,
        color: Colors.red,
      );

  /// Displays an informational toast with a dark background.
  ///
  /// - `context`: The `BuildContext` used to show the toast.
  /// - `title`: The title of the message.
  /// - `message`: (Optional) Additional details.
  ///
  /// ### Example:
  /// ```dart
  /// ISpectToaster.showInfoToast(context, title: "Update available");
  /// ```
  static Future<void> showInfoToast(
    BuildContext context, {
    required String title,
    String? message,
  }) =>
      _showToast(
        context,
        title: title,
        message: message,
        color: const Color.fromARGB(255, 49, 49, 49),
      );

  /// Displays a success toast with a green background.
  ///
  /// - `context`: The `BuildContext` used to show the toast.
  /// - `title`: The title of the success message.
  /// - `message`: (Optional) Additional details.
  /// - `trailing`: (Optional) A trailing widget (e.g., an icon or button).
  ///
  /// ### Example:
  /// ```dart
  /// ISpectToaster.showSuccessToast(context, title: "Upload completed");
  /// ```
  static Future<void> showSuccessToast(
    BuildContext context, {
    required String title,
    String? message,
    Widget? trailing,
  }) =>
      _showToast(
        context,
        title: title,
        message: message,
        color: Colors.green,
        trailing: trailing,
      );

  /// Displays a toast indicating that a value has been copied to the clipboard.
  ///
  /// - `context`: The `BuildContext` used to show the toast.
  /// - `value`: The copied text.
  /// - `title`: (Optional) A custom title for the toast.
  /// - `showValue`: Determines whether the copied text should be displayed.
  ///
  /// ### Example:
  /// ```dart
  /// ISpectToaster.showCopiedToast(context, value: "Copied text");
  /// ```
  static Future<void> showCopiedToast(
    BuildContext context, {
    required String value,
    String? title,
    bool showValue = true,
  }) =>
      _showCopiedToast(
        context,
        value: value,
        title: title,
        showValue: showValue,
      );

  /// A private helper method to display a custom toast message.
  static Future<void> _showToast(
    BuildContext context, {
    required String title,
    required Color color,
    String? message,
    Widget? icon,
    Widget? trailing,
  }) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        elevation: 0,
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(12),
            Row(
              children: [
                if (icon != null) icon,
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            if (message != null)
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  /// A private helper method to display a "copied to clipboard" toast.
  static Future<void> _showCopiedToast(
    BuildContext context, {
    required String value,
    required bool showValue,
    String? title,
  }) async {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    final copiedText = title ?? '✅ ${context.ispectL10n.logItemCopied}';

    const titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    const valueStyle = TextStyle(
      color: Colors.grey,
    );

    final textSpans = <TextSpan>[
      TextSpan(text: copiedText, style: titleStyle),
      if (showValue) TextSpan(text: '\n\n"$value"', style: valueStyle),
    ];

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color.fromARGB(255, 49, 49, 49),
        elevation: 0,
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(children: textSpans),
              maxLines: 30,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
