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

/// A filter that checks whether an `ISpectifyData` item matches
/// any of the specified titles.
class TitleFilter implements Filter<ISpectifyData> {
  /// Creates a filter with a set of titles.
  ///
  /// Converts the list to a Set for O(1) lookups.
  TitleFilter(List<String> titles) : titles = titles.toSet();

  /// Set of titles used for filtering.
  final Set<String> titles;

  @override
  bool apply(ISpectifyData item) =>
      item.title != null && titles.contains(item.title);
}

/// A filter that checks whether an `ISpectifyData` item matches
/// any of the specified runtime types.
class TypeFilter implements Filter<ISpectifyData> {
  /// Creates a filter with a set of types.
  ///
  /// Converts the list to a Set for O(1) lookups.
  TypeFilter(List<Type> types) : types = types.toSet();

  /// Set of types used for filtering.
  final Set<Type> types;

  @override
  bool apply(ISpectifyData item) => types.contains(item.runtimeType);
}

/// A filter that performs a case-insensitive search within
/// the `message`, [textMessage], or [additionalData] fields of [ISpectifyData].
class SearchFilter implements Filter<ISpectifyData> {
  /// Creates a search filter with a specified `query`.
  SearchFilter(this.query) : _lowerQuery = query.toLowerCase();

  /// The original search query.
  final String query;

  /// Lowercased version of the search query for case-insensitive matching.
  final String _lowerQuery;

  @override
  bool apply(ISpectifyData item) {
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
    return item.additionalData != null &&
        _deepSearchIterative(item.additionalData, _lowerQuery);
  }

  /// Iteratively searches through nested structures (Map/List)
  /// for a matching string containing the query.
  ///
  /// Uses a stack-based approach to prevent stack overflow on deeply
  /// nested structures.
  bool _deepSearchIterative(Object? value, String query) {
    if (value == null) return false;

    // Use a growable list for the stack with initial capacity
    final stack = <Object?>[value];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      // Check if current value is a string containing the query
      if (current is String) {
        if (current.toLowerCase().contains(query)) {
          return true;
        }
        continue;
      }

      // Add map keys and values to stack
      if (current is Map<dynamic, dynamic>) {
        stack
          ..addAll(current.values)
          ..addAll(current.keys.map((k) => k.toString()));
      }
      // Add iterable elements to stack
      else if (current is Iterable<dynamic>) {
        stack.addAll(current);
      }
    }
    return false;
  }
}

/// A composite filter that combines multiple filtering criteria.
///
/// It allows filtering based on `titles`, `types`, and a `searchQuery`.
/// All filters are combined with a logical OR operation.
class ISpectifyFilter implements Filter<ISpectifyData> {
  /// Creates an `ISpectifyFilter` that combines title, type, and search filters.
  ISpectifyFilter({
    List<String> titles = const [],
    List<Type> types = const [],
    String? searchQuery,
  })  : _filters = _buildFilters(titles, types, searchQuery),
        _isEmpty =
            titles.isEmpty && types.isEmpty && (searchQuery?.isEmpty ?? true);

  /// List of individual filters applied.
  final List<Filter<ISpectifyData>> _filters;

  /// Getter for filters to provide read-only access.
  List<Filter<ISpectifyData>> get filters => List.unmodifiable(_filters);

  /// Indicates whether any filter is active.
  final bool _isEmpty;

  /// Builds a list of filters based on provided parameters.
  static List<Filter<ISpectifyData>> _buildFilters(
    List<String> titles,
    List<Type> types,
    String? searchQuery,
  ) {
    final filters = <Filter<ISpectifyData>>[];

    if (titles.isNotEmpty) filters.add(TitleFilter(titles));
    if (types.isNotEmpty) filters.add(TypeFilter(types));
    if (searchQuery?.isNotEmpty ?? false) {
      filters.add(SearchFilter(searchQuery!));
    }

    return filters;
  }

  @override
  bool apply(ISpectifyData item) {
    // Skip filtering if no filters are active
    if (_isEmpty) return true;

    // Returns true if any filter matches the item
    return _filters.any((filter) => filter.apply(item));
  }

  /// Returns a new instance of `ISpectifyFilter` with updated filtering criteria.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  ISpectifyFilter copyWith({
    List<String>? titles,
    List<Type>? types,
    String? searchQuery,
  }) =>
      ISpectifyFilter(
        titles: titles ??
            _getExistingFilterValues<TitleFilter, String>((f) => f.titles),
        types:
            types ?? _getExistingFilterValues<TypeFilter, Type>((f) => f.types),
        searchQuery: searchQuery ?? _getExistingSearchQuery(),
      );

  /// Retrieves existing values from a specific filter type.
  List<T> _getExistingFilterValues<F extends Filter<ISpectifyData>, T>(
    Set<T> Function(F filter) extractor,
  ) {
    final filter = _filters.whereType<F>().firstOrNull;
    return filter != null ? extractor(filter).toList() : [];
  }

  /// Retrieves the existing search query if a `SearchFilter` exists.
  String? _getExistingSearchQuery() {
    final filter = _filters.whereType<SearchFilter>().firstOrNull;
    return filter?.query;
  }
}
