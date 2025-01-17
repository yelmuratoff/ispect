import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';

void copyClipboard(
  BuildContext context, {
  required String value,
  String? title,
  bool showValue = true,
}) {
  Clipboard.setData(
    ClipboardData(
      text: value,
    ),
  );
  ISpectToaster.showCopiedToast(
    context,
    value: value,
    title: title,
    showValue: showValue,
  );
}
