import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';

final class ISpectToaster {
  static Future<void> hideToast(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

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
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showCopiedToast(
    BuildContext context, {
    required String value,
    required bool showValue,
    String? title,
  }) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
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
            //   ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title ?? '✅ ${context.ispectL10n.logItemCopied}: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showValue)
                    TextSpan(
                      text: '\n\n"$value"',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
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
