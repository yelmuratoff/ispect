import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_object_pool.dart';

/// Interface for search strategy following Strategy pattern
abstract interface class SearchStrategy {
  Future<List<SearchResult>> search({
    required UnmodifiableListView<NodeViewModelState> nodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  });
}

/// Interface for search match finder following SRP
abstract interface class SearchMatchFinder {
  List<SearchResult> findMatches(
    NodeViewModelState node,
    String searchTerm,
  );
}

/// Interface for search progress tracker following SRP
abstract interface class SearchProgressTracker {
  void updateProgress(int processed, int total);
  void notifyComplete();
  bool shouldYield();
}

/// Concrete implementation for basic search match finding
class DefaultSearchMatchFinder implements SearchMatchFinder {
  @override
  List<SearchResult> findMatches(
    NodeViewModelState node,
    String searchTerm,
  ) {
    final results = <SearchResult>[];

    // Process key matches
    _addKeyMatches(node, searchTerm, results);

    // Process value matches for non-root nodes
    if (!node.isRoot) {
      _addValueMatches(node, searchTerm, results);
    }

    return results;
  }

  void _addKeyMatches(
    NodeViewModelState node,
    String searchTerm,
    List<SearchResult> results,
  ) {
    final nodeKey = node.key;
    if (nodeKey.isNotEmpty) {
      final keyLower = nodeKey.toLowerCase();
      if (keyLower.contains(searchTerm)) {
        _findAndAddMatches(
          keyLower,
          searchTerm,
          node,
          SearchMatchLocation.key,
          results,
        );
      }
    }
  }

  void _addValueMatches(
    NodeViewModelState node,
    String searchTerm,
    List<SearchResult> results,
  ) {
    final dynamic nodeValue = node.value;
    if (nodeValue != null) {
      final valueStr = nodeValue.toString();
      if (valueStr.isNotEmpty) {
        final valueLower = valueStr.toLowerCase();
        if (valueLower.contains(searchTerm)) {
          _findAndAddMatches(
            valueLower,
            searchTerm,
            node,
            SearchMatchLocation.value,
            results,
          );
        }
      }
    }
  }

  void _findAndAddMatches(
    String text,
    String pattern,
    NodeViewModelState node,
    SearchMatchLocation location,
    List<SearchResult> results,
  ) {
    var startIndex = 0;
    while (true) {
      final index = text.indexOf(pattern, startIndex);
      if (index == -1) break;

      results.add(
        SearchResult(
          node,
          matchLocation: location,
          matchIndex: index,
        ),
      );
      startIndex = index + 1;
    }
  }
}

/// Concrete implementation for search progress tracking
class DefaultSearchProgressTracker implements SearchProgressTracker {
  DefaultSearchProgressTracker({
    this.onProgressUpdate,
    this.yieldInterval = const Duration(milliseconds: 80),
    this.progressThreshold = 15,
  });

  final VoidCallback? onProgressUpdate;
  final Duration yieldInterval;
  final int progressThreshold;

  DateTime _nextUIUpdateTime = DateTime.now();
  int _resultsFoundSinceLastUpdate = 0;

  @override
  void updateProgress(int processed, int total) {
    _resultsFoundSinceLastUpdate++;
  }

  @override
  void notifyComplete() {
    onProgressUpdate?.call();
  }

  @override
  bool shouldYield() {
    final now = DateTime.now();
    if (now.isAfter(_nextUIUpdateTime) ||
        _resultsFoundSinceLastUpdate >= progressThreshold) {
      onProgressUpdate?.call();
      _nextUIUpdateTime = now.add(yieldInterval);
      _resultsFoundSinceLastUpdate = 0;
      return true;
    }
    return false;
  }
}

/// Concrete strategy for standard batch search
class StandardBatchSearchStrategy implements SearchStrategy {
  StandardBatchSearchStrategy({
    SearchMatchFinder? matchFinder,
    SearchProgressTracker? progressTracker,
  })  : _matchFinder = matchFinder ?? DefaultSearchMatchFinder(),
        _progressTracker = progressTracker;

  final SearchMatchFinder _matchFinder;
  final SearchProgressTracker? _progressTracker;

  @override
  Future<List<SearchResult>> search({
    required UnmodifiableListView<NodeViewModelState> nodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    if (searchTerm.isEmpty || nodes.isEmpty) {
      return const <SearchResult>[];
    }

    final normalizedTerm = searchTerm.toLowerCase();
    final results = <SearchResult>[];
    var processedCount = 0;

    // Adjust batch size based on node complexity
    final batchSize = _calculateBatchSize(nodes.length);
    final totalNodes = nodes.length;

    final tracker = _progressTracker ??
        DefaultSearchProgressTracker(onProgressUpdate: onProgressUpdate);

    while (processedCount < totalNodes && isMounted()) {
      final end = (processedCount + batchSize).clamp(0, totalNodes);
      final batch = nodes.sublist(processedCount, end);

      for (final node in batch) {
        if (!isMounted()) return results;

        final nodeResults = _matchFinder.findMatches(node, normalizedTerm);
        results.addAll(nodeResults);

        tracker.updateProgress(processedCount, totalNodes);
      }

      processedCount = end;

      if (tracker.shouldYield()) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    tracker.notifyComplete();
    return results;
  }

  int _calculateBatchSize(int nodeCount) => nodeCount > 10000
      ? 80
      : nodeCount > 5000
          ? 120
          : 200;
}

/// Concrete strategy for optimized search with short terms
class OptimizedShortTermSearchStrategy implements SearchStrategy {
  OptimizedShortTermSearchStrategy({
    SearchMatchFinder? matchFinder,
  }) : _matchFinder = matchFinder ?? DefaultSearchMatchFinder();

  final SearchMatchFinder _matchFinder;

  @override
  Future<List<SearchResult>> search({
    required UnmodifiableListView<NodeViewModelState> nodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    if (searchTerm.isEmpty || nodes.isEmpty) {
      return const <SearchResult>[];
    }

    const batchSize = 300;
    final results = <SearchResult>[];
    final totalNodes = nodes.length;
    var processedCount = 0;

    final normalizedTerm = searchTerm.toLowerCase();
    final tracker = DefaultSearchProgressTracker(
      onProgressUpdate: onProgressUpdate,
      yieldInterval: const Duration(milliseconds: 150),
      progressThreshold: 20,
    );

    while (processedCount < totalNodes && isMounted()) {
      final end = (processedCount + batchSize).clamp(0, totalNodes);
      final batch = nodes.sublist(processedCount, end);

      for (final node in batch) {
        if (!isMounted()) return results;

        final nodeResults = _matchFinder.findMatches(node, normalizedTerm);
        results.addAll(nodeResults);
      }

      processedCount = end;
      tracker.updateProgress(processedCount, totalNodes);

      if (tracker.shouldYield()) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    tracker.notifyComplete();
    return results;
  }
}

/// Factory for creating search strategies following Factory pattern
class SearchStrategyFactory {
  static SearchStrategy createStrategy({
    required int nodeCount,
    required int searchTermLength,
    SearchMatchFinder? matchFinder,
    SearchProgressTracker? progressTracker,
  }) {
    // Optimize for short search terms in large datasets
    if (nodeCount > 5000 && searchTermLength < 3) {
      return OptimizedShortTermSearchStrategy(matchFinder: matchFinder);
    }

    return StandardBatchSearchStrategy(
      matchFinder: matchFinder,
      progressTracker: progressTracker,
    );
  }
}

/// Improved search service following SOLID principles
class JsonSearchService {
  JsonSearchService({
    SearchStrategy? strategy,
    SearchMatchFinder? matchFinder,
    SearchProgressTracker? progressTracker,
  })  : _strategy = strategy,
        _matchFinder = matchFinder ?? DefaultSearchMatchFinder(),
        _progressTracker = progressTracker;

  SearchStrategy? _strategy;
  final SearchMatchFinder _matchFinder;
  final SearchProgressTracker? _progressTracker;

  static const Duration _searchDebounceTime = Duration(milliseconds: 300);

  /// Main search method using strategy pattern
  Future<List<SearchResult>> searchInNodes({
    required UnmodifiableListView<NodeViewModelState> allNodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    // Create strategy if not provided
    _strategy ??= SearchStrategyFactory.createStrategy(
      nodeCount: allNodes.length,
      searchTermLength: searchTerm.length,
      matchFinder: _matchFinder,
      progressTracker: _progressTracker,
    );

    return _strategy!.search(
      nodes: allNodes,
      searchTerm: searchTerm,
      isMounted: isMounted,
      onProgressUpdate: onProgressUpdate,
    );
  }

  /// Set a custom search strategy
  // ignore: use_setters_to_change_properties
  void setStrategy(SearchStrategy strategy) {
    _strategy = strategy;
  }

  /// Debounce search operations to improve performance
  static Timer? debounceSearchOperation(
    String searchTerm,
    DateTime? lastSearchTime,
    int nodeCount,
    VoidCallback onSearch,
  ) {
    final now = DateTime.now();
    if (lastSearchTime != null) {
      final timeSinceLastSearch = now.difference(lastSearchTime);
      final adjustedDebounceTime = nodeCount > 10000 && searchTerm.length < 3
          ? _searchDebounceTime + const Duration(milliseconds: 50)
          : _searchDebounceTime;

      if (timeSinceLastSearch < adjustedDebounceTime) {
        return Timer(adjustedDebounceTime - timeSinceLastSearch, onSearch);
      }
    }

    onSearch();
    return null;
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use _findAndAddMatches instead for better performance')
  static List<int> findAllOccurrences(String text, String pattern) {
    if (text.isEmpty || pattern.isEmpty) {
      return const <int>[];
    }

    final indices = JsonObjectPool.instance.getIntList();
    var startIndex = 0;

    try {
      while (true) {
        final index = text.indexOf(pattern, startIndex);
        if (index == -1) break;
        indices.add(index);
        startIndex = index + 1;
      }

      final result = List<int>.from(indices);
      return result;
    } finally {
      JsonObjectPool.instance.releaseIntList(indices);
    }
  }
}
