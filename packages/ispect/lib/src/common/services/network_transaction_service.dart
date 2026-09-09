import 'dart:collection';

import 'package:ispectify/ispectify.dart';

class GroupedLogEntries {
  const GroupedLogEntries({required this.entries, required this.transactions});

  final List<Object> entries;
  final Map<String, NetworkTransaction> transactions;
}

/// Controls which logs participate in transaction grouping.
class TransactionMatcher {
  const TransactionMatcher({
    required this.categories,
    this.errorLogTypes = const {},
    this.requestLogTypes = const {},
    this.legacyKeyPrefixes = const {},
  });

  final Set<String> categories;
  final Set<String> errorLogTypes;
  final Set<String> requestLogTypes;

  /// Key prefixes used by v4 logs that don't carry a [TraceKeys.category].
  /// For example, HTTP logs use the `'http-'` prefix.
  final Set<String> legacyKeyPrefixes;

  String? extractCorrelationId(ISpectLogData log) {
    if (!_belongsToCategory(log)) return null;

    final meta = log.additionalData?[TraceKeys.meta];
    if (meta is Map<String, dynamic>) {
      final id = meta['requestId'];
      if (id is String) return id;
    }
    final corrId = log.additionalData?[TraceKeys.correlationId];
    if (corrId is String) return corrId;
    final legacyId = log.additionalData?[NetworkJsonKeys.requestId];
    if (legacyId is String) return legacyId;
    return null;
  }

  LogRole roleOf(ISpectLogData log) {
    final key = log.key;
    if (key != null && errorLogTypes.contains(key)) return LogRole.error;
    if (key != null && requestLogTypes.contains(key)) return LogRole.request;
    if (log.additionalData?[TraceKeys.success] == false) {
      return LogRole.error;
    }
    return LogRole.response;
  }

  bool _belongsToCategory(ISpectLogData log) {
    final cat = log.additionalData?[TraceKeys.category];
    if (cat is String && categories.contains(cat)) return true;
    final key = log.key;
    if (key == null) return false;
    for (final c in categories) {
      if (key.startsWith('$c-')) return true;
    }
    for (final prefix in legacyKeyPrefixes) {
      if (key.startsWith(prefix)) return true;
    }
    return false;
  }
}

enum LogRole { request, response, error }

const httpTransactionMatcher = TransactionMatcher(
  categories: {TraceCategoryIds.network},
  errorLogTypes: {'http-error'},
  requestLogTypes: {'http-request'},
  legacyKeyPrefixes: {'http-'},
);

class NetworkTransactionService {
  NetworkTransactionService({this.matcher = httpTransactionMatcher});

  final TransactionMatcher matcher;

  GroupedLogEntries? _cached;
  List<ISpectLogData>? _cachedLogs;
  List<ISpectLogData>? _cachedSource;
  int _generation = -1;

  /// Folds [logs] into rows where correlated HTTP entries collapse into one
  /// [NetworkTransaction], keeping the order of [logs].
  ///
  /// Transactions are assembled from [source] when it is given, so a row
  /// stays whole when [logs] is a filtered subset of it: a response that
  /// passed the filter still sits next to its request.
  GroupedLogEntries getGroupedEntries(
    List<ISpectLogData> logs,
    int generation, {
    List<ISpectLogData>? source,
  }) {
    final pool = source ?? logs;
    final cached = _cached;
    if (cached != null &&
        _generation == generation &&
        identical(logs, _cachedLogs) &&
        identical(pool, _cachedSource)) {
      return cached;
    }

    final result = _buildGroupedEntries(logs, pool);
    _cached = result;
    _cachedLogs = logs;
    _cachedSource = pool;
    _generation = generation;
    return result;
  }

  void invalidate() {
    _cached = null;
    _cachedLogs = null;
    _cachedSource = null;
    _generation = -1;
  }

  GroupedLogEntries _buildGroupedEntries(
    List<ISpectLogData> logs,
    List<ISpectLogData> source,
  ) {
    final transactions = <String, NetworkTransaction>{};
    final correlationIds = HashMap<ISpectLogData, String>.identity();

    for (final log in source) {
      final corrId = matcher.extractCorrelationId(log);
      if (corrId == null) continue;

      correlationIds[log] = corrId;

      switch (matcher.roleOf(log)) {
        case LogRole.request:
          transactions[corrId] = NetworkTransaction(
            requestId: corrId,
            request: log,
            response: transactions[corrId]?.response,
            error: transactions[corrId]?.error,
          );
        case LogRole.error:
          final existing = transactions[corrId];
          if (existing != null) {
            transactions[corrId] = existing.copyWith(error: log);
          } else {
            transactions[corrId] = NetworkTransaction(
              requestId: corrId,
              request: log,
              error: log,
            );
          }
        case LogRole.response:
          final existing = transactions[corrId];
          if (existing != null) {
            transactions[corrId] = existing.copyWith(response: log);
          } else {
            transactions[corrId] = NetworkTransaction(
              requestId: corrId,
              request: log,
              response: log,
            );
          }
      }
    }

    final inserted = <String>{};
    final entries = <Object>[];

    for (final log in logs) {
      final corrId = correlationIds[log];
      final tx = corrId == null ? null : transactions[corrId];
      if (tx == null) {
        entries.add(log);
      } else if (inserted.add(tx.requestId)) {
        entries.add(tx);
      }
    }

    return GroupedLogEntries(entries: entries, transactions: transactions);
  }
}
