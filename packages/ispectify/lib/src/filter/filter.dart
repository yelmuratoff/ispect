import 'package:ispectify/ispectify.dart';

export 'ispect_filter.dart';
export 'log_level_filter.dart';
export 'search_filter.dart';

/// A generic filter that checks whether a given item satisfies certain
/// conditions. Used as a building block for more specific filter types.
abstract class Filter<T> {
  /// Returns `true` if the item matches the filter condition.
  bool apply(T item);
}

/// Matches [ISpectLogData] items whose [ISpectLogData.key] is in [keys].
class LogTypeKeyFilter implements Filter<ISpectLogData> {
  /// Creates a filter matching any log whose `key` is present in [keys].
  LogTypeKeyFilter(List<String> keys) : keys = keys.toSet();

  /// Creates a filter from an existing [Set] (no copy).
  const LogTypeKeyFilter.fromSet(this.keys);

  /// Log-type keys that this filter matches (see [ISpectLogType]).
  final Set<String> keys;

  @override
  bool apply(ISpectLogData item) {
    final key = captureISpectLogDataForEgress(item).key;
    return key != null && keys.contains(key);
  }
}

/// Matches core log kinds in [types] without reading an overridable
/// `runtimeType` getter.
///
/// Custom and adapter subtypes are classified as [ISpectLogData]. Filter
/// those entries by their stable log key instead.
class TypeFilter implements Filter<ISpectLogData> {
  /// Creates a filter matching any trusted core log kind in [types].
  TypeFilter(List<Type> types) : types = types.toSet();

  /// Creates a filter from an existing [Set] (no copy).
  const TypeFilter.fromSet(this.types);

  /// Core log kinds that this filter matches.
  final Set<Type> types;

  @override
  bool apply(ISpectLogData item) => types.contains(
        switch (item) {
          ISpectLogException() => ISpectLogException,
          ISpectLogError() => ISpectLogError,
          _ => ISpectLogData,
        },
      );
}
