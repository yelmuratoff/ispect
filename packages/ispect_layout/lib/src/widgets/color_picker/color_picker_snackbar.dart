import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_scheme_inspector.dart';
import 'utils.dart';

/// Shows a snackbar confirming the picked colour with a Copy action and,
/// when [showColorSchemeMatch] is true, a subtle line listing matching
/// `ColorScheme` tokens (e.g. `colorScheme.primary`) — surfaced here rather
/// than in the live picker overlay so it doesn't reflow during pixel hunting.
void showColorPickerResultSnackbar({
  required BuildContext context,
  required Color color,
  bool showColorSchemeMatch = false,
}) {
  final colorString = colorToDisplayHex(color);
  final tokens = showColorSchemeMatch
      ? ColorSchemeInspector.matchingTokens(
          color,
          Theme.of(context).colorScheme,
        )
      : const <String>[];

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      duration: tokens.isEmpty
          ? const Duration(seconds: 4)
          : const Duration(seconds: 6),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(width: 8.0),
              Text('Color: $colorString'),
            ],
          ),
          if (tokens.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tokens.length == 1
                  ? 'Matches colorScheme.${tokens.first}'
                  : 'Matches ${tokens.map((t) => 'colorScheme.$t').join(', ')}',
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ],
        ],
      ),
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: colorString));
          HapticFeedback.lightImpact();
          messenger.hideCurrentSnackBar();
        },
      ),
    ),
  );
}
