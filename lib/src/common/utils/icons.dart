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

  'riverpod-add': Icons.add_rounded,
  'riverpod-update': Icons.refresh_rounded,
  'riverpod-dispose': Icons.close_rounded,
  'riverpod-fail': Icons.error_outline_rounded,

  /// Flutter section
  'route': Icons.route_rounded,
};
