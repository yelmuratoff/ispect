part of 'ispect_constants.dart';

List<LogDescription> _buildDefaultLogDescriptions(BuildContext context) {
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
      key: 'provider',
      description: l10n.providerLogDesc,
    ),
    LogDescription(
      key: 'analytics',
      description: l10n.analyticsLogDesc,
    ),
    LogDescription(
      key: 'http-error',
      title: 'HTTP Error',
      description: l10n.httpErrorLogDesc,
    ),
    LogDescription(
      key: 'http-request',
      title: 'HTTP Request',
      description: l10n.httpRequestLogDesc,
    ),
    LogDescription(
      key: 'http-response',
      title: 'HTTP Response',
      description: l10n.httpResponseLogDesc,
    ),
    LogDescription(
      key: 'bloc-event',
      title: 'BLoC Event',
      description: l10n.blocEventLogDesc,
    ),
    LogDescription(
      key: 'bloc-transition',
      title: 'BLoC Transition',
      description: l10n.blocTransitionLogDesc,
    ),
    LogDescription(
      key: 'bloc-done',
      title: 'BLoC Done',
      description: l10n.blocDoneLogDesc,
    ),
    LogDescription(
      key: 'bloc-close',
      title: 'BLoC Close',
      description: l10n.blocCloseLogDesc,
    ),
    LogDescription(
      key: 'bloc-create',
      title: 'BLoC Create',
      description: l10n.blocCreateLogDesc,
    ),
    LogDescription(
      key: 'bloc-state',
      title: 'BLoC State',
      description: l10n.blocStateLogDesc,
    ),
    LogDescription(
      key: 'bloc-error',
      title: 'BLoC Error',
      description: l10n.blocErrorLogDesc,
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
      title: 'WebSocket Sent',
      description: l10n.wsSentLogDesc,
    ),
    LogDescription(
      key: 'ws-received',
      title: 'WebSocket Received',
      description: l10n.wsReceivedLogDesc,
    ),
    LogDescription(
      key: 'db-query',
      title: 'Database Query',
      description: l10n.dbQueryLogDesc,
    ),
    LogDescription(
      key: 'db-result',
      title: 'Database Result',
      description: l10n.dbResultLogDesc,
    ),
    LogDescription(
      key: 'db-error',
      title: 'Database Error',
      description: l10n.dbErrorLogDesc,
    ),
    LogDescription(
      key: 'ws-error',
      title: 'WebSocket Error',
      description: l10n.wsErrorLogDesc,
    ),
    LogDescription(
      key: 'auth-success',
      description: l10n.authSuccessLogDesc,
    ),
    LogDescription(
      key: 'auth-error',
      description: l10n.authErrorLogDesc,
    ),
    LogDescription(
      key: 'storage-result',
      description: l10n.storageResultLogDesc,
    ),
    LogDescription(
      key: 'storage-query',
      description: l10n.storageQueryLogDesc,
    ),
    LogDescription(
      key: 'storage-error',
      description: l10n.storageErrorLogDesc,
    ),
    LogDescription(
      key: 'push-received',
      description: l10n.pushReceivedLogDesc,
    ),
    LogDescription(
      key: 'push-sent',
      description: l10n.pushSentLogDesc,
    ),
    LogDescription(
      key: 'push-error',
      description: l10n.pushErrorLogDesc,
    ),
    LogDescription(
      key: 'payment-success',
      description: l10n.paymentSuccessLogDesc,
    ),
    LogDescription(
      key: 'payment-error',
      description: l10n.paymentErrorLogDesc,
    ),
    LogDescription(
      key: 'state-change',
      description: l10n.stateChangeLogDesc,
    ),
    LogDescription(
      key: 'state-error',
      description: l10n.stateErrorLogDesc,
    ),
    LogDescription(
      key: 'sse-received',
      title: 'SSE Received',
      description: l10n.sseReceivedLogDesc,
    ),
    LogDescription(
      key: 'sse-error',
      title: 'SSE Error',
      description: l10n.sseErrorLogDesc,
    ),
    LogDescription(
      key: 'grpc-request',
      title: 'gRPC Request',
      description: l10n.grpcRequestLogDesc,
    ),
    LogDescription(
      key: 'grpc-response',
      title: 'gRPC Response',
      description: l10n.grpcResponseLogDesc,
    ),
    LogDescription(
      key: 'grpc-error',
      title: 'gRPC Error',
      description: l10n.grpcErrorLogDesc,
    ),
    LogDescription(
      key: 'graphql-request',
      title: 'GraphQL Request',
      description: l10n.graphqlRequestLogDesc,
    ),
    LogDescription(
      key: 'graphql-response',
      title: 'GraphQL Response',
      description: l10n.graphqlResponseLogDesc,
    ),
    LogDescription(
      key: 'graphql-error',
      title: 'GraphQL Error',
      description: l10n.graphqlErrorLogDesc,
    ),
    LogDescription(
      key: 'performance-jank',
      title: 'Performance Jank',
      description: l10n.performanceJankLogDesc,
    ),
    LogDescription(
      key: 'performance-error',
      title: 'Performance Error',
      description: l10n.performanceErrorLogDesc,
    ),
  ];
}
