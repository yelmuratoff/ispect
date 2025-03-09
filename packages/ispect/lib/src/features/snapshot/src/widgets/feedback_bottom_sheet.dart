// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/src/better_feedback.dart';
import 'package:ispect/src/features/snapshot/src/theme/feedback_theme.dart';
import 'package:ispect/src/features/snapshot/src/utilities/back_button_interceptor.dart';

/// Shows the text input in which the user can describe his feedback.
class FeedbackBottomSheet extends StatelessWidget {
  const FeedbackBottomSheet({
    required this.feedbackBuilder,
    required this.onSubmit,
    required this.sheetProgress,
    super.key,
  });

  final FeedbackBuilder feedbackBuilder;
  final OnSubmit onSubmit;
  final ValueNotifier<double> sheetProgress;

  @override
  Widget build(BuildContext context) {
    if (FeedbackTheme.of(context).sheetIsDraggable) {
      return DraggableScrollableActuator(
        child: _DraggableFeedbackSheet(
          feedbackBuilder: feedbackBuilder,
          onSubmit: onSubmit,
          sheetProgress: sheetProgress,
        ),
      );
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height *
            FeedbackTheme.of(context).feedbackSheetHeight,
        child: Material(
          color: FeedbackTheme.of(context).feedbackSheetColor,
          // Pass a null scroll controller because the sheet is not drag
          // enabled.
          child: feedbackBuilder(context, onSubmit, null),
        ),
      ),
    );
  }
}

class _DraggableFeedbackSheet extends StatefulWidget {
  const _DraggableFeedbackSheet({
    required this.feedbackBuilder,
    required this.onSubmit,
    required this.sheetProgress,
  });

  final FeedbackBuilder feedbackBuilder;
  final OnSubmit onSubmit;
  final ValueNotifier<double> sheetProgress;

  @override
  State<_DraggableFeedbackSheet> createState() =>
      _DraggableFeedbackSheetState();
}

class _DraggableFeedbackSheetState extends State<_DraggableFeedbackSheet> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(_onBackButton, priority: 0);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_onBackButton);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackTheme = FeedbackTheme.of(context);

    // We need to recalculate the collapsed height to account for the safe area
    // at the top and the keyboard (if present).
    final collapsedHeight = feedbackTheme.feedbackSheetHeight *
        MediaQuery.sizeOf(context).height /
        (MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).top -
            MediaQuery.viewInsetsOf(context).bottom);
    return Column(
      children: [
        ValueListenableBuilder<void>(
          valueListenable: widget.sheetProgress,
          child: Container(
            height: MediaQuery.paddingOf(context).top,
            color: FeedbackTheme.of(context).feedbackSheetColor,
          ),
          builder: (_, __, child) => Opacity(
            // Use the curved progress value
            opacity: widget.sheetProgress.value,
            child: child,
          ),
        ),
        Expanded(
          child: DraggableScrollableSheet(
            controller: BetterFeedback.of(context).sheetController,
            snap: true,
            minChildSize: collapsedHeight,
            initialChildSize: collapsedHeight,
            builder: (context, scrollController) =>
                ValueListenableBuilder<void>(
              valueListenable: widget.sheetProgress,
              builder: (_, __, child) => ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20 * (1 - widget.sheetProgress.value)),
                ),
                child: child,
              ),
              child: Material(
                color: FeedbackTheme.of(context).feedbackSheetColor,
                // A `ListView` makes the content here disappear.
                child: DefaultTextEditingShortcuts(
                  child: widget.feedbackBuilder(
                    context,
                    widget.onSubmit,
                    scrollController,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _onBackButton() {
    if (widget.sheetProgress.value != 0) {
      if (DraggableScrollableActuator.reset(context)) {
        widget.sheetProgress.value = 0;
        return true;
      }
    }
    return false;
  }
}
