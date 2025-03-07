import 'package:ispectify/ispectify.dart';

abstract class Filter<T> {
  bool apply(T item);
}

class TitleFilter implements Filter<ISpectifyData> {
  TitleFilter(List<String> titles) : titles = titles.toSet();
  final Set<String> titles;

  @override
  bool apply(ISpectifyData item) => titles.contains(item.title);
}

class TypeFilter implements Filter<ISpectifyData> {
  TypeFilter(List<Type> types) : types = types.toSet();
  final Set<Type> types;

  @override
  bool apply(ISpectifyData item) => types.contains(item.runtimeType);
}

class SearchFilter implements Filter<ISpectifyData> {
  SearchFilter(this.query) {
    _upperQuery = query.toUpperCase();
    _lowerQuery = query.toLowerCase();
  }
  final String query;
  late final String _upperQuery;
  late final String _lowerQuery;

  @override
  bool apply(ISpectifyData item) {
    final message = item.message ?? item.textMessage;
    return message.toUpperCase().contains(_upperQuery) ||
        message.toLowerCase().contains(_lowerQuery);
  }
}

class ISpectifyFilter implements Filter<ISpectifyData> {
  ISpectifyFilter({
    List<String> titles = const [],
    List<Type> types = const [],
    String? searchQuery,
  })  : _filters = _buildFilters(titles, types, searchQuery),
        _isEmpty =
            titles.isEmpty && types.isEmpty && (searchQuery?.isEmpty ?? true);
  final List<Filter<ISpectifyData>> _filters;
  List<Filter<ISpectifyData>> get filters => _filters;
  final bool _isEmpty;

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
    if (_isEmpty) return true;
    return _filters.any((filter) => filter.apply(item));
  }

  ISpectifyFilter copyWith({
    List<String>? titles,
    List<Type>? types,
    String? searchQuery,
  }) =>
      ISpectifyFilter(
        titles: titles ??
            (_filters.any((f) => f is TitleFilter)
                ? (_filters.firstWhere((f) => f is TitleFilter) as TitleFilter)
                    .titles
                    .toList()
                : []),
        types: types ??
            (_filters.any((f) => f is TypeFilter)
                ? (_filters.firstWhere((f) => f is TypeFilter) as TypeFilter)
                    .types
                    .toList()
                : []),
        searchQuery: searchQuery ??
            (_filters.any((f) => f is SearchFilter)
                ? (_filters.firstWhere((f) => f is SearchFilter)
                        as SearchFilter)
                    .query
                : null),
      );
}
