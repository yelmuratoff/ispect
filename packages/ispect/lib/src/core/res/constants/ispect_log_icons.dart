part of 'ispect_constants.dart';

const Map<String, IconData> _kTypeIcons = {
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
  'ws-error': Icons.error_outline_rounded,

  /// Database
  'db-query': Icons.storage_rounded,
  'db-result': Icons.dataset_rounded,
  'db-error': Icons.error_outline_rounded,

  /// Auth
  'auth-success': Icons.verified_user_rounded,
  'auth-error': Icons.no_accounts_rounded,

  /// Storage
  'storage-result': Icons.cloud_done_rounded,
  'storage-query': Icons.cloud_download_rounded,
  'storage-error': Icons.cloud_off_rounded,

  /// Push
  'push-received': Icons.notifications_active_rounded,
  'push-sent': Icons.send_rounded,
  'push-error': Icons.notifications_off_rounded,

  /// Payment
  'payment-success': Icons.payment_rounded,
  'payment-error': Icons.money_off_rounded,

  /// State
  'state-change': Icons.change_circle_rounded,
  'state-error': Icons.error_outline_rounded,

  /// SSE
  'sse-received': Icons.stream_rounded,
  'sse-error': Icons.error_outline_rounded,

  /// gRPC
  'grpc-request': Icons.call_made_rounded,
  'grpc-response': Icons.call_received_rounded,
  'grpc-error': Icons.error_outline_rounded,

  /// GraphQL
  'graphql-request': Icons.hub_rounded,
  'graphql-response': Icons.hub_rounded,
  'graphql-error': Icons.error_outline_rounded,
};
