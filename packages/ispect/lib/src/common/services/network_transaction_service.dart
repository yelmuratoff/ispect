import 'package:ispectify/ispectify.dart';

class GroupedLogEntries {
  const GroupedLogEntries({
    required this.entries,
    required this.transactions,
  });

  final List<Object> entries;
  final Map<String, NetworkTransaction> transactions;
}

/// Controls which logs participate in transaction grouping.
class TransactionMatcher {
  const TransactionMatcher({
    required this.categories,
    this.errorLogTypes = const {},
    this.requestLogTypes = const {},
  });

  final Set<String> categories;
  final Set<String> errorLogTypes;
  final Set<String> requestLogTypes;

  String? extractCorrelationId(ISpectLogData log) {
    if (!_belongsToCategory(log)) return null;

    final meta = log.additionalData?[TraceKeys.meta];
    if (meta is Map<String, dynamic>) {
      final id = meta['requestId'];
      if (id is String) return id;
    }
    final corrId = log.additionalData?[TraceKeys.correlationId];
    if (corrId is String) return corrId;
    final legacyId = log.additionalData?['request-id'];
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
      if (key.startsWith('$c-') || key.startsWith('http-')) return true;
    }
    return false;
  }
}

enum LogRole { request, response, error }

const httpTransactionMatcher = TransactionMatcher(
  categories: {TraceCategoryIds.network},
  errorLogTypes: {'http-error'},
  requestLogTypes: {'http-request'},
);

class NetworkTransactionService {
  NetworkTransactionService({
    this.matcher = httpTransactionMatcher,
  });

  final TransactionMatcher matcher;

  Map<String, NetworkTransaction>? _cachedTransactions;
  List<Object>? _cachedEntries;
  int _generation = -1;

  GroupedLogEntries getGroupedEntries(
    List<ISpectLogData> logs,
    int generation,
  ) {
    if (_generation == generation &&
        _cachedTransactions != null &&
        _cachedEntries != null) {
      return GroupedLogEntries(
        entries: _cachedEntries!,
        transactions: _cachedTransactions!,
      );
    }

    final result = _buildGroupedEntries(logs);
    _cachedTransactions = result.transactions;
    _cachedEntries = result.entries;
    _generation = generation;
    return result;
  }

  void invalidate() {
    _cachedTransactions = null;
    _cachedEntries = null;
    _generation = -1;
  }

  GroupedLogEntries _buildGroupedEntries(List<ISpectLogData> logs) {
    final transactions = <String, NetworkTransaction>{};
    final groupedLogIndices = <int>{};

    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final corrId = matcher.extractCorrelationId(log);
      if (corrId == null) continue;

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
      groupedLogIndices.add(i);
    }

    final insertedTransactions = <String>{};
    final entries = <Object>[];

    for (var i = 0; i < logs.length; i++) {
      if (groupedLogIndices.contains(i)) {
        final corrId = matcher.extractCorrelationId(logs[i]);
        if (corrId != null && !insertedTransactions.contains(corrId)) {
          final tx = transactions[corrId];
          if (tx != null) {
            entries.add(tx);
            insertedTransactions.add(corrId);
          }
        }
      } else {
        entries.add(logs[i]);
      }
    }

    return GroupedLogEntries(
      entries: entries,
      transactions: transactions,
    );
  }
}
