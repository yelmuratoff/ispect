import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/src/common/extensions/context.dart';

import 'utils.dart';

void showColorPickerResultSnackbar({
  required BuildContext context,
  required Color color,
}) {
  final colorString = '#${colorToHexString(color)}';

  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(context).cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1.0,
        ),
      ),
      content: Row(
        children: [
          Container(
            width: 16.0,
            height: 16.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
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
