// import 'package:feedback_plus/feedback_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:ispect/src/common/utils/ispect_options.dart';
// import 'package:ispect/src/common/widgets/feedback_body.dart';
// import 'package:ispect/src/core/localization/localization.dart';

// /// `ISpectWrapper` is a wrapper for the `ISpect` widget. It used for some specific tools.
// class ISpectWrapper extends StatefulWidget {
//   final Widget child;
//   final ISpectOptions options;

//   const ISpectWrapper({
//     super.key,
//     required this.child,
//     required this.options,
//   });

//   @override
//   State<ISpectWrapper> createState() => _ISpectWrapperState();
// }

// class _ISpectWrapperState extends State<ISpectWrapper> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = widget.options.themeMode == ThemeMode.light ? widget.options.lightTheme : widget.options.darkTheme;
//     return _View(widget: widget, isInspectorEnabled: widget.options.controller.isInspectorEnabled, theme: theme);
//   }
// }

// class _View extends StatelessWidget {
//   const _View({
//     required this.widget,
//     required this.isInspectorEnabled,
//     required this.theme,
//   });

//   final ISpectWrapper widget;
//   final ThemeData theme;
//   final bool isInspectorEnabled;

//   @override
//   Widget build(BuildContext context) {
//     return BetterFeedback(
//       themeMode: widget.options.themeMode,
//       localizationsDelegates: Localization.localizationDelegates,
//       localeOverride: widget.options.locale,
//       theme: FeedbackThemeData(
//         background: Colors.grey[800]!,
//         feedbackSheetColor: widget.options.lightTheme.colorScheme.surface,
//         activeFeedbackModeColor: widget.options.lightTheme.colorScheme.primary,
//         cardColor: widget.options.lightTheme.scaffoldBackgroundColor,
//         bottomSheetDescriptionStyle: widget.options.lightTheme.textTheme.bodyMedium!.copyWith(
//           color: Colors.grey[800],
//         ),
//         dragHandleColor: Colors.grey[400],
//         inactiveColor: Colors.grey[700]!,
//         textColor: Colors.grey[800]!,
//       ),
//       darkTheme: FeedbackThemeData(
//         background: Colors.grey[800]!,
//         feedbackSheetColor: widget.options.darkTheme.colorScheme.surface,
//         activeFeedbackModeColor: widget.options.darkTheme.colorScheme.primary,
//         cardColor: widget.options.darkTheme.scaffoldBackgroundColor,
//         bottomSheetDescriptionStyle: widget.options.lightTheme.textTheme.bodyMedium!.copyWith(
//           color: Colors.grey[300],
//         ),
//         dragHandleColor: Colors.grey[400],
//         inactiveColor: Colors.grey[600]!,
//         textColor: Colors.grey[300]!,
//       ),
//       mode: FeedbackMode.navigate,
//       feedbackBuilder: (context, extras, scrollController) => simpleFeedbackBuilder(
//         context,
//         extras,
//         scrollController,
//         widget.options.themeMode == ThemeMode.light ? widget.options.lightTheme : widget.options.darkTheme,
//       ),
//       child: widget.child,
//     );
//   }
// }
