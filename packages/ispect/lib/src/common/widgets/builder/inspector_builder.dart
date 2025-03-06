import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/widgets/builder/performance_overlay_builder.dart';
import 'package:ispect/src/common/widgets/feedback_body.dart';
import 'package:ispect/src/features/inspector/inspector.dart';
import 'package:ispect/src/features/snapshot/feedback_plus.dart';

class ISpectBuilder extends StatefulWidget {
  const ISpectBuilder({
    required this.child,
    required this.isISpectEnabled,
    this.options,
    this.theme,
    this.initialPosition,
    this.observer,
    this.feedbackTheme,
    this.feedBackDarkTheme,
    this.feedbackBuilder,
    this.onPositionChanged,
    this.controller,
    super.key,
  });

  final Widget child;
  final ISpectOptions? options;
  final ISpectTheme? theme;
  final bool isISpectEnabled;
  final NavigatorObserver? observer;
  final FeedbackThemeData? feedbackTheme;
  final FeedbackThemeData? feedBackDarkTheme;
  final Widget Function(
    BuildContext context,
    Future<void> Function(String text, {Map<String, dynamic>? extras}) onSubmit,
    ScrollController? controller,
  )? feedbackBuilder;
  final void Function(double x, double y)? onPositionChanged;

  final ({double x, double y})? initialPosition;

  final DraggablePanelController? controller;

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
      ..options = widget.options ?? model.options
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
            options: model.options,
            observer: widget.observer,
            isPanelVisible: model.isISpectEnabled,
            backgroundColor: adjustColorBrightness(
              theme.colorScheme.primaryContainer,
              0.6,
            ),
            selectedColor: theme.colorScheme.primaryContainer,
            textColor: theme.colorScheme.onSurface,
            selectedTextColor: theme.colorScheme.onSurface,
            onPositionChanged: widget.onPositionChanged,
            controller: widget.controller,
            child: currentChild,
          );

          // Add performance overlay to the widget tree.
          currentChild = PerformanceOverlayBuilder(
            isPerformanceTrackingEnabled: model.isPerformanceTrackingEnabled,
            theme: theme,
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
            child: Navigator(
              observers: [ISpectNavigatorObserver()],
              pages: [MaterialPage(child: currentChild)],
              onDidRemovePage: (_) {},
            ),
          );
        },
      );
}
