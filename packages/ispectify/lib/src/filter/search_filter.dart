import 'package:ispectify/ispectify.dart';

/// Case-insensitive search across all fields of [ISpectLogData],
/// including nested [ISpectLogData.additionalData].
class SearchFilter implements Filter<ISpectLogData> {
  SearchFilter(
    String query, {
    this.resourceLimits = DiagnosticResourceLimits.balanced,
  })  : query = LogExportOutput.truncateUtf8(
          query,
          maxBytes: resourceLimits.maxSearchQueryBytes,
        ),
        _lowerQuery = LogExportOutput.truncateUtf8(
          query,
          maxBytes: resourceLimits.maxSearchQueryBytes,
        ).toLowerCase();

  /// The bounded search query.
  final String query;

  /// Budgets applied to the query and searchable log snapshot.
  final DiagnosticResourceLimits resourceLimits;

  final String _lowerQuery;

  @override
  bool apply(ISpectLogData item) {
    if (_lowerQuery.isEmpty) return true;

    final captured = captureISpectLogDataForEgress(item);
    final snapshot = LogExportOutput.boundJsonValue(
      <String, Object?>{
        'message': captured.message,
        'key': captured.key,
        'log-level': captured.logLevel?.name,
        'time': ISpectDateTimeFormatter(captured.time).defaultFormat,
        'exception': captured.exceptionText,
        'error': captured.errorText,
        'stack-trace': captured.stackTraceText,
        'additional-data': captured.additionalData,
      },
      resourceLimits: resourceLimits,
    );
    return _deepSearch(snapshot);
  }

  /// Iteratively searches nested structures (Map/List) for a string
  /// containing [_lowerQuery].
  ///
  /// Uses identity-based [Set] to detect circular references in Map/List
  /// without preventing equal primitives from being checked (primitives
  /// are checked inline, never added to [visited]).
  bool _deepSearch(Object? value) {
    if (value == null) return false;

    final visited = Set<Object>.identity();
    final stack = <Object?>[value];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current == null) continue;

      if (current is String) {
        if (current.toLowerCase().contains(_lowerQuery)) return true;
        continue;
      }

      if (current is Map<dynamic, dynamic>) {
        if (!visited.add(current)) continue;
        for (final key in current.keys) {
          if (key is String && key.toLowerCase().contains(_lowerQuery)) {
            return true;
          }
        }
        stack.addAll(current.values);
        continue;
      }

      if (current is Iterable<dynamic>) {
        if (!visited.add(current)) continue;
        stack.addAll(current);
        continue;
      }

      if (current is num || current is bool) {
        if (current.toString().toLowerCase().contains(_lowerQuery)) return true;
      }
    }
    return false;
  }
}
