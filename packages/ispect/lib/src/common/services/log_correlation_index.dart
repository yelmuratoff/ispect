import 'package:ispect/src/common/services/network_transaction_service.dart';
import 'package:ispectify/ispectify.dart';

/// Result of a correlation lookup: the counterpart log and the time
/// between request and response/error.
typedef LogCorrelation = ({ISpectLogData? log, Duration? duration});

/// Indexes HTTP logs by `requestId` and returns the opposite role for a
/// given active log (request → response/error, response/error → request).
///
/// The index is delegated to [NetworkTransactionService] and reused across
/// lookups until the input list identity or generation changes, so the
/// cost is paid at most once per pipeline update instead of once per
/// widget rebuild.
class LogCorrelationIndex {
  LogCorrelationIndex({NetworkTransactionService? service})
      : _service = service ?? NetworkTransactionService();

  final NetworkTransactionService _service;

  Map<String, NetworkTransaction>? _index;
  List<ISpectLogData>? _input;
  int? _generation;

  /// Returns the counterpart log for [activeLog] or `null` when none
  /// exists (non-HTTP log, missing requestId, or pending transaction).
  LogCorrelation? find(
    ISpectLogData activeLog,
    List<ISpectLogData> allLogs,
    int generation,
  ) {
    if (!activeLog.isHttpLog) return null;

    final requestId = httpTransactionMatcher.extractCorrelationId(activeLog);
    if (requestId == null) return null;

    final tx = _ensure(allLogs, generation)[requestId];
    if (tx == null) return null;

    final role = httpTransactionMatcher.roleOf(activeLog);
    final ISpectLogData? counterpart;
    switch (role) {
      case LogRole.request:
        counterpart = tx.response ?? tx.error;
      case LogRole.response:
      case LogRole.error:
        counterpart = identical(tx.request, activeLog) ? null : tx.request;
    }
    if (counterpart == null) return null;

    return (
      log: counterpart,
      duration: role == LogRole.request
          ? counterpart.time.difference(activeLog.time)
          : activeLog.time.difference(counterpart.time),
    );
  }

  Map<String, NetworkTransaction> _ensure(
    List<ISpectLogData> allLogs,
    int generation,
  ) {
    final cached = _index;
    if (cached != null &&
        identical(allLogs, _input) &&
        generation == _generation) {
      return cached;
    }
    final grouped = _service.getGroupedEntries(allLogs, generation);
    _index = grouped.transactions;
    _input = allLogs;
    _generation = generation;
    return grouped.transactions;
  }
}
