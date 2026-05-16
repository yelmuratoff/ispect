import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

/// Thin [AlertDialog] wrapper that applies the ISpect surface defaults
/// (ISpect-themed background, no M3 surface tint).
///
/// Use this anywhere a plain `AlertDialog` would have repeated the
/// `backgroundColor: context.ispectBackgroundColor` + transparent surface tint
/// preamble.
class ISpectAlertDialog extends StatelessWidget {
  const ISpectAlertDialog({
    this.title,
    this.content,
    this.actions,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    super.key,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: context.ispectBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: title,
        content: content,
        actions: actions,
        titlePadding: titlePadding,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
      );
}
