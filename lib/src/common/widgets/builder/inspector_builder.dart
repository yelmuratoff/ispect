import 'package:feedback_plus/feedback_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/widgets/feedback_body.dart';
import 'package:ispect/src/core/localization/localization.dart';
import 'package:ispect/src/features/inspector/inspector.dart';

import 'performance_overlay_builder.dart';

class ISpectWrapper extends StatelessWidget {
  final ISpectOptions options;

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? child;

  const ISpectWrapper({
    super.key,
    required this.options,
    required this.child,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = options.themeMode == ThemeMode.light ? options.lightTheme : options.darkTheme;
    return AnimatedBuilder(
      animation: options.controller,
      builder: (BuildContext context, Widget? child) {
        /// Add inspector to the widget tree
        child = Inspector(
          isPanelVisible: options.controller.isInspectorEnabled,
          backgroundColor: adjustColorBrightness(theme.colorScheme.primaryContainer, 0.6),
          selectedColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onBackground,
          selectedTextColor: theme.colorScheme.onBackground,
          child: child ?? const SizedBox(),
        );

        /// Add draggable button to the widget tree
        child = DraggableButton(
          navigatorKey: navigatorKey,
          options: options,
          child: child,
        );

        /// Add performance overlay to the widget tree
        child = PerformanceOverlayBuilder(
          isPerformanceTrackingEnabled: options.controller.isPerformanceTrackingEnabled,
          theme: theme,
          child: child,
        );

        /// Add feedback button to the widget tree
        child = BetterFeedback(
          themeMode: options.themeMode,
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          localeOverride: options.locale,
          theme: FeedbackThemeData(
            background: Colors.grey[800]!,
            feedbackSheetColor: options.lightTheme.colorScheme.surface,
            activeFeedbackModeColor: options.lightTheme.colorScheme.primary,
            cardColor: options.lightTheme.scaffoldBackgroundColor,
            bottomSheetDescriptionStyle: options.lightTheme.textTheme.bodyMedium!.copyWith(
              color: Colors.grey[800],
            ),
            dragHandleColor: Colors.grey[400],
            inactiveColor: Colors.grey[700]!,
            textColor: Colors.grey[800]!,
          ),
          darkTheme: FeedbackThemeData(
            background: Colors.grey[800]!,
            feedbackSheetColor: options.darkTheme.colorScheme.surface,
            activeFeedbackModeColor: options.darkTheme.colorScheme.primary,
            cardColor: options.darkTheme.scaffoldBackgroundColor,
            bottomSheetDescriptionStyle: options.lightTheme.textTheme.bodyMedium!.copyWith(
              color: Colors.grey[300],
            ),
            dragHandleColor: Colors.grey[400],
            inactiveColor: Colors.grey[600]!,
            textColor: Colors.grey[300]!,
          ),
          mode: FeedbackMode.navigate,
          feedbackBuilder: (context, extras, scrollController) => simpleFeedbackBuilder(
            context,
            extras,
            scrollController,
            theme,
          ),
          child: child,
        );

        return child;
      },
      child: child,
    );
  }
}
