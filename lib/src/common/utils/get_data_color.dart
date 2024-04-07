import 'package:flutter/material.dart';

Color getTypeColor({required bool isDark, required String? key}) {
  if (key == null) return Colors.grey;
  return isDark ? _darkTypeColors[key] ?? Colors.grey : _lightTypeColors[key] ?? Colors.grey;
}

const _lightTypeColors = {
  /// Base logs section
  "error": Color.fromARGB(255, 239, 83, 80),
  "critical": Color.fromARGB(255, 198, 40, 40),
  "info": Color.fromARGB(255, 66, 165, 245),
  "debug": Color.fromARGB(255, 158, 158, 158),
  "verbose": Color.fromARGB(255, 189, 189, 189),
  "warning": Color.fromARGB(255, 239, 108, 0),
  "exception": Color.fromARGB(255, 239, 83, 80),
  "good": Color.fromARGB(255, 90, 213, 100),
  "provider": Color.fromARGB(255, 120, 180, 190),

  /// Http section
  "http-error": Color.fromARGB(255, 239, 83, 80),
  "http-request": Color(0xFFF602C1),
  "http-response": Color(0xFF26FF3C),

  /// Bloc section
  "bloc-event": Color.fromARGB(255, 66, 107, 255),
  "bloc-transition": Color.fromARGB(255, 119, 138, 98),
  "bloc-close": Color(0xFFFF005F),
  "bloc-create": Color.fromARGB(255, 120, 230, 129),

  /// Flutter section
  "route": Color(0xFFAF5FFF),
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
  "provider": Color.fromARGB(255, 120, 180, 190),

  /// Http section
  "http-error": Color.fromARGB(255, 239, 83, 80),
  "http-request": Color(0xFFF602C1),
  "http-response": Color(0xFF26FF3C),

  /// Bloc section
  "bloc-event": Color(0xFF63FAFE),
  "bloc-transition": Color(0xFF56FEA8),
  "bloc-close": Color(0xFFFF005F),
  "bloc-create": Color.fromARGB(255, 120, 230, 129),

  /// Flutter section
  "route": Color(0xFFAF5FFF),
};
