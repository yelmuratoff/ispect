import 'package:ispectify/src/models/log_type.dart';
import 'package:ispectify/src/trace/trace_category.dart';
import 'package:ispectify/src/trace/trace_category_ids.dart';

/// Predefined trace categories for built-in domains.
///
/// NB: `final` not `const` — in Dart, `.key` property access on an enum value
/// is NOT a compile-time constant expression. `final` top-level variables are
/// lazily initialized on first access (guaranteed single init).

final networkCategory = ISpectTraceCategory(
  id: TraceCategoryIds.network,
  successKey: ISpectLogType.httpResponse.key,
  errorKey: ISpectLogType.httpError.key,
  secondaryKey: ISpectLogType.httpRequest.key,
  secondaryOperations: const {'GET', 'HEAD', 'OPTIONS'},
);

final dbCategory = ISpectTraceCategory(
  id: TraceCategoryIds.db,
  successKey: ISpectLogType.dbResult.key,
  errorKey: ISpectLogType.dbError.key,
  secondaryKey: ISpectLogType.dbQuery.key,
  secondaryOperations: const {
    'query',
    'get',
    'select',
    'find',
    'count',
    'list',
  },
);

final authCategory = ISpectTraceCategory(
  id: TraceCategoryIds.auth,
  successKey: ISpectLogType.authSuccess.key,
  errorKey: ISpectLogType.authError.key,
);

final wsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.ws,
  successKey: ISpectLogType.wsReceived.key,
  errorKey: ISpectLogType.wsError.key,
  secondaryKey: ISpectLogType.wsSent.key,
  secondaryOperations: const {'send'},
);

final sseCategory = ISpectTraceCategory(
  id: TraceCategoryIds.sse,
  successKey: ISpectLogType.sseReceived.key,
  errorKey: ISpectLogType.sseError.key,
);

final storageCategory = ISpectTraceCategory(
  id: TraceCategoryIds.storage,
  successKey: ISpectLogType.storageResult.key,
  errorKey: ISpectLogType.storageError.key,
  secondaryKey: ISpectLogType.storageQuery.key,
  secondaryOperations: const {
    'download',
    'list',
    'getUrl',
    'getMetadata',
  },
);

final stateCategory = ISpectTraceCategory(
  id: TraceCategoryIds.state,
  successKey: ISpectLogType.stateChange.key,
  errorKey: ISpectLogType.stateError.key,
);

final pushCategory = ISpectTraceCategory(
  id: TraceCategoryIds.push,
  successKey: ISpectLogType.pushReceived.key,
  errorKey: ISpectLogType.pushError.key,
  secondaryKey: ISpectLogType.pushSent.key,
  secondaryOperations: const {'sent', 'send'},
);

/// NB: analytics uses one key for success and error.
/// Intentional — analytics events rarely have distinct error types.
final analyticsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.analytics,
  successKey: ISpectLogType.analytics.key,
  errorKey: ISpectLogType.analytics.key,
);

final paymentCategory = ISpectTraceCategory(
  id: TraceCategoryIds.payment,
  successKey: ISpectLogType.paymentSuccess.key,
  errorKey: ISpectLogType.paymentError.key,
);

/// NB: navigation — route push and pop are linked via correlationId.
final navigationCategory = ISpectTraceCategory(
  id: TraceCategoryIds.navigation,
  successKey: ISpectLogType.route.key,
  errorKey: ISpectLogType.route.key,
);

final grpcCategory = ISpectTraceCategory(
  id: TraceCategoryIds.grpc,
  successKey: ISpectLogType.grpcResponse.key,
  errorKey: ISpectLogType.grpcError.key,
  secondaryKey: ISpectLogType.grpcRequest.key,
  secondaryOperations: const {'unary', 'serverStreaming'},
);

final graphqlCategory = ISpectTraceCategory(
  id: TraceCategoryIds.graphql,
  successKey: ISpectLogType.graphqlResponse.key,
  errorKey: ISpectLogType.graphqlError.key,
  secondaryKey: ISpectLogType.graphqlRequest.key,
  secondaryOperations: const {'query', 'subscription'},
);

final performanceCategory = ISpectTraceCategory(
  id: TraceCategoryIds.performance,
  successKey: ISpectLogType.performanceJank.key,
  errorKey: ISpectLogType.performanceError.key,
);
