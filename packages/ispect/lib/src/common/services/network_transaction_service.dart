import 'package:ispectify/ispectify.dart';

/// Result of grouping logs into network transactions.
class GroupedLogEntries {
  const GroupedLogEntries({
    required this.entries,
    required this.transactions,
  });

  /// Mixed list of [ISpectLogData] (non-HTTP logs) and
  /// [NetworkTransaction] (grouped HTTP logs), in chronological order.
  final List<Object> entries;

  /// All transactions indexed by [NetworkTransaction.requestId].
  final Map<String, NetworkTransaction> transactions;
}

/// Builds [NetworkTransaction] groups from a flat list of logs.
///
/// Uses generation-based caching to avoid recomputing on every frame.
/// Only logs with a non-null `requestId` (via [kRequestIdKey] in
/// [ISpectLogData.additionalData]) participate in grouping.
class NetworkTransactionService {
  Map<String, NetworkTransaction>? _cachedTransactions;
  List<Object>? _cachedEntries;
  int _generation = -1;

  /// Returns grouped entries for the given [logs] list.
  ///
  /// The result is cached per [generation] — pass the data generation
  /// counter from the filter manager to invalidate on new logs.
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

  /// Invalidates the cache, forcing a rebuild on next access.
  void invalidate() {
    _cachedTransactions = null;
    _cachedEntries = null;
    _generation = -1;
  }

  /// Single O(n) pass to build transactions and the grouped list.
  GroupedLogEntries _buildGroupedEntries(List<ISpectLogData> logs) {
    final transactions = <String, NetworkTransaction>{};
    // Track which logs have been grouped (by their index in the original list).
    final groupedLogIndices = <int>{};
    // Map requestId → index of the request log for insertion ordering.
    final requestIndices = <String, int>{};

    // First pass: build transactions
    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final requestId = _extractRequestId(log);
      if (requestId == null) continue;

      final isRequest = log is NetworkRequestLog ||
          log.key == ISpectLogType.httpRequest.key;
      final isError = log is NetworkErrorLog ||
          log.key == ISpectLogType.httpError.key;

      if (isRequest) {
        transactions[requestId] = NetworkTransaction(
          requestId: requestId,
          request: log,
          response: transactions[requestId]?.response,
          error: transactions[requestId]?.error,
        );
        requestIndices[requestId] = i;
        groupedLogIndices.add(i);
      } else if (isError) {
        final existing = transactions[requestId];
        if (existing != null) {
          transactions[requestId] = existing.copyWith(error: log);
        } else {
          // Error without a request — create a standalone transaction.
          transactions[requestId] = NetworkTransaction(
            requestId: requestId,
            request: log,
            error: log,
          );
          requestIndices[requestId] = i;
        }
        groupedLogIndices.add(i);
      } else {
        // Response
        final existing = transactions[requestId];
        if (existing != null) {
          transactions[requestId] = existing.copyWith(response: log);
        } else {
          // Response without a request — create a standalone transaction.
          transactions[requestId] = NetworkTransaction(
            requestId: requestId,
            request: log,
            response: log,
          );
          requestIndices[requestId] = i;
        }
        groupedLogIndices.add(i);
      }
    }

    // Second pass: build the mixed entries list.
    // Replace grouped logs with their transaction at the request's position.
    final insertedTransactions = <String>{};
    final entries = <Object>[];

    for (var i = 0; i < logs.length; i++) {
      if (groupedLogIndices.contains(i)) {
        final requestId = _extractRequestId(logs[i]);
        if (requestId != null && !insertedTransactions.contains(requestId)) {
          final tx = transactions[requestId];
          if (tx != null) {
            entries.add(tx);
            insertedTransactions.add(requestId);
          }
        }
        // Skip — already represented by the transaction.
      } else {
        entries.add(logs[i]);
      }
    }

    return GroupedLogEntries(
      entries: entries,
      transactions: transactions,
    );
  }

  /// Extracts request ID from a log entry.
  ///
  /// Checks the typed field first (for live logs), then falls back
  /// to [additionalData] (for imported/deserialized logs).
  String? _extractRequestId(ISpectLogData log) {
    if (log is NetworkRequestLog) return log.requestId;
    if (log is NetworkResponseLog) return log.requestId;
    if (log is NetworkErrorLog) return log.requestId;
    return log.additionalData?[kRequestIdKey] as String?;
  }
}
