import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';

/// Shared sizing tokens for ISpect inputs. Keep in sync with
/// [ISpectSearchField] so search bars and plain text fields read as one
/// system.
abstract final class ISpectInputStyle {
  static const double radius = 10;
  static const double fontSize = 14;
  static const EdgeInsets denseContentPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 12);

  /// Default text style for ISpect inputs.
  ///
  /// Callers can override `fontWeight` per-input (e.g. numeric editors that
  /// want a bolder value) by passing a custom `textStyle`.
  static TextStyle textStyle(BuildContext context) => TextStyle(
        fontSize: fontSize,
        color: context.appTheme.colorScheme.onSurface,
      );

  /// Hint/placeholder text style for ISpect inputs.
  static TextStyle hintStyle(BuildContext context) => TextStyle(
        fontSize: fontSize,
        color: context.appTheme.colorScheme.onSurface.withValues(alpha: 0.5),
      );
}

/// Returns an [InputDecoration] that matches the rest of ISpect's surfaces:
/// filled card-color background, 10px radius, subtle neutral border, primary
/// accent on focus.
InputDecoration ispectInputDecoration(
  BuildContext context, {
  String? hintText,
  String? labelText,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isDense = true,
  EdgeInsetsGeometry? contentPadding,
  Color? fillColor,
}) {
  final fill = fillColor ?? context.ispectCardColor;
  final borderColor = context.ispectSubtleBorderColor;
  final primary = context.ispectPrimaryColor;

  InputBorder border(Color color, {double width = 1}) =>
      ISpectSquircle.inputBorder(
        radius: ISpectInputStyle.radius,
        side: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    filled: true,
    fillColor: fill,
    labelText: labelText,
    hintText: hintText,
    hintStyle: ISpectInputStyle.hintStyle(context),
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    isDense: isDense,
    contentPadding: contentPadding ?? ISpectInputStyle.denseContentPadding,
    border: border(borderColor),
    enabledBorder: border(borderColor),
    focusedBorder: border(primary, width: 1.2),
  );
}

/// Pre-styled [TextField] wrapper matching [ispectInputDecoration]. Use it
/// for plain numeric/text inputs inside dialogs and bottom sheets. For the
/// log-list search bar use `ISpectSearchField` instead — it uses Material 3
/// [SearchBar] under the hood.
class ISpectTextField extends StatelessWidget {
  const ISpectTextField({
    required this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.textAlignVertical,
    this.onChanged,
    this.onSubmitted,
    this.textStyle,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        minLines: minLines,
        expands: expands,
        textAlignVertical: textAlignVertical,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: textStyle ?? ISpectInputStyle.textStyle(context),
        decoration: ispectInputDecoration(
          context,
          hintText: hintText,
          labelText: labelText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      );
}
