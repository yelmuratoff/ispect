import 'package:ispectify/ispectify.dart';

/// Case-insensitive search across all fields of [ISpectLogData],
/// including nested [ISpectLogData.additionalData].
class SearchFilter implements Filter<ISpectLogData> {
  SearchFilter(this.query) : _lowerQuery = query.toLowerCase();

  /// The original search query.
  final String query;

  final String _lowerQuery;

  @override
  bool apply(ISpectLogData item) {
    if (_lowerQuery.isEmpty) return true;

    final lowerMsg = item.lowerMessage;
    if (lowerMsg != null && lowerMsg.contains(_lowerQuery)) {
      return true;
    }

    final key = item.key;
    if (key != null && key.toLowerCase().contains(_lowerQuery)) return true;

    final title = item.title;
    if (title != null &&
        title != key &&
        title.toLowerCase().contains(_lowerQuery)) {
      return true;
    }

    final logLevel = item.logLevel;
    if (logLevel != null && logLevel.name.toLowerCase().contains(_lowerQuery)) {
      return true;
    }

    if (item.formattedTime.toLowerCase().contains(_lowerQuery)) return true;

    final exception = item.exception;
    if (exception != null &&
        exception.toString().toLowerCase().contains(_lowerQuery)) {
      return true;
    }

    final error = item.error;
    if (error != null && error.toString().toLowerCase().contains(_lowerQuery)) {
      return true;
    }

    final stackTrace = item.stackTrace;
    if (stackTrace != null &&
        stackTrace != StackTrace.empty &&
        stackTrace.toString().toLowerCase().contains(_lowerQuery)) {
      return true;
    }

    final additionalData = item.additionalData;
    return additionalData != null && _deepSearch(additionalData);
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

      // Primitives (int, bool, etc.) — check string representation.
      final str = current.toString();
      if (str.toLowerCase().contains(_lowerQuery)) return true;
    }
    return false;
  }
}
