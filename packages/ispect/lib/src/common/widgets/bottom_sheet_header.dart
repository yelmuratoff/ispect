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
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.textColor,
          ),
        ),
        IconButton(
          onPressed: onClose ?? () => Navigator.pop(context),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: theme.textColor),
        ),
      ],
    );
  }
}
