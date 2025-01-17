import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

AnsiPen getAnsiPenFromColor(Color color) =>
    AnsiPen()..rgb(r: color.r, g: color.g, b: color.b);
