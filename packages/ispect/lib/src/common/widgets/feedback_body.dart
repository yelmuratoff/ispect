// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/snapshot/feedback_plus.dart';
import 'package:ispect/src/features/snapshot/src/theme/feedback_theme.dart';

/// Prompt the user for feedback using `StringFeedback`.
class SimpleFeedbackBuilder extends StatelessWidget {
  const SimpleFeedbackBuilder({
    required this.onSubmit,
    required this.theme,
    this.scrollController,
    super.key,
  });
  final OnSubmit onSubmit;
  final ScrollController? scrollController;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => StringFeedback(
        onSubmit: onSubmit,
        scrollController: scrollController,
        theme: theme,
      );
}

/// A form that prompts the user for feedback with a single text field.
/// This is the default feedback widget used by [BetterFeedback].
class StringFeedback extends StatefulWidget {
  /// Create a [StringFeedback].
  /// This is the default feedback bottom sheet, which is presented to the user.
  const StringFeedback({
    required this.onSubmit,
    required this.scrollController,
    required this.theme,
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
  final ThemeData theme;

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
                  padding: EdgeInsets.only(
                    left: 16,
                    top: widget.scrollController != null ? 20 : 16,
                    right: 16,
                  ),
                  children: <Widget>[
                    Text(
                      context.ispectL10n.feedbackDescriptionText,
                      maxLines: 2,
                    ),
                    const Gap(8),
                    TextField(
                      style: FeedbackTheme.of(context)
                          .bottomSheetTextInputStyle
                          .copyWith(
                            color: widget.theme.textTheme.bodyMedium?.color,
                          ),
                      key: const Key('text_input_field'),
                      maxLines: 20,
                      minLines: 2,
                      scrollPhysics: const NeverScrollableScrollPhysics(),
                      controller: _controller,
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(12),
                        hintText: context.ispectL10n.feedbackDescriptionText,
                        hintStyle: TextStyle(
                          color: widget.theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.scrollController != null)
                  const FeedbackSheetDragHandle(),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                key: const Key('submit_feedback_button'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      FeedbackTheme.of(context).activeFeedbackModeColor,
                  backgroundColor:
                      context.ispectTheme.colorScheme.primaryContainer,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share_rounded),
                    const Gap(8),
                    Text(
                      context.ispectL10n.share,
                    ),
                  ],
                ),
                onPressed: () => widget.onSubmit(_controller.text),
              ),
            ],
          ),
          const Gap(32),
        ],
      );
}
