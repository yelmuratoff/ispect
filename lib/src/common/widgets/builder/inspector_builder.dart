import 'package:feedback_plus/feedback_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/widgets/feedback_body.dart';
import 'package:ispect/src/features/inspector/inspector.dart';
import 'package:provider/provider.dart';

import 'performance_overlay_builder.dart';

class ISpectWrapper extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? child;

  const ISpectWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    final isISpectEnabled = Provider.of<ISpectScopeModel>(context).isISpectEnabled;
    final isPerformanceTrackingEnabled = Provider.of<ISpectScopeModel>(context).isPerformanceTrackingEnabled;
    final options = Provider.of<ISpectScopeModel>(context).options;
    final theme = Theme.of(context);
    return Consumer<ISpectScopeModel>(
      builder: (
        BuildContext context,
        ISpectScopeModel model,
        Widget? child,
      ) {
        /// Add inspector to the widget tree
        child = Inspector(
          options: options,
          navigatorKey: navigatorKey,
          isPanelVisible: isISpectEnabled,
          backgroundColor: adjustColorBrightness(theme.colorScheme.primaryContainer, 0.6),
          selectedColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onBackground,
          selectedTextColor: theme.colorScheme.onBackground,
          child: child ?? const SizedBox(),
        );

        /// Add performance overlay to the widget tree
        child = PerformanceOverlayBuilder(
          isPerformanceTrackingEnabled: isPerformanceTrackingEnabled,
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

  static ISpectScopeModel provideOnce(BuildContext context) {
    return Provider.of<ISpectScopeModel>(context, listen: false);
  }
}
