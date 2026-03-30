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
  LogTypeKeyFilter(List<String> keys) : keys = keys.toSet();

  const LogTypeKeyFilter.fromSet(this.keys);

  final Set<String> keys;

  @override
  bool apply(ISpectLogData item) {
    final key = item.key;
    return key != null && keys.contains(key);
  }
}

/// Matches [ISpectLogData] items whose runtime type is in [types].
class TypeFilter implements Filter<ISpectLogData> {
  TypeFilter(List<Type> types) : types = types.toSet();

  const TypeFilter.fromSet(this.types);

  final Set<Type> types;

  @override
  bool apply(ISpectLogData item) => types.contains(item.runtimeType);
}
