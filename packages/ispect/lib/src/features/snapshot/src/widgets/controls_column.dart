// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/snapshot/src/theme/feedback_theme.dart';
import 'package:ispect/src/features/snapshot/src/utilities/feedback_mode.dart';

/// This is the Widget on the right side of the app when the feedback view
/// is active.
class ControlsColumn extends StatelessWidget {
  // ignore: prefer_const_constructor_declarations
  ControlsColumn({
    required this.mode,
    required this.activeColor,
    required this.onColorChanged,
    required this.onUndo,
    required this.onControlModeChanged,
    required this.onCloseFeedback,
    required this.onClearDrawing,
    required this.colors,
    super.key,
  })  : assert(
          colors.isNotEmpty,
          'There must be at least one color to draw in colors',
        ),
        assert(colors.contains(activeColor), 'colors must contain activeColor');

  final ValueChanged<Color> onColorChanged;
  final VoidCallback onUndo;
  final ValueChanged<FeedbackMode> onControlModeChanged;
  final VoidCallback onCloseFeedback;
  final VoidCallback onClearDrawing;
  final List<Color> colors;
  final Color activeColor;
  final FeedbackMode mode;

  @override
  Widget build(BuildContext context) {
    final isNavigatingActive = FeedbackMode.navigate == mode;
    final isDrawingActive = FeedbackMode.draw == mode;
    return Card(
      elevation: 0,
      color: FeedbackTheme.of(context).cardColor,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('close_controls_column'),
            icon: Icon(
              Icons.close,
              color: FeedbackTheme.of(context).textColor,
            ),
            onPressed: onCloseFeedback,
          ),
          _ColumnDivider(),
          RotatedBox(
            quarterTurns: 1,
            child: MaterialButton(
              key: const ValueKey<String>('navigate_button'),
              onPressed: isNavigatingActive
                  ? null
                  : () => onControlModeChanged(FeedbackMode.navigate),
              disabledTextColor:
                  FeedbackTheme.of(context).activeFeedbackModeColor,
              child: Text(
                context.ispectL10n.navigate,
                style: TextStyle(
                  color: isNavigatingActive
                      ? FeedbackTheme.of(context).activeFeedbackModeColor
                      : isDrawingActive
                          ? Colors.grey
                          : FeedbackTheme.of(context).textColor,
                ),
              ),
            ),
          ),
          _ColumnDivider(),
          RotatedBox(
            quarterTurns: 1,
            child: MaterialButton(
              key: const ValueKey<String>('draw_button'),
              minWidth: 20,
              onPressed: isNavigatingActive
                  ? () => onControlModeChanged(FeedbackMode.draw)
                  : null,
              disabledTextColor:
                  FeedbackTheme.of(context).activeFeedbackModeColor,
              child: Text(
                context.ispectL10n.draw,
                style: TextStyle(
                  color: isNavigatingActive
                      ? Colors.grey
                      : (isDrawingActive
                          ? FeedbackTheme.of(context).activeFeedbackModeColor
                          : FeedbackTheme.of(context).textColor),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>('undo_button'),
            icon: Icon(
              Icons.undo,
              color: isNavigatingActive
                  ? Colors.grey
                  : FeedbackTheme.of(context).textColor,
            ),
            onPressed: isNavigatingActive ? null : onUndo,
          ),
          IconButton(
            key: const ValueKey<String>('clear_button'),
            icon: Icon(
              Icons.delete,
              color: isNavigatingActive
                  ? Colors.grey
                  : FeedbackTheme.of(context).textColor,
            ),
            onPressed: isNavigatingActive ? null : onClearDrawing,
          ),
          for (final color in colors)
            _ColorSelectionIconButton(
              key: ValueKey<Color>(color),
              color: isNavigatingActive ? Colors.grey : color,
              onPressed: isNavigatingActive ? null : onColorChanged,
              isActive: activeColor == color,
            ),
        ],
      ),
    );
  }
}

class _ColorSelectionIconButton extends StatelessWidget {
  const _ColorSelectionIconButton({
    required this.color,
    required this.onPressed,
    required this.isActive,
    super.key,
  });

  final Color color;
  final ValueChanged<Color>? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(isActive ? Icons.lens : Icons.panorama_fish_eye),
        color: color,
        disabledColor: color.withValues(alpha: 0.5),
        onPressed: onPressed == null ? null : () => onPressed!(color),
      );
}

class _ColumnDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 35,
        height: 1,
        color: Theme.of(context).dividerColor,
      );
}
