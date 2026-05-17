import 'dart:ui';

String formatInspectorDouble(
  double value, {
  int decimalPlaces = 1,
}) {
  assert(decimalPlaces >= 0, 'decimalPlaces must be >= 0');
  return value.toStringAsFixed(decimalPlaces);
}

String formatInspectorSize(
  Size size, {
  int decimalPlaces = 1,
}) =>
    '${formatInspectorDouble(size.width, decimalPlaces: decimalPlaces)} × '
    '${formatInspectorDouble(size.height, decimalPlaces: decimalPlaces)}';

String formatInspectorOffset(
  Offset offset, {
  int decimalPlaces = 1,
}) =>
    '(${formatInspectorDouble(offset.dx, decimalPlaces: decimalPlaces)}, '
    '${formatInspectorDouble(offset.dy, decimalPlaces: decimalPlaces)})';
