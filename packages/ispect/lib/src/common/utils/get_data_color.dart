import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

AnsiPen getAnsiPenFromColor(Color color) =>
    AnsiPen()..rgb(r: color.r, g: color.g, b: color.b);
