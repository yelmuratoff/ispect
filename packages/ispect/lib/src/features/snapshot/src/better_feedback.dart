// ignore_for_file: comment_references

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/feedback_plus.dart';
import 'package:ispect/src/features/snapshot/src/controllers/feedback_data.dart';
import 'package:ispect/src/features/snapshot/src/controllers/screenshot.dart';
import 'package:ispect/src/features/snapshot/src/controllers/screenshot_data.dart';
import 'package:ispect/src/features/snapshot/src/feedback_widget.dart';
import 'package:ispect/src/features/snapshot/src/theme/feedback_theme.dart';
import 'package:ispect/src/features/snapshot/src/utilities/feedback_app.dart';
import 'package:ispect/src/features/snapshot/src/utilities/renderer/renderer.dart';

/// The function to be called when the user submits his feedback.
typedef OnSubmit = Future<void> Function(
  String feedback, {
  Map<String, dynamic>? extras,
});

/// A function that returns a Widget that prompts the user for feedback and
/// calls [OnSubmit] when the user wants to submit their feedback.
///
/// A non-null controller is provided if the sheet is set to draggable in the
/// feedback theme.
/// If the sheet is draggable, the non null controller should be passed into a
/// scrollable widget to make the feedback sheet expand when the widget is
/// scrolled. Typically, this will be a `ListView` or `SingleChildScrollView`
/// wrapping the feedback sheet's content.
/// See: [FeedbackThemeData.sheetIsDraggable] and [DraggableScrollableSheet].
typedef FeedbackBuilder = Widget Function(
  BuildContext context,
  OnSubmit onSubmit,
  ScrollController? controller,
);

/// A drag handle to be placed at the top of a draggable feedback sheet.
///
/// This is a purely visual element that communicates to users that the sheet
/// can be dragged to expand it.
///
/// It should be placed in a stack over the sheet's scrollable element so that
/// users can click and drag on it-the drag handle ignores pointers so the drag
/// will pass through to the scrollable beneath.
//   builder function once `DraggableScrollableController` is available in
//   production.
//   See: https://github.com/flutter/flutter/pull/92440.
class FeedbackSheetDragHandle extends StatelessWidget {
  /// Create a drag handle.
  const FeedbackSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final feedbackTheme = FeedbackTheme.of(context);
    return IgnorePointer(
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        alignment: Alignment.center,
        color: feedbackTheme.feedbackSheetColor,
        child: Container(
          height: 5,
          width: 30,
          decoration: BoxDecoration(
            color: feedbackTheme.dragHandleColor,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
        ),
      ),
    );
  }
}

/// Function which gets called when the user submits his feedback.
/// [feedback] is the user generated feedback. A string, by default.
/// [screenshot] is a raw png encoded image.
/// [OnFeedbackCallback] should cast [feedback] to the appropriate type.
typedef OnFeedbackCallback = FutureOr<void> Function(UserFeedback feedback);

/// A feedback widget that uses a custom widget and data type for
/// prompting the user for their feedback. This widget should be the root of
/// your widget tree. Specifically, it should be above any [Navigator] widgets,
/// including the navigator provided by [MaterialApp].
///
/// For example like this
/// ```dart
/// BetterFeedback(
///   child: MaterialApp(
///   title: 'App',
///   home: MyHomePage(),
/// );
/// ```
///
class BetterFeedback extends StatefulWidget {
  /// Creates a [BetterFeedback].
  ///
  /// /// ```dart
  /// BetterFeedback(
  ///   child: MaterialApp(
  ///   title: 'App',
  ///   home: MyHomePage(),
  /// );
  /// ```
  const BetterFeedback({
    required this.child,
    required this.feedbackBuilder,
    super.key,
    this.themeMode,
    this.theme,
    this.darkTheme,
    this.localizationsDelegates,
    this.localeOverride,
    this.mode = FeedbackMode.draw,
    this.pixelRatio = 3.0,
  }) : assert(
          pixelRatio > 0,
          'pixelRatio needs to be larger than 0',
        );

  /// The application to wrap, typically a [MaterialApp].
  final Widget child;

  /// Returns a widget that prompts the user for feedback and calls the provided
  /// submit function with their completed feedback. Typically, this involves
  /// some form fields and a submit button that calls [OnSubmit] when pressed.
  /// Defaults to [StringFeedback] which uses a single editable text field to
  /// prompt for input.
  final FeedbackBuilder feedbackBuilder;

  /// Determines which theme will be used by the Feedback UI.
  /// If set to [ThemeMode.system], the choice of which theme to use will be based
  /// on the user's system preferences (using the [MediaQuery.platformBrightnessOf]).
  /// If set to [ThemeMode.light] the [theme] will be used, regardless of the user's
  /// system preference.  If [theme] isn't provided [FeedbackThemeData] will
  /// be used.
  /// If set to [ThemeMode.dark] the [darkTheme] will be used regardless of the
  /// user's system preference. If [darkTheme] isn't provided, will fallback to
  /// [theme]. If both [darkTheme] and [theme] aren't provided
  /// [FeedbackThemeData.dark] will be used.
  /// The default value is [ThemeMode.system].
  final ThemeMode? themeMode;

  /// The Theme, which gets used to style the feedback ui if the [themeMode] is
  /// ThemeMode.light or user's system preference is light.
  final FeedbackThemeData? theme;

  /// The theme, which gets used to style the feedback ui if the [themeMode] is
  /// ThemeMode.dark or user's system preference is dark.
  final FeedbackThemeData? darkTheme;

  /// The delegates for this library's FeedbackLocalization widget.
  /// You need to supply the following delegates if you choose to customize it.
  /// [MaterialLocalizations]
  /// [CupertinoLocalizations]
  /// [WidgetsLocalizations]
  /// an instance of [LocalizationsDelegate]<[FeedbackLocalizations]>
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Can be used to set the locale.
  /// If it is not set, the platform default locale is used.
  /// If no platform default locale exists, english is used.
  final Locale? localeOverride;

  /// Set the default mode when launching feedback.
  /// By default it will allow the user to navigate.
  /// See [FeedbackMode] for other options.
  final FeedbackMode mode;

  /// The pixelRatio describes the scale between
  /// the logical pixels and the size of the output image.
  /// Specifying 1.0 will give you a 1:1 mapping between
  /// logical pixels and the output pixels in the image.
  /// The default is a pixel ration of 3 and a value below 1 is not recommended.
  ///
  /// See [RenderRepaintBoundary](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
  /// for information on the underlying implementation.
  final double pixelRatio;

  /// Call `BetterFeedback.of(context)` to get an
  /// instance of [FeedbackData] on which you can call `.show()` or `.hide()`
  /// to enable or disable the feedback view.
  ///
  /// For example:
  /// ```dart
  /// BetterFeedback.of(context).show(...);
  /// BetterFeedback.of(context).hide(...);
  /// ```
  static FeedbackController of(BuildContext context) {
    final feedbackData =
        context.dependOnInheritedWidgetOfExactType<FeedbackData>();
    assert(
      feedbackData != null,
      'You need to add a $BetterFeedback widget above this context!',
    );
    return feedbackData!.controller;
  }

  static ScreenshotController ofScreenshot(BuildContext context) {
    final screenshotData =
        context.dependOnInheritedWidgetOfExactType<ScreenShotData>();
    assert(
      screenshotData != null,
      'You need to add a $BetterFeedback widget above this context!',
    );
    return screenshotData!.controller;
  }

  @override
  State<BetterFeedback> createState() => _BetterFeedbackState();
}

class _BetterFeedbackState extends State<BetterFeedback> {
  final FeedbackController _controller = FeedbackController();
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    printRendererErrorMessageIfNecessary();
    _controller.addListener(_onUpdateOfController);
  }

  @override
  void dispose() {
    _controller.dispose();

    // ignore: cascade_invocations
    _controller.removeListener(_onUpdateOfController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeedbackApp(
        themeMode: widget.themeMode,
        theme: widget.theme,
        darkTheme: widget.darkTheme,
        localizationsDelegates: widget.localizationsDelegates,
        localeOverride: widget.localeOverride,
        child: Builder(
          builder: (_) => ScreenShotData(
            controller: _screenshotController,
            child: FeedbackData(
              controller: _controller,
              child: Builder(
                builder: (context) => FeedbackWidget(
                  screenshotController: _screenshotController,
                  isFeedbackVisible: _controller.isVisible,
                  drawColors: FeedbackTheme.of(context).drawColors,
                  mode: widget.mode,
                  pixelRatio: widget.pixelRatio,
                  feedbackBuilder: widget.feedbackBuilder,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      );

  void _onUpdateOfController() {
    // ignore: avoid_empty_blocks
    setState(() {});
  }
}
