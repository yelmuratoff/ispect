part of 'ispect_constants.dart';

final Map<String, IconData> _kTypeIcons = Map.unmodifiable({
  /// Base logs section
  ISpectLogType.error.key: Icons.error_outline_rounded,
  ISpectLogType.critical.key: Icons.new_releases_rounded,
  ISpectLogType.info.key: Icons.info_outline_rounded,
  ISpectLogType.debug.key: Icons.bug_report_outlined,
  ISpectLogType.verbose.key: Icons.subject,
  ISpectLogType.warning.key: Icons.warning_amber_rounded,
  ISpectLogType.exception.key: Icons.report_rounded,
  ISpectLogType.good.key: Icons.check_circle_outline_rounded,
  ISpectLogType.print.key: Icons.print_outlined,
  ISpectLogType.provider.key: Icons.inventory_2_outlined,
  ISpectLogType.analytics.key: Icons.insights,

  /// Http section
  ISpectLogType.httpError.key: Icons.http_rounded,
  ISpectLogType.httpRequest.key: Icons.call_made_rounded,
  ISpectLogType.httpResponse.key: Icons.call_received_rounded,

  /// Bloc section
  ISpectLogType.blocEvent.key: Icons.event_note_rounded,
  ISpectLogType.blocTransition.key: Icons.swap_horiz_rounded,
  ISpectLogType.blocClose.key: Icons.close_rounded,
  ISpectLogType.blocCreate.key: Icons.add_rounded,
  ISpectLogType.blocState.key: Icons.change_circle_rounded,
  ISpectLogType.blocDone.key: Icons.check_circle_outline_rounded,
  ISpectLogType.blocError.key: Icons.error_outline_rounded,

  ISpectLogType.riverpodAdd.key: Icons.add_rounded,
  ISpectLogType.riverpodUpdate.key: Icons.refresh_rounded,
  ISpectLogType.riverpodDispose.key: Icons.close_rounded,
  ISpectLogType.riverpodFail.key: Icons.error_outline_rounded,

  /// Flutter section
  ISpectLogType.route.key: Icons.route_rounded,

  /// WebSocket
  ISpectLogType.wsSent.key: Icons.call_made_rounded,
  ISpectLogType.wsReceived.key: Icons.call_received_rounded,
  ISpectLogType.wsError.key: Icons.error_outline_rounded,
  ISpectLogType.wsState.key: Icons.sync_alt_rounded,

  /// Database
  ISpectLogType.dbQuery.key: Icons.storage_rounded,
  ISpectLogType.dbResult.key: Icons.dataset_rounded,
  ISpectLogType.dbError.key: Icons.error_outline_rounded,

  /// Auth
  ISpectLogType.authSuccess.key: Icons.verified_user_rounded,
  ISpectLogType.authError.key: Icons.no_accounts_rounded,

  /// Storage
  ISpectLogType.storageResult.key: Icons.cloud_done_rounded,
  ISpectLogType.storageQuery.key: Icons.cloud_download_rounded,
  ISpectLogType.storageError.key: Icons.cloud_off_rounded,

  /// Push
  ISpectLogType.pushReceived.key: Icons.notifications_active_rounded,
  ISpectLogType.pushSent.key: Icons.send_rounded,
  ISpectLogType.pushError.key: Icons.notifications_off_rounded,

  /// Payment
  ISpectLogType.paymentSuccess.key: Icons.payment_rounded,
  ISpectLogType.paymentError.key: Icons.money_off_rounded,

  /// State
  ISpectLogType.stateChange.key: Icons.change_circle_rounded,
  ISpectLogType.stateError.key: Icons.error_outline_rounded,

  /// SSE
  ISpectLogType.sseReceived.key: Icons.stream_rounded,
  ISpectLogType.sseError.key: Icons.error_outline_rounded,

  /// gRPC
  ISpectLogType.grpcRequest.key: Icons.call_made_rounded,
  ISpectLogType.grpcResponse.key: Icons.call_received_rounded,
  ISpectLogType.grpcError.key: Icons.error_outline_rounded,

  /// GraphQL
  ISpectLogType.graphqlRequest.key: Icons.hub_rounded,
  ISpectLogType.graphqlResponse.key: Icons.hub_rounded,
  ISpectLogType.graphqlError.key: Icons.error_outline_rounded,

  /// Performance
  ISpectLogType.performanceJank.key: Icons.speed_rounded,
  ISpectLogType.performanceError.key: Icons.error_outline_rounded,
});
