import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';

import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';

void showColorPickerResultSnackbar({
  required BuildContext context,
  required Color color,
}) {
  final colorString = '#${colorToHexString(color)}';
  final iSpect = ISpect.read(context);

  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(context).cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(
          color: iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
              context.ispectTheme.dividerColor,
        ),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              border: Border.fromBorderSide(
                BorderSide(
                  color:
                      iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
                          context.ispectTheme.dividerColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Color: $colorString',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      action: SnackBarAction(
        label: context.ispectL10n.copy,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: colorString));
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
