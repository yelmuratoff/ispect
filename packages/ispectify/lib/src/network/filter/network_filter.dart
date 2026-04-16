/// Base class for network filter chain units.
///
/// A filter decides whether a network event (request, response, or error)
/// should be logged. Filters are synchronous, stateless by convention, and
/// side-effect free.
///
/// Implement [apply] to return `true` when the event should be logged.
abstract class NetworkFilter<T> {
  const NetworkFilter();

  /// Returns `true` if [value] should be logged.
  bool apply(T value);
}

/// Immutable, ordered chain of [NetworkFilter]s with short-circuit evaluation.
///
/// The chain runs filters in insertion order and stops at the first `false`.
/// An empty chain permits everything (returns `true`).
///
/// Chains are value-like: [add] and [merge] return new instances.
class NetworkFilterChain<T> {
  /// Creates a chain from an ordered list of filters.
  const NetworkFilterChain(List<NetworkFilter<T>> filters) : _filters = filters;

  /// Creates an empty chain that permits all events.
  const NetworkFilterChain.empty() : _filters = const [];

  /// Wraps a legacy `bool Function(T)` callback as a single-filter chain.
  factory NetworkFilterChain.fromPredicate(bool Function(T) predicate) =>
      NetworkFilterChain<T>([_PredicateFilter<T>(predicate)]);

  final List<NetworkFilter<T>> _filters;

  /// Runs all filters in order. Returns `false` on the first failing filter
  /// (short-circuit). An empty chain returns `true`.
  bool apply(T value) {
    for (final filter in _filters) {
      if (!filter.apply(value)) return false;
    }
    return true;
  }

  /// Returns a new chain with [filter] appended.
  NetworkFilterChain<T> add(NetworkFilter<T> filter) =>
      NetworkFilterChain<T>([..._filters, filter]);

  /// Returns a new chain combining this chain's filters with [other]'s.
  NetworkFilterChain<T> merge(NetworkFilterChain<T> other) =>
      NetworkFilterChain<T>([..._filters, ...other._filters]);

  /// Creates an OR-combinator filter: passes if *any* filter returns `true`.
  static NetworkFilter<T> any<T>(List<NetworkFilter<T>> filters) =>
      _AnyFilter<T>(filters);

  /// Whether this chain contains no filters.
  bool get isEmpty => _filters.isEmpty;

  /// The number of filters in this chain.
  int get length => _filters.length;
}

/// Wraps a plain callback for backward compatibility with legacy filters.
class _PredicateFilter<T> extends NetworkFilter<T> {
  const _PredicateFilter(this._predicate);

  final bool Function(T) _predicate;

  @override
  bool apply(T value) => _predicate(value);
}

/// OR-combinator: passes when at least one inner filter returns `true`.
class _AnyFilter<T> extends NetworkFilter<T> {
  const _AnyFilter(this._filters);

  final List<NetworkFilter<T>> _filters;

  @override
  bool apply(T value) => _filters.any((f) => f.apply(value));
}
