import 'package:flutter/material.dart';

const _defaultDrawColors = [
  Colors.red,
  Colors.green,
  Color.fromRGBO(33, 150, 243, 1),
  Colors.yellow,
];

/// This is the same as `Colors.grey`50``
/// or the default value of ThemeData.canvasColor for light theme
const _lightGrey = Color(0xFFFAFAFA);

/// This is the same as `Colors.grey`850`,
/// or default value of ThemeData.canvasColor for dark theme
const _darkGrey = Color(0xFF303030);

/// This is the same as `Colors.blue`
/// or the default value of ThemeData.accentColor
const _blue = Color(0xFF2196F3);

const _defaultBottomSheetDescriptionStyle = TextStyle(
  color: Colors.black,
);

const _defaultBottomSheetTextInputStyle = TextStyle(
  color: Colors.black,
);

/// See the following image to get a better understanding of the properties.
/// !`Theme`(https://raw.githubusercontent.com/ueman/feedback/master/img/theme_description.png "Theme")
class FeedbackThemeData {
  /// Creates a `FeedbackThemeData`.
  /// !`Theme`(https://raw.githubusercontent.com/ueman/feedback/master/img/theme_description.png "Theme")
  FeedbackThemeData({
    this.background = Colors.grey,
    this.feedbackSheetColor = _lightGrey,
    this.feedbackSheetHeight = .25,
    this.activeFeedbackModeColor = _blue,
    this.cardColor = _lightGrey,
    this.inactiveColor = Colors.grey,
    this.textColor = Colors.black,
    this.drawColors = _defaultDrawColors,
    this.bottomSheetDescriptionStyle = _defaultBottomSheetDescriptionStyle,
    this.bottomSheetTextInputStyle = _defaultBottomSheetTextInputStyle,
    this.sheetIsDraggable = true,
    Color? dragHandleColor,
  })  :
        // if the user chooses to supply custom drawing colors,
        // make sure there is at least on color to draw with
        assert(
          // ignore: prefer_is_empty
          drawColors.length > 0,
          'There must be at least one color to draw with',
        ),
        brightness = ThemeData.estimateBrightnessForColor(feedbackSheetColor) {
    final isDark = brightness == Brightness.dark;
    this.dragHandleColor =
        dragHandleColor ?? (isDark ? Colors.black26 : Colors.white38);
  }

  /// Create a dark version of the `FeedbackThemeData`
  factory FeedbackThemeData.dark({bool sheetIsDraggable = true}) =>
      FeedbackThemeData(
        background: Colors.grey.shade700,
        dragHandleColor: Colors.white38,
        feedbackSheetColor: _darkGrey,
        bottomSheetDescriptionStyle: const TextStyle(
          color: Colors.white,
        ),
        sheetIsDraggable: sheetIsDraggable,
      );

  /// Create a light version of the `FeedbackThemeData`
  factory FeedbackThemeData.light({bool sheetIsDraggable = true}) =>
      FeedbackThemeData(
        dragHandleColor: Colors.black26,
        sheetIsDraggable: sheetIsDraggable,
      );

  /// Brightness of the theme based on the `background` color
  final Brightness brightness;

  /// The background of the feedback view.
  final Color background;

  /// The background color of the bottom sheet in which the user can input
  /// his feedback and thoughts.
  final Color feedbackSheetColor;

  /// The height of the bottom sheet as a fraction of the screen height.
  ///
  /// Values between .2 and .3 are usually ideal.
  final double feedbackSheetHeight;

  /// The color to highlight the currently selected feedback mode.
  final Color activeFeedbackModeColor;

  /// Colors which can be used to draw while in feedback mode.
  final List<Color> drawColors;

  /// Text Style of the text above of the feedback text input.
  final TextStyle bottomSheetDescriptionStyle;

  /// Text Style of the text input.
  final TextStyle bottomSheetTextInputStyle;

  /// Whether or not the bottom sheet is draggable.
  ///
  /// If this is set to true, the user feedback form will be wrapped in a
  /// `DraggableScrollableSheet` that will expand when the user drags upward on
  /// it. This is useful for large feedback forms.
  final bool sheetIsDraggable;

  /// Color of the drag handle on the feedback sheet
  late final Color dragHandleColor;

  /// `ThemeData` on the feedback UI
  late final ThemeData themeData;

  /// The color of the card in the feedback view.
  final Color cardColor;

  /// The color of the text in the feedback view.
  final Color textColor;

  /// The color of the inactive elements in the feedback view.
  final Color inactiveColor;
}

/// Provides an instance of `FeedbackThemeData` for all descendants.
class FeedbackTheme extends InheritedTheme {
  /// Creates a feedback theme that controls the color, opacity, and size of
  /// descendant widgets.
  ///
  /// Both `data` and [child] arguments must not be null.
  const FeedbackTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// This `FeedbackThemeData` can be obtained by calling
  /// `FeedbackTheme.of(context)`.
  final FeedbackThemeData data;

  /// The data from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// FeedbackThemeData theme = FeedbackTheme.of(context);
  /// ```
  static FeedbackThemeData of(BuildContext context) {
    final feedbackThemeData =
        context.dependOnInheritedWidgetOfExactType<FeedbackTheme>();
    return feedbackThemeData?.data ?? FeedbackThemeData();
  }

  @override
  bool updateShouldNotify(FeedbackTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    final theme = context.findAncestorWidgetOfExactType<FeedbackTheme>();
    return identical(this, theme)
        ? child
        : FeedbackTheme(data: data, child: child);
  }
}
