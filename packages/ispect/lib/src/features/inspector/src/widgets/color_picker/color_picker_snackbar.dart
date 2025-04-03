import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';

/// Displays a snackbar with the selected color information and an option to copy the color value.
///
/// This function shows a snackbar that includes a preview of the selected color,
/// its hexadecimal string representation, and a button to copy the color value to the clipboard.
/// The snackbar is styled according to the application's theme.
///
/// - Parameters:
///   - context: The [BuildContext] used to access theme and localization resources.
///   - color: The [Color] to be displayed in the snackbar.
///
/// The snackbar includes:
/// - A small box showing the selected color.
/// - A text displaying the color's hexadecimal value.
/// - A button to copy the color value to the clipboard.
///
/// Example usage:
/// ```dart
/// showColorPickerResultSnackbar(
///   context: context,
///   color: Colors.blue,
/// );
/// ```

void showColorPickerResultSnackbar({
  required BuildContext context,
  required Color color,
}) {
  final colorString = '#${colorToHexString(color)}';
  final iSpect = ISpect.read(context);

  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: context.ispectTheme.cardColor,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(
          color: iSpect.theme.dividerColor(context) ??
              context.ispectTheme.dividerColor,
        ),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: getTextColorOnBackground(color),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(8),
              Text(
                'Color: $colorString',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Gap(8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              copyClipboard(context, value: colorString);
            },
            child: Text(context.ispectL10n.copy),
          ),
        ],
      ),
    ),
  );
}
