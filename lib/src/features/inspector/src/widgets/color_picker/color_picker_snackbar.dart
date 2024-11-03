import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';

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
