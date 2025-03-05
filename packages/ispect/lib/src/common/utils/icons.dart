import 'package:flutter/material.dart';

const typeIcons = {
  /// Base logs section
  'error': Icons.error_outline_rounded,
  'critical': Icons.error_outline_rounded,
  'info': Icons.info_outline_rounded,
  'debug': Icons.bug_report_outlined,
  'verbose': Icons.bug_report_outlined,
  'warning': Icons.warning_amber_rounded,
  'exception': Icons.error_outline_rounded,
  'good': Icons.check_circle_outline_rounded,
  'print': Icons.print_outlined,
  'analytics': Icons.track_changes_rounded,

  /// Http section
  'http-error': Icons.http_rounded,
  'http-request': Icons.http_rounded,
  'http-response': Icons.http_rounded,

  /// Bloc section
  'bloc-event': Icons.event_note_rounded,
  'bloc-transition': Icons.swap_horiz_rounded,
  'bloc-close': Icons.close_rounded,
  'bloc-create': Icons.add_rounded,
  'bloc-state': Icons.change_circle_rounded,

  'riverpod-add': Icons.add_rounded,
  'riverpod-update': Icons.refresh_rounded,
  'riverpod-dispose': Icons.close_rounded,
  'riverpod-fail': Icons.error_outline_rounded,

  /// Flutter section
  'route': Icons.route_rounded,
};

const lightTypeColors = {
  /// Base logs section
  'error': Color.fromARGB(255, 192, 38, 38),
  'critical': Color.fromARGB(255, 142, 22, 22),
  'info': Color.fromARGB(255, 25, 118, 210),
  'debug': Color.fromARGB(255, 97, 97, 97),
  'verbose': Color.fromARGB(255, 117, 117, 117),
  'warning': Color.fromARGB(255, 255, 160, 0),
  'exception': Color.fromARGB(255, 211, 47, 47),
  'good': Color.fromARGB(255, 56, 142, 60),
  'print': Color.fromARGB(255, 25, 118, 210),
  'analytics': Color.fromARGB(255, 182, 177, 25),

  /// Http section
  'http-error': Color.fromARGB(255, 192, 38, 38),
  'http-request': Color.fromARGB(255, 162, 0, 190),
  'http-response': Color.fromARGB(255, 0, 158, 66),

  /// Bloc section
  'bloc-event': Color.fromARGB(255, 25, 118, 210),
  'bloc-transition': Color.fromARGB(255, 85, 139, 47),
  'bloc-close': Color.fromARGB(255, 192, 38, 38),
  'bloc-create': Color.fromARGB(255, 56, 142, 60),
  'bloc-state': Color.fromARGB(255, 0, 105, 135),

  'riverpod-add': Color.fromARGB(255, 56, 142, 60),
  'riverpod-update': Color.fromARGB(255, 0, 105, 135),
  'riverpod-dispose': Color(0xFFD50000),
  'riverpod-fail': Color.fromARGB(255, 192, 38, 38),

  /// Flutter section
  'route': Color(0xFF8E24AA),
};

const darkTypeColors = {
  /// Base logs section
  'error': Color.fromARGB(255, 239, 83, 80),
  'critical': Color.fromARGB(255, 198, 40, 40),
  'info': Color.fromARGB(255, 66, 165, 245),
  'debug': Color.fromARGB(255, 158, 158, 158),
  'verbose': Color.fromARGB(255, 189, 189, 189),
  'warning': Color.fromARGB(255, 239, 108, 0),
  'exception': Color.fromARGB(255, 239, 83, 80),
  'good': Color.fromARGB(255, 120, 230, 129),
  'print': Color.fromARGB(255, 66, 165, 245),
  'analytics': Color.fromARGB(255, 255, 255, 0),

  /// Http section
  'http-error': Color.fromARGB(255, 239, 83, 80),
  'http-request': Color(0xFFF602C1),
  'http-response': Color(0xFF26FF3C),

  /// Bloc section
  'bloc-event': Color(0xFF63FAFE),
  'bloc-transition': Color(0xFF56FEA8),
  'bloc-close': Color(0xFFFF005F),
  'bloc-create': Color.fromARGB(255, 120, 230, 129),
  'bloc-state': Color.fromARGB(255, 0, 125, 160),

  'riverpod-add': Color.fromARGB(255, 120, 230, 129),
  'riverpod-update': Color.fromARGB(255, 120, 180, 190),
  'riverpod-dispose': Color(0xFFFF005F),
  'riverpod-fail': Color.fromARGB(255, 239, 83, 80),

  /// Flutter section
  'route': Color(0xFFAF5FFF),
};
