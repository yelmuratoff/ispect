import 'package:flutter/material.dart';

Color getTypeColor({required bool isDark, required String? key}) {
  if (key == null) return Colors.grey;
  return isDark
      ? _darkTypeColors[key] ?? Colors.grey
      : _lightTypeColors[key] ?? Colors.grey;
}

const _lightTypeColors = {
  /// Base logs section
  "error": Color.fromARGB(255, 211, 47, 47),
  "critical": Color.fromARGB(255, 183, 28, 28),
  "info": Color.fromARGB(255, 25, 118, 210),
  "debug": Color.fromARGB(255, 97, 97, 97),
  "verbose": Color.fromARGB(255, 117, 117, 117),
  "warning": Color.fromARGB(255, 255, 160, 0),
  "exception": Color.fromARGB(255, 211, 47, 47),
  "good": Color.fromARGB(255, 56, 142, 60),

  /// Http section
  "http-error": Color.fromARGB(255, 211, 47, 47),
  "http-request": Color(0xFFD500F9),
  "http-response": Color(0xFF00C853),

  /// Bloc section
  "bloc-event": Color.fromARGB(255, 25, 118, 210),
  "bloc-transition": Color.fromARGB(255, 85, 139, 47),
  "bloc-close": Color(0xFFD50000),
  "bloc-create": Color.fromARGB(255, 56, 142, 60),

  "riverpod-add": Color.fromARGB(255, 56, 142, 60),
  "riverpod-update": Color.fromARGB(255, 0, 105, 135),
  "riverpod-dispose": Color(0xFFD50000),
  "riverpod-fail": Color.fromARGB(255, 211, 47, 47),

  /// Flutter section
  "route": Color(0xFF8E24AA),
};

const _darkTypeColors = {
  /// Base logs section
  "error": Color.fromARGB(255, 239, 83, 80),
  "critical": Color.fromARGB(255, 198, 40, 40),
  "info": Color.fromARGB(255, 66, 165, 245),
  "debug": Color.fromARGB(255, 158, 158, 158),
  "verbose": Color.fromARGB(255, 189, 189, 189),
  "warning": Color.fromARGB(255, 239, 108, 0),
  "exception": Color.fromARGB(255, 239, 83, 80),
  "good": Color.fromARGB(255, 120, 230, 129),

  /// Http section
  "http-error": Color.fromARGB(255, 239, 83, 80),
  "http-request": Color(0xFFF602C1),
  "http-response": Color(0xFF26FF3C),

  /// Bloc section
  "bloc-event": Color(0xFF63FAFE),
  "bloc-transition": Color(0xFF56FEA8),
  "bloc-close": Color(0xFFFF005F),
  "bloc-create": Color.fromARGB(255, 120, 230, 129),

  "riverpod-add": Color.fromARGB(255, 120, 230, 129),
  "riverpod-update": Color.fromARGB(255, 120, 180, 190),
  "riverpod-dispose": Color(0xFFFF005F),
  "riverpod-fail": Color.fromARGB(255, 239, 83, 80),

  /// Flutter section
  "route": Color(0xFFAF5FFF),
};
