import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/trace/trace_category_ids.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Convenience getters for accessing structured trace data in [ISpectLogData].
///
/// All getters use defensive `is` checks instead of `as` casts.
/// If [additionalData] contains unexpected types (v4 logs, custom data,
/// deserialized JSON), getters safely return `null` instead of throwing.
extension ISpectLogDataX on ISpectLogData {
  // ── Structured trace field access ──────────────────────────────────

  String? get traceCategory {
    final v = additionalData?[TraceKeys.category];
    return v is String ? v : null;
  }

  String? get traceSource {
    final v = additionalData?[TraceKeys.source];
    return v is String ? v : null;
  }

  String? get traceOperation {
    final v = additionalData?[TraceKeys.operation];
    return v is String ? v : null;
  }

  String? get traceTarget {
    final v = additionalData?[TraceKeys.target];
    return v is String ? v : null;
  }

  Map<String, dynamic>? get traceMeta {
    final v = additionalData?[TraceKeys.meta];
    return v is Map<String, dynamic> ? v : null;
  }

  int? get traceDurationMs {
    final v = additionalData?[TraceKeys.durationMs];
    return v is int ? v : null;
  }

  bool? get traceSuccess {
    final v = additionalData?[TraceKeys.success];
    return v is bool ? v : null;
  }

  bool? get traceSlow {
    final v = additionalData?[TraceKeys.slow];
    return v is bool ? v : null;
  }

  String? get traceTransactionId {
    final v = additionalData?[TraceKeys.transactionId];
    return v is String ? v : null;
  }

  String? get traceCorrelationId {
    final v = additionalData?[TraceKeys.correlationId];
    return v is String ? v : null;
  }

  // ── Category checks ────────────────────────────────────────────────

  bool get isNetwork => traceCategory == TraceCategoryIds.network;
  bool get isWs => traceCategory == TraceCategoryIds.ws;
  bool get isSse => traceCategory == TraceCategoryIds.sse;
  bool get isGrpc => traceCategory == TraceCategoryIds.grpc;
  bool get isGraphql => traceCategory == TraceCategoryIds.graphql;
  bool get isDb => traceCategory == TraceCategoryIds.db;
  bool get isState => traceCategory == TraceCategoryIds.state;
  bool get isAuth => traceCategory == TraceCategoryIds.auth;
  bool get isStorage => traceCategory == TraceCategoryIds.storage;
  bool get isPush => traceCategory == TraceCategoryIds.push;
  bool get isAnalytics => traceCategory == TraceCategoryIds.analytics;
  bool get isPayment => traceCategory == TraceCategoryIds.payment;
  bool get isNavigation => traceCategory == TraceCategoryIds.navigation;

  // ── Network convenience (from nested meta) ─────────────────────────

  int? get httpStatusCode {
    final v = traceMeta?['statusCode'];
    return v is int ? v : null;
  }

  String? get requestId {
    final v = traceMeta?['requestId'];
    return v is String ? v : null;
  }

  Map<String, dynamic>? get httpHeaders {
    final v = traceMeta?['headers'];
    return v is Map<String, dynamic> ? v : null;
  }

  // ── DB convenience ─────────────────────────────────────────────────

  String? get dbStatement {
    final v = traceMeta?['statement'];
    return v is String ? v : null;
  }

  String? get dbStatementDigest {
    final v = traceMeta?['statementDigest'];
    return v is String ? v : null;
  }

  List<Object?>? get dbArgs {
    final v = traceMeta?['args'];
    return v is List<Object?> ? v : null;
  }

  // ── Auth convenience ───────────────────────────────────────────────

  String? get authProvider {
    final v = traceMeta?['provider'];
    return v is String ? v : null;
  }

  // ── Storage convenience ────────────────────────────────────────────

  String? get storageBucket {
    final v = traceMeta?['bucket'];
    return v is String ? v : null;
  }

  int? get storageSizeBytes {
    final v = traceMeta?['sizeBytes'];
    return v is int ? v : null;
  }

  // ── State convenience ──────────────────────────────────────────────

  String? get blocType {
    final v = traceMeta?['blocType'];
    return v is String ? v : null;
  }

  String? get eventType {
    final v = traceMeta?['eventType'];
    return v is String ? v : null;
  }

  // ── Push convenience ───────────────────────────────────────────────

  String? get pushTitle {
    final v = traceMeta?['title'];
    return v is String ? v : null;
  }

  String? get pushTopic {
    final v = traceMeta?['topic'];
    return v is String ? v : null;
  }

  // ── Payment convenience ────────────────────────────────────────────

  /// NB: `num` check — JSON may return int (100) instead of double (100.0).
  double? get paymentAmount {
    final v = traceMeta?['amount'];
    return v is num ? v.toDouble() : null;
  }

  String? get paymentCurrency {
    final v = traceMeta?['currency'];
    return v is String ? v : null;
  }

  // ── Generic ────────────────────────────────────────────────────────

  /// Check any custom category: `log.hasCategory('my-service')`
  bool hasCategory(String categoryId) => traceCategory == categoryId;
}
