import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

AnsiPen getAnsiPenFromColor(Color color) =>
    AnsiPen()..rgb(r: color.r, g: color.g, b: color.b);

Color getColorFromAnsiPen(AnsiPen pen) {
  final fcolor = pen.fcolor;
  return Color.fromRGBO(
    fcolor & 0xFF,
    (fcolor >> 8) & 0xFF,
    (fcolor >> 16) & 0xFF,
    1,
  );
}
