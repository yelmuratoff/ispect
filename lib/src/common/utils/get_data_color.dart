import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

AnsiPen getAnsiPenFromColor(Color color) =>
    AnsiPen()..rgb(r: color.red, g: color.green, b: color.blue);
