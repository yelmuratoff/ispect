part of 'ispect_constants.dart';

List<LogDescription> _buildDefaultLogDescriptions(BuildContext context) {
  final l10n = context.ispectL10n;
  return [
    LogDescription(
      key: ISpectLogType.error.key,
      description: l10n.errorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.critical.key,
      description: l10n.criticalLogDesc,
    ),
    LogDescription(key: ISpectLogType.info.key, description: l10n.infoLogDesc),
    LogDescription(
      key: ISpectLogType.debug.key,
      description: l10n.debugLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.verbose.key,
      description: l10n.verboseLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.warning.key,
      description: l10n.warningLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.exception.key,
      description: l10n.exceptionLogDesc,
    ),
    LogDescription(key: ISpectLogType.good.key, description: l10n.goodLogDesc),
    LogDescription(
      key: ISpectLogType.print.key,
      description: l10n.printLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.provider.key,
      description: l10n.providerLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.analytics.key,
      description: l10n.analyticsLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.httpError.key,
      title: 'HTTP Error',
      description: l10n.httpErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.httpRequest.key,
      title: 'HTTP Request',
      description: l10n.httpRequestLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.httpResponse.key,
      title: 'HTTP Response',
      description: l10n.httpResponseLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocEvent.key,
      title: 'BLoC Event',
      description: l10n.blocEventLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocTransition.key,
      title: 'BLoC Transition',
      description: l10n.blocTransitionLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocDone.key,
      title: 'BLoC Done',
      description: l10n.blocDoneLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocClose.key,
      title: 'BLoC Close',
      description: l10n.blocCloseLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocCreate.key,
      title: 'BLoC Create',
      description: l10n.blocCreateLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocState.key,
      title: 'BLoC State',
      description: l10n.blocStateLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.blocError.key,
      title: 'BLoC Error',
      description: l10n.blocErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.riverpodAdd.key,
      title: 'Riverpod Add',
      description: l10n.riverpodAddLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.riverpodUpdate.key,
      title: 'Riverpod Update',
      description: l10n.riverpodUpdateLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.riverpodDispose.key,
      title: 'Riverpod Dispose',
      description: l10n.riverpodDisposeLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.riverpodFail.key,
      title: 'Riverpod Fail',
      description: l10n.riverpodFailLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.route.key,
      description: l10n.routeLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.wsSent.key,
      title: 'WebSocket Sent',
      description: l10n.wsSentLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.wsReceived.key,
      title: 'WebSocket Received',
      description: l10n.wsReceivedLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.wsState.key,
      title: 'WebSocket State',
      description: l10n.wsStateLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.dbQuery.key,
      title: 'Database Query',
      description: l10n.dbQueryLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.dbResult.key,
      title: 'Database Result',
      description: l10n.dbResultLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.dbError.key,
      title: 'Database Error',
      description: l10n.dbErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.wsError.key,
      title: 'WebSocket Error',
      description: l10n.wsErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.authSuccess.key,
      description: l10n.authSuccessLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.authError.key,
      description: l10n.authErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.storageResult.key,
      description: l10n.storageResultLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.storageQuery.key,
      description: l10n.storageQueryLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.storageError.key,
      description: l10n.storageErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.pushReceived.key,
      description: l10n.pushReceivedLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.pushSent.key,
      description: l10n.pushSentLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.pushError.key,
      description: l10n.pushErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.paymentSuccess.key,
      description: l10n.paymentSuccessLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.paymentError.key,
      description: l10n.paymentErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.stateChange.key,
      description: l10n.stateChangeLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.stateError.key,
      description: l10n.stateErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.sseReceived.key,
      title: 'SSE Received',
      description: l10n.sseReceivedLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.sseError.key,
      title: 'SSE Error',
      description: l10n.sseErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.grpcRequest.key,
      title: 'gRPC Request',
      description: l10n.grpcRequestLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.grpcResponse.key,
      title: 'gRPC Response',
      description: l10n.grpcResponseLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.grpcError.key,
      title: 'gRPC Error',
      description: l10n.grpcErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.graphqlRequest.key,
      title: 'GraphQL Request',
      description: l10n.graphqlRequestLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.graphqlResponse.key,
      title: 'GraphQL Response',
      description: l10n.graphqlResponseLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.graphqlError.key,
      title: 'GraphQL Error',
      description: l10n.graphqlErrorLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.performanceJank.key,
      title: 'Performance Jank',
      description: l10n.performanceJankLogDesc,
    ),
    LogDescription(
      key: ISpectLogType.performanceError.key,
      title: 'Performance Error',
      description: l10n.performanceErrorLogDesc,
    ),
  ];
}
