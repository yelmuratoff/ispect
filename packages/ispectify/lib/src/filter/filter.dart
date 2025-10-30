import 'package:ispectify/ispectify.dart';

/// An abstract class defining a filter interface.
///
/// A generic filter that checks whether a given item satisfies
/// certain conditions. Used as a building block for more specific filter types.
abstract class Filter<T> {
  /// Determines if the provided `item` passes the filter criteria.
  ///
  /// Returns `true` if the item matches the filter condition, `false` otherwise.
  bool apply(T item);
}

/// A filter that checks whether an `ISpectLogData` item matches
/// any of the specified log type keys.
class LogTypeKeyFilter implements Filter<ISpectLogData> {
  /// Creates a filter with a set of log type keys.
  ///
  /// Converts the list to a Set for O(1) lookups.
  LogTypeKeyFilter(List<String> keys) : keys = keys.toSet();

  /// Creates a filter from a set of log type keys.
  const LogTypeKeyFilter.fromSet(this.keys);

  /// Set of log type keys used for filtering.
  final Set<String> keys;

  @override
  bool apply(ISpectLogData item) {
    final key = item.key;
    return key != null && keys.contains(key);
  }
}

/// A filter that checks whether an `ISpectLogData` item matches
/// any of the specified titles.
class TitleFilter implements Filter<ISpectLogData> {
  /// Creates a filter with a set of titles.
  ///
  /// Converts the list to a Set for O(1) lookups.
  TitleFilter(List<String> titles) : titles = titles.toSet();

  /// Creates a filter from a set of titles.
  const TitleFilter.fromSet(this.titles);

  /// Set of titles used for filtering.
  final Set<String> titles;

  @override
  bool apply(ISpectLogData item) {
    final title = item.title;
    return title != null && titles.contains(title);
  }
}

/// A filter that checks whether an `ISpectLogData` item matches
/// any of the specified runtime types.
class TypeFilter implements Filter<ISpectLogData> {
  /// Creates a filter with a set of types.
  ///
  /// Converts the list to a Set for O(1) lookups.
  TypeFilter(List<Type> types) : types = types.toSet();

  /// Creates a filter from a set of types.
  const TypeFilter.fromSet(this.types);

  /// Set of types used for filtering.
  final Set<Type> types;

  @override
  bool apply(ISpectLogData item) => types.contains(item.runtimeType);
}

/// A filter that performs a case-insensitive search within
/// the `message`, [textMessage], or [additionalData] fields of [ISpectLogData].
class SearchFilter implements Filter<ISpectLogData> {
  /// Creates a search filter with a specified `query`.
  SearchFilter(this.query) : _lowerQuery = query.toLowerCase();

  /// The original search query.
  final String query;

  /// Lowercased version of the search query for case-insensitive matching.
  final String _lowerQuery;

  @override
  bool apply(ISpectLogData item) {
    // Early return if query is empty (matches everything)
    if (_lowerQuery.isEmpty) return true;

    // Check if the query is in message or textMessage
    final message = item.message;
    if (message != null && message.toLowerCase().contains(_lowerQuery)) {
      return true;
    }

    // Check in textMessage if available
    final textMessage = item.textMessage;
    if (textMessage.toLowerCase().contains(_lowerQuery)) return true;

    // Check in additional data recursively only if data exists
    final additionalData = item.additionalData;
    return additionalData != null &&
        _deepSearchIterative(additionalData, _lowerQuery);
  }

  /// Iteratively searches through nested structures (Map/List)
  /// for a matching string containing the query.
  ///
  /// Uses a stack-based approach to prevent stack overflow on deeply
  /// nested structures with visited tracking to avoid infinite loops.
  bool _deepSearchIterative(Object? value, String query) {
    if (value == null) return false;

    // Use a set to track visited objects to prevent infinite loops
    final visited = <Object>{};
    // Pre-allocate stack with reasonable initial capacity
    final stack = <Object?>[value];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current == null) continue;

      // Prevent infinite loops with circular references
      if (!visited.add(current)) continue;

      // Check if current value contains the query
      if (current is String) {
        if (current.toLowerCase().contains(query)) {
          return true;
        }
        continue;
      }

      // Handle Map structures
      if (current is Map<dynamic, dynamic>) {
        stack
          ..addAll(current.values)
          ..addAll(current.keys);
        continue;
      }

      // Handle Iterable structures (but not Strings which are also Iterable)
      if (current is Iterable<dynamic>) {
        stack.addAll(current);
        continue;
      }

      // Check primitive values' string representation
      final stringRepresentation = current.toString();
      if (stringRepresentation.toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }
}

/// A composite filter that combines multiple filtering criteria.
///
/// It allows filtering based on `titles`, `types`, `logTypeKeys`, and a `searchQuery`.
/// All filters are combined with a logical OR operation for search purposes.
class ISpectFilter implements Filter<ISpectLogData> {
  /// Creates an `ISpectFilter` that combines title, type, log type key, and search filters.
  ISpectFilter({
    Iterable<String> titles = const [],
    Iterable<Type> types = const [],
    Iterable<String> logTypeKeys = const [],
    String? searchQuery,
  })  : _titles = {...titles.where((title) => title.isNotEmpty)},
        _types = {...types},
        _logTypeKeys = {...logTypeKeys.where((key) => key.isNotEmpty)},
        _searchQuery = searchQuery?.trim(),
        _searchFilter = (searchQuery?.trim().isNotEmpty ?? false)
            ? SearchFilter(searchQuery!.trim())
            : null;

  final Set<String> _titles;
  final Set<Type> _types;
  final Set<String> _logTypeKeys;
  final String? _searchQuery;
  final SearchFilter? _searchFilter;

  /// Exposes the active filters for consumers that rely on the original API.
  List<Filter<ISpectLogData>> get filters =>
      List<Filter<ISpectLogData>>.unmodifiable(
        [
          if (_titles.isNotEmpty) TitleFilter.fromSet(_titles),
          if (_types.isNotEmpty) TypeFilter.fromSet(_types),
          if (_logTypeKeys.isNotEmpty) LogTypeKeyFilter.fromSet(_logTypeKeys),
          if (_searchFilter != null) _searchFilter,
        ],
      );

  /// Provides read-only access to the configured titles.
  Set<String> get titles => Set.unmodifiable(_titles);

  /// Provides read-only access to the configured runtime types.
  Set<Type> get types => Set.unmodifiable(_types);

  /// Provides read-only access to the configured log keys.
  Set<String> get logTypeKeys => Set.unmodifiable(_logTypeKeys);

  /// Returns the configured search query, if any.
  String? get searchQuery => _searchQuery;

  bool get _isEmpty =>
      _titles.isEmpty &&
      _types.isEmpty &&
      _logTypeKeys.isEmpty &&
      _searchFilter == null;

  @override
  bool apply(ISpectLogData item) {
    // Skip filtering if no filters are active
    if (_isEmpty) return true;

    if (_titles.contains(item.title)) return true;
    if (_logTypeKeys.contains(item.key)) return true;

    if (_types.isNotEmpty) {
      final runtimeType = item.runtimeType;
      if (_types.contains(runtimeType)) return true;
    }

    if (_searchFilter != null && _searchFilter.apply(item)) return true;

    return false;
  }

  /// Returns a new instance of `ISpectFilter` with updated filtering criteria.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  ISpectFilter copyWith({
    List<String>? titles,
    List<Type>? types,
    List<String>? logTypeKeys,
    String? searchQuery,
  }) => ISpectFilter(
      titles: titles ?? _titles,
      types: types ?? _types,
      logTypeKeys: logTypeKeys ?? _logTypeKeys,
      searchQuery: searchQuery ?? _searchQuery,
    );
}
