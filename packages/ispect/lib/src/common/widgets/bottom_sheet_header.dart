import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

/// Reusable header widget for bottom sheets with title and close button.
///
/// Provides consistent styling across all ISpect bottom sheets.
class ISpectBottomSheetHeader extends StatelessWidget {
  const ISpectBottomSheetHeader({
    required this.title,
    this.onClose,
    super.key,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.appTheme.textTheme.headlineSmall?.copyWith(
              color: context.appTheme.textColor,
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, color: context.appTheme.textColor),
          ),
        ],
      );
}
