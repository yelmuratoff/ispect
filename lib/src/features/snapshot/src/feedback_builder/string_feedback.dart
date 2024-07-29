import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/src/better_feedback.dart';
import 'package:ispect/src/features/snapshot/src/l18n/translation.dart';
import 'package:ispect/src/features/snapshot/src/theme/feedback_theme.dart';

/// A form that prompts the user for feedback with a single text field.
/// This is the default feedback widget used by [BetterFeedback].
class StringFeedback extends StatefulWidget {
  /// Create a [StringFeedback].
  /// This is the default feedback bottom sheet, which is presented to the user.
  const StringFeedback({
    required this.onSubmit,
    required this.scrollController,
    super.key,
  });

  /// Should be called when the user taps the submit button.
  final OnSubmit onSubmit;

  /// A scroll controller that expands the sheet when it's attached to a
  /// scrollable widget and that widget is scrolled.
  ///
  /// Non null if the sheet is draggable.
  /// See: [FeedbackThemeData.sheetIsDraggable].
  final ScrollController? scrollController;

  @override
  State<StringFeedback> createState() => _StringFeedbackState();
}

class _StringFeedbackState extends State<StringFeedback> {
  late TextEditingController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView(
                  controller: widget.scrollController,
                  // Pad the top by 20 to match the corner radius if drag enabled.
                  padding: EdgeInsets.only(left: 16, top: widget.scrollController != null ? 20 : 16, right: 16),
                  children: <Widget>[
                    Text(
                      FeedbackLocalizations.of(context).feedbackDescriptionText,
                      maxLines: 2,
                      style: FeedbackTheme.of(context).bottomSheetDescriptionStyle,
                    ),
                    TextField(
                      style: FeedbackTheme.of(context).bottomSheetTextInputStyle,
                      key: const Key('text_input_field'),
                      maxLines: 2,
                      minLines: 2,
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
                if (widget.scrollController != null) const FeedbackSheetDragHandle(),
              ],
            ),
          ),
          TextButton(
            key: const Key('submit_feedback_button'),
            child: Text(
              FeedbackLocalizations.of(context).submitButtonText,
              style: TextStyle(
                color: FeedbackTheme.of(context).activeFeedbackModeColor,
              ),
            ),
            onPressed: () => widget.onSubmit(_controller.text),
          ),
          const SizedBox(height: 8),
        ],
      );
}
