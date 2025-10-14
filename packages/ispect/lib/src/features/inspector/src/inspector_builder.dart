import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/widgets/builder/feedback_builder.dart';
import 'package:ispect/src/core/res/ispect_callbacks.dart';
import 'package:ispect/src/features/inspector/inspector.dart';
import 'package:ispect/src/features/performance/src/builder.dart';
import 'package:ispect/src/features/snapshot/feedback_plus.dart';

/// A widget that wraps your app with ISpect debugging tools.
///
/// **⚠️ WARNING: Never include in production builds - contains sensitive debug data.**
///
/// This widget adds debugging capabilities around your main app widget:
/// - Inspector panel for UI debugging
/// - Performance monitoring overlay
/// - Feedback system for bug reporting
/// - Navigation tracking
///
/// ## Safe Usage
///
/// ```dart
/// const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT');
///
/// MaterialApp(
///   builder: (context, child) {
///     if (kEnableISpect) {
///       return ISpectBuilder(child: child);
///     }
///     return child;
///   },
///   home: MyApp(),
/// )
/// ```
///
/// Build commands:
/// ```bash
/// # Development
/// flutter run --dart-define=ENABLE_ISPECT=true
///
/// # Production (ISpect removed)
/// flutter build apk
/// ```
class ISpectBuilder extends StatefulWidget {
  /// Creates an ISpectBuilder that wraps [child] with debugging tools.
  ///
  /// Set [isISpectEnabled] to false in production for security.
  const ISpectBuilder({
    required this.child,
    this.isISpectEnabled = kDebugMode,
    this.options,
    this.theme,
    this.feedbackTheme,
    this.feedBackDarkTheme,
    this.feedbackBuilder,
    this.controller,
    this.onShare,
    this.onOpenFile,
    this.deviceInfoProvider,
    this.packageInfoProvider,
    super.key,
  });

  /// Your main app widget.
  final Widget child;

  /// ISpect configuration options.
  final ISpectOptions? options;

  /// Custom theme for ISpect interface.
  final ISpectTheme? theme;

  /// Whether debugging tools are enabled. Set to false in production.
  final bool isISpectEnabled;

  /// Light theme for feedback widget.
  final FeedbackThemeData? feedbackTheme;

  /// Dark theme for feedback widget.
  final FeedbackThemeData? feedBackDarkTheme;

  /// Custom feedback widget builder.
  final Widget Function(
    BuildContext context,
    Future<void> Function(String text, {Map<String, dynamic>? extras}) onSubmit,
    ScrollController? controller,
  )? feedbackBuilder;

  /// Controller for the draggable debug panel.
  final DraggablePanelController? controller;

  /// Custom handler invoked when ISpect needs to share content.
  final ISpectShareCallback? onShare;

  /// Custom handler invoked when ISpect needs to open a file path.
  final ISpectOpenFileCallback? onOpenFile;

  /// Custom provider for device info displayed in the App Info screen.
  final ISpectInfoProvider? deviceInfoProvider;

  /// Custom provider for package info displayed in the App Info screen.
  final ISpectInfoProvider? packageInfoProvider;

  @override
  State<ISpectBuilder> createState() => _ISpectBuilderState();
}

class _ISpectBuilderState extends State<ISpectBuilder> {
  late ISpectScopeModel model;

  @override
  void initState() {
    super.initState();
    model = ISpectScopeModel();

    model
      ..isISpectEnabled = widget.isISpectEnabled
      ..options = (widget.options ?? model.options).copyWith(
        onShare: widget.onShare ?? widget.options?.onShare,
        onOpenFile: widget.onOpenFile ?? widget.options?.onOpenFile,
        deviceInfoProvider:
            widget.deviceInfoProvider ?? widget.options?.deviceInfoProvider,
        packageInfoProvider:
            widget.packageInfoProvider ?? widget.options?.packageInfoProvider,
      )
      ..theme = widget.theme ?? model.theme;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final theme = Theme.of(context);

          // Build the widget tree with the necessary layers.
          var currentChild = widget.child;

          // Add inspector to the widget tree.
          currentChild = Inspector(
            isPanelVisible: model.isISpectEnabled,
            backgroundColor: adjustColorBrightness(
              theme.colorScheme.primaryContainer,
              0.6,
            ),
            selectedColor: theme.colorScheme.primaryContainer,
            textColor: theme.colorScheme.onSurface,
            selectedTextColor: theme.colorScheme.onSurface,
            controller: widget.controller,
            child: currentChild,
          );

          // Add performance overlay to the widget tree.
          currentChild = ISpectPerformanceOverlayBuilder(
            isPerformanceTrackingEnabled: model.isPerformanceTrackingEnabled,
            child: currentChild,
          );

          // Add feedback button to the widget tree.
          currentChild = BetterFeedback(
            themeMode: context.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: ISpectLocalization.localizationDelegates,
            localeOverride: model.options.locale,
            theme: widget.feedbackTheme ??
                FeedbackThemeData(
                  background: Colors.grey[800]!,
                  feedbackSheetColor: context.ispectTheme.colorScheme.surface,
                  activeFeedbackModeColor:
                      context.ispectTheme.colorScheme.primary,
                  cardColor: context.ispectTheme.scaffoldBackgroundColor,
                  bottomSheetDescriptionStyle:
                      context.ispectTheme.textTheme.bodyMedium!.copyWith(
                    color: Colors.grey[800],
                  ),
                  dragHandleColor: Colors.grey[400],
                  inactiveColor: Colors.grey[700]!,
                  textColor: Colors.grey[800]!,
                ),
            darkTheme: widget.feedBackDarkTheme ??
                FeedbackThemeData(
                  background: Colors.grey[800]!,
                  feedbackSheetColor: context.ispectTheme.colorScheme.surface,
                  activeFeedbackModeColor:
                      context.ispectTheme.colorScheme.primary,
                  cardColor: context.ispectTheme.scaffoldBackgroundColor,
                  bottomSheetDescriptionStyle:
                      context.ispectTheme.textTheme.bodyMedium!.copyWith(
                    color: Colors.grey[300],
                  ),
                  dragHandleColor: Colors.grey[400],
                  inactiveColor: Colors.grey[600]!,
                  textColor: Colors.grey[300]!,
                ),
            mode: FeedbackMode.navigate,
            feedbackBuilder: widget.feedbackBuilder ??
                (_, onSubmit, scrollController) => SimpleFeedbackBuilder(
                      onSubmit: onSubmit,
                      scrollController: scrollController,
                      theme: theme,
                    ),
            child: currentChild,
          );

          return ISpectScopeController(
            model: model,
            child: widget.options?.observer != null
                ? currentChild
                : Navigator(
                    observers: [
                      ISpectNavigatorObserver(),
                    ],
                    pages: [MaterialPage(child: currentChild)],
                    onDidRemovePage: (page) {},
                  ),
          );
        },
      );
}
