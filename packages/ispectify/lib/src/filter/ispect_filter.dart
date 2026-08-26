import 'package:ispectify/ispectify.dart';

/// Composite filter combining log-type-key, runtime type, and search criteria.
///
/// The matching criteria are combined with logical OR: a log passes if **any**
/// active criterion matches. [excludedLogTypeKeys] is a veto instead — a log
/// whose key is excluded is rejected regardless of the other criteria.
class ISpectFilter implements Filter<ISpectLogData> {
  ISpectFilter({
    Iterable<Type> types = const [],
    Iterable<String> logTypeKeys = const [],
    Iterable<String> excludedLogTypeKeys = const [],
    String? searchQuery,
    this.resourceLimits = DiagnosticResourceLimits.balanced,
  })  : _types = {...types},
        _logTypeKeys = {...logTypeKeys.where((key) => key.isNotEmpty)},
        _excludedLogTypeKeys = {
          ...excludedLogTypeKeys.where((key) => key.isNotEmpty),
        },
        _searchQuery = searchQuery?.trim(),
        _searchFilter = _toSearchFilter(
          searchQuery?.trim(),
          resourceLimits,
        );

  static SearchFilter? _toSearchFilter(
    String? trimmed,
    DiagnosticResourceLimits resourceLimits,
  ) =>
      (trimmed != null && trimmed.isNotEmpty)
          ? SearchFilter(trimmed, resourceLimits: resourceLimits)
          : null;

  final Set<Type> _types;
  final Set<String> _logTypeKeys;
  final Set<String> _excludedLogTypeKeys;
  final String? _searchQuery;
  final SearchFilter? _searchFilter;
  final DiagnosticResourceLimits resourceLimits;

  /// Active filters materialized as a list (cached).
  late final List<Filter<ISpectLogData>> filters =
      List<Filter<ISpectLogData>>.unmodifiable([
    if (_types.isNotEmpty) TypeFilter.fromSet(_types),
    if (_logTypeKeys.isNotEmpty) LogTypeKeyFilter.fromSet(_logTypeKeys),
    if (_searchFilter != null) _searchFilter,
  ]);

  /// Read-only access to the configured runtime types.
  late final Set<Type> types = Set.unmodifiable(_types);

  /// Read-only access to the configured log keys.
  late final Set<String> logTypeKeys = Set.unmodifiable(_logTypeKeys);

  /// Read-only access to the vetoed log keys.
  late final Set<String> excludedLogTypeKeys =
      Set.unmodifiable(_excludedLogTypeKeys);

  /// The configured search query, if any.
  String? get searchQuery => _searchQuery;

  late final bool _isEmpty =
      _types.isEmpty && _logTypeKeys.isEmpty && _searchFilter == null;

  @override
  bool apply(ISpectLogData item) {
    if (_excludedLogTypeKeys.isNotEmpty) {
      final key = captureISpectLogWithoutPayload(item).key;
      if (key != null && _excludedLogTypeKeys.contains(key)) return false;
    }
    if (_isEmpty) return true;
    for (final filter in filters) {
      if (filter.apply(item)) return true;
    }
    return false;
  }

  /// Returns a new instance with updated criteria.
  /// `null` parameters preserve existing values.
  ISpectFilter copyWith({
    List<Type>? types,
    List<String>? logTypeKeys,
    Iterable<String>? excludedLogTypeKeys,
    String? searchQuery,
    DiagnosticResourceLimits? resourceLimits,
  }) =>
      ISpectFilter(
        types: types ?? _types,
        logTypeKeys: logTypeKeys ?? _logTypeKeys,
        excludedLogTypeKeys: excludedLogTypeKeys ?? _excludedLogTypeKeys,
        searchQuery: searchQuery ?? _searchQuery,
        resourceLimits: resourceLimits ?? this.resourceLimits,
      );
}
