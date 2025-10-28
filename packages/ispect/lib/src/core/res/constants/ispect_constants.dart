import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/ispect/domain/models/log_description.dart';

/// `ISpectConstants` class contains all the constants used in the `ISpect` package.
final class ISpectConstants {
  const ISpectConstants._();

  /// The default width of the draggable button.
  static const double draggableButtonWidth = 60;

  /// The default height of the draggable button.
  static const double draggableButtonHeight = 60;

  static const hidden = 'Hidden';

  // UI Constants for consistent spacing and sizing
  /// Standard icon size for log cards
  static const double logCardIconSize = 16.0;

  /// Standard icon button dimension
  static const double iconButtonDimension = 24.0;

  /// Standard icon button icon size
  static const double iconButtonIconSize = 16.0;

  /// Standard border radius
  static const double standardBorderRadius = 8.0;

  /// Large border radius for containers
  static const double largeBorderRadius = 10.0;

  /// Snackbar border radius
  static const double snackbarBorderRadius = 16.0;

  /// Standard horizontal padding
  static const double standardHorizontalPadding = 12.0;

  /// Standard vertical padding
  static const double standardVerticalPadding = 8.0;

  /// Standard gap size
  static const double standardGap = 6.0;

  /// Animation duration in milliseconds
  static const int animationDurationMs = 150;

  /// Max lines for selectable text in stack traces
  static const int stackTraceMaxLines = 50;

  /// Standard opacity for background colors
  static const double standardBackgroundOpacity = 0.08;

  /// Standard opacity for icon buttons
  static const double iconButtonBackgroundOpacity = 0.1;

  /// Standard opacity for disabled elements
  static const double disabledOpacity = 0.5;

  /// Toast background color
  static const Color toastBackgroundColor = Color.fromARGB(255, 49, 49, 49);

  static const typeIcons = {
    /// Base logs section
    'error': Icons.error_outline_rounded,
    'critical': Icons.new_releases_rounded,
    'info': Icons.info_outline_rounded,
    'debug': Icons.bug_report_outlined,
    'verbose': Icons.subject,
    'warning': Icons.warning_amber_rounded,
    'exception': Icons.report_rounded,
    'good': Icons.check_circle_outline_rounded,
    'print': Icons.print_outlined,
    'analytics': Icons.insights,

    /// Http section
    'http-error': Icons.http_rounded,
    'http-request': Icons.call_made_rounded,
    'http-response': Icons.call_received_rounded,

    /// Bloc section
    'bloc-event': Icons.event_note_rounded,
    'bloc-transition': Icons.swap_horiz_rounded,
    'bloc-close': Icons.close_rounded,
    'bloc-create': Icons.add_rounded,
    'bloc-state': Icons.change_circle_rounded,
    'bloc-done': Icons.check_circle_outline_rounded,
    'bloc-error': Icons.error_outline_rounded,

    'riverpod-add': Icons.add_rounded,
    'riverpod-update': Icons.refresh_rounded,
    'riverpod-dispose': Icons.close_rounded,
    'riverpod-fail': Icons.error_outline_rounded,

    /// Flutter section
    'route': Icons.route_rounded,

    /// WebSocket
    'ws-sent': Icons.call_made_rounded,
    'ws-received': Icons.call_received_rounded,

    /// Database
    'db-query': Icons.storage_rounded,
    'db-result': Icons.dataset_rounded,
    'db-error': Icons.error_outline_rounded,
  };

  static const lightTypeColors = {
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
    'http-request': Color(0xFF9C27B0),
    'http-response': Color(0xFF00C853),

    /// Bloc section
    'bloc-event': Color.fromARGB(255, 25, 118, 210),
    'bloc-transition': Color.fromARGB(255, 85, 139, 47),
    'bloc-close': Color.fromARGB(255, 192, 38, 38),
    'bloc-create': Color.fromARGB(255, 56, 142, 60),
    'bloc-state': Color.fromARGB(255, 0, 105, 135),
    'bloc-done': Color.fromARGB(255, 56, 142, 60),
    'bloc-error': Color.fromARGB(255, 192, 38, 38),

    'riverpod-add': Color.fromARGB(255, 56, 142, 60),
    'riverpod-update': Color.fromARGB(255, 0, 105, 135),
    'riverpod-dispose': Color(0xFFD50000),
    'riverpod-fail': Color.fromARGB(255, 192, 38, 38),

    /// Flutter section
    'route': Color(0xFF8E24AA),

    /// WebSocket
    'ws-sent': Color.fromARGB(255, 162, 0, 190),
    'ws-received': Color.fromARGB(255, 0, 158, 66),

    /// Database
    'db-query': Color.fromARGB(255, 25, 118, 210),
    'db-result': Color.fromARGB(255, 56, 142, 60),
    'db-error': Color.fromARGB(255, 192, 38, 38),
  };

  static const darkTypeColors = {
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
    'bloc-done': Color.fromARGB(255, 120, 230, 129),
    'bloc-error': Color.fromARGB(255, 239, 83, 80),

    'riverpod-add': Color.fromARGB(255, 120, 230, 129),
    'riverpod-update': Color.fromARGB(255, 120, 180, 190),
    'riverpod-dispose': Color(0xFFFF005F),
    'riverpod-fail': Color.fromARGB(255, 239, 83, 80),

    /// Flutter section
    'route': Color(0xFFAF5FFF),

    /// WebSocket
    'ws-sent': Color(0xFFF602C1),
    'ws-received': Color(0xFF26FF3C),

    /// Database
    'db-query': Color.fromARGB(255, 66, 165, 245),
    'db-result': Color.fromARGB(255, 120, 230, 129),
    'db-error': Color.fromARGB(255, 239, 83, 80),
  };

  /// Converts default log descriptions into a list of `LogDescription`.
  static List<LogDescription> defaultLogDescriptions(BuildContext context) {
    final l10n = context.ispectL10n;
    return [
      LogDescription(
        key: 'error',
        description: l10n.errorLogDesc,
      ),
      LogDescription(
        key: 'critical',
        description: l10n.criticalLogDesc,
      ),
      LogDescription(
        key: 'info',
        description: l10n.infoLogDesc,
      ),
      LogDescription(
        key: 'debug',
        description: l10n.debugLogDesc,
      ),
      LogDescription(
        key: 'verbose',
        description: l10n.verboseLogDesc,
      ),
      LogDescription(
        key: 'warning',
        description: l10n.warningLogDesc,
      ),
      LogDescription(
        key: 'exception',
        description: l10n.exceptionLogDesc,
      ),
      LogDescription(
        key: 'good',
        description: l10n.goodLogDesc,
      ),
      LogDescription(
        key: 'print',
        description: l10n.printLogDesc,
      ),
      LogDescription(
        key: 'analytics',
        description: l10n.analyticsLogDesc,
      ),
      LogDescription(
        key: 'http-error',
        description: l10n.httpErrorLogDesc,
      ),
      LogDescription(
        key: 'http-request',
        description: l10n.httpRequestLogDesc,
      ),
      LogDescription(
        key: 'http-response',
        description: l10n.httpResponseLogDesc,
      ),
      LogDescription(
        key: 'bloc-event',
        description: l10n.blocEventLogDesc,
      ),
      LogDescription(
        key: 'bloc-transition',
        description: l10n.blocTransitionLogDesc,
      ),
      LogDescription(
        key: 'bloc-done',
        description: l10n.blocDoneLogDesc,
      ),
      LogDescription(
        key: 'bloc-close',
        description: l10n.blocCloseLogDesc,
      ),
      LogDescription(
        key: 'bloc-create',
        description: l10n.blocCreateLogDesc,
      ),
      LogDescription(
        key: 'bloc-state',
        description: l10n.blocStateLogDesc,
      ),
      LogDescription(
        key: 'riverpod-add',
        description: l10n.riverpodAddLogDesc,
      ),
      LogDescription(
        key: 'riverpod-update',
        description: l10n.riverpodUpdateLogDesc,
      ),
      LogDescription(
        key: 'riverpod-dispose',
        description: l10n.riverpodDisposeLogDesc,
      ),
      LogDescription(
        key: 'riverpod-fail',
        description: l10n.riverpodFailLogDesc,
      ),
      LogDescription(
        key: 'route',
        description: l10n.routeLogDesc,
      ),
      LogDescription(
        key: 'ws-sent',
        description: l10n.wsSentLogDesc,
      ),
      LogDescription(
        key: 'ws-received',
        description: l10n.wsReceivedLogDesc,
      ),
      LogDescription(
        key: 'db-query',
        description: l10n.dbQueryLogDesc,
      ),
      LogDescription(
        key: 'db-result',
        description: l10n.dbResultLogDesc,
      ),
      LogDescription(
        key: 'db-error',
        description: l10n.dbErrorLogDesc,
      ),
    ];
  }
}
