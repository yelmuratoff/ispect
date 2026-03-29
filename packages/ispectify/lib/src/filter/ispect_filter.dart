import 'package:ispectify/ispectify.dart';

/// Composite filter combining title, type, log-type-key, and search criteria.
///
/// All criteria are combined with logical OR: a log passes if **any** active
/// criterion matches.
class ISpectFilter implements Filter<ISpectLogData> {
  ISpectFilter({
    Iterable<String> titles = const [],
    Iterable<Type> types = const [],
    Iterable<String> logTypeKeys = const [],
    String? searchQuery,
  })  : _titles = {...titles.where((title) => title.isNotEmpty)},
        _types = {...types},
        _logTypeKeys = {...logTypeKeys.where((key) => key.isNotEmpty)},
        _searchQuery = searchQuery?.trim(),
        _searchFilter = _toSearchFilter(searchQuery?.trim());

  static SearchFilter? _toSearchFilter(String? trimmed) =>
      (trimmed != null && trimmed.isNotEmpty) ? SearchFilter(trimmed) : null;

  final Set<String> _titles;
  final Set<Type> _types;
  final Set<String> _logTypeKeys;
  final String? _searchQuery;
  final SearchFilter? _searchFilter;

  /// Active filters materialized as a list (cached).
  late final List<Filter<ISpectLogData>> filters =
      List<Filter<ISpectLogData>>.unmodifiable([
    if (_titles.isNotEmpty) TitleFilter.fromSet(_titles),
    if (_types.isNotEmpty) TypeFilter.fromSet(_types),
    if (_logTypeKeys.isNotEmpty) LogTypeKeyFilter.fromSet(_logTypeKeys),
    if (_searchFilter != null) _searchFilter,
  ]);

  /// Read-only access to the configured titles.
  late final Set<String> titles = Set.unmodifiable(_titles);

  /// Read-only access to the configured runtime types.
  late final Set<Type> types = Set.unmodifiable(_types);

  /// Read-only access to the configured log keys.
  late final Set<String> logTypeKeys = Set.unmodifiable(_logTypeKeys);

  /// The configured search query, if any.
  String? get searchQuery => _searchQuery;

  late final bool _isEmpty = _titles.isEmpty &&
      _types.isEmpty &&
      _logTypeKeys.isEmpty &&
      _searchFilter == null;

  @override
  bool apply(ISpectLogData item) {
    if (_isEmpty) return true;

    if (_titles.contains(item.key) || _titles.contains(item.title)) {
      return true;
    }
    if (_logTypeKeys.contains(item.key)) return true;
    if (_types.contains(item.runtimeType)) return true;
    if (_searchFilter != null && _searchFilter.apply(item)) return true;

    return false;
  }

  /// Returns a new instance with updated criteria.
  /// `null` parameters preserve existing values.
  ISpectFilter copyWith({
    List<String>? titles,
    List<Type>? types,
    List<String>? logTypeKeys,
    String? searchQuery,
  }) =>
      ISpectFilter(
        titles: titles ?? _titles,
        types: types ?? _types,
        logTypeKeys: logTypeKeys ?? _logTypeKeys,
        searchQuery: searchQuery ?? _searchQuery,
      );
}
