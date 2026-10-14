import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispectify/ispectify.dart';

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
  List<SearchResult> findMatches(NodeViewModelState node, String searchTerm);
}

/// Interface for search progress tracker following SRP
abstract interface class SearchProgressTracker {
  void updateProgress(int processed, int total);
  void notifyComplete();
  bool shouldYield();
}

/// Concrete implementation for basic search match finding
class DefaultSearchMatchFinder implements SearchMatchFinder {
  RegExp? _pattern;
  String? _patternTerm;

  @override
  List<SearchResult> findMatches(NodeViewModelState node, String searchTerm) {
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
    if (nodeKey.isEmpty) return;
    _addMatches(nodeKey, searchTerm, node, SearchMatchLocation.key, results);
  }

  void _addValueMatches(
    NodeViewModelState node,
    String searchTerm,
    List<SearchResult> results,
  ) {
    final valueStr = node.value?.toString() ?? '';
    if (valueStr.isEmpty) return;
    _addMatches(valueStr, searchTerm, node, SearchMatchLocation.value, results);
  }

  void _addMatches(
    String text,
    String searchTerm,
    NodeViewModelState node,
    SearchMatchLocation location,
    List<SearchResult> results,
  ) {
    for (final match in _patternFor(searchTerm).allMatches(text)) {
      results.add(
        SearchResult(node, matchLocation: location, matchIndex: match.start),
      );
    }
  }

  RegExp _patternFor(String searchTerm) {
    final cached = _pattern;
    if (cached != null && _patternTerm == searchTerm) return cached;
    _patternTerm = searchTerm;
    return _pattern = RegExp(RegExp.escape(searchTerm), caseSensitive: false);
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
    this.processingPolicy = DiagnosticProcessingPolicy.balanced,
  }) : _matchFinder = matchFinder ?? DefaultSearchMatchFinder(),
       _progressTracker = progressTracker {
    processingPolicy.validate();
  }

  final SearchMatchFinder _matchFinder;
  final SearchProgressTracker? _progressTracker;
  final DiagnosticProcessingPolicy processingPolicy;

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

    final tracker =
        _progressTracker ??
        DefaultSearchProgressTracker(
          onProgressUpdate: onProgressUpdate,
          yieldInterval: processingPolicy.searchYieldInterval,
          progressThreshold: processingPolicy.searchProgressThreshold,
        );

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

  int _calculateBatchSize(int nodeCount) =>
      nodeCount > processingPolicy.veryLargeSearchNodeThreshold
      ? processingPolicy.veryLargeSearchBatchSize
      : nodeCount > processingPolicy.largeSearchNodeThreshold
      ? processingPolicy.largeSearchBatchSize
      : processingPolicy.searchBatchSize;
}

/// Concrete strategy for optimized search with short terms
class OptimizedShortTermSearchStrategy implements SearchStrategy {
  OptimizedShortTermSearchStrategy({
    SearchMatchFinder? matchFinder,
    this.processingPolicy = DiagnosticProcessingPolicy.balanced,
  }) : _matchFinder = matchFinder ?? DefaultSearchMatchFinder() {
    processingPolicy.validate();
  }

  final SearchMatchFinder _matchFinder;
  final DiagnosticProcessingPolicy processingPolicy;

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

    final batchSize = processingPolicy.shortSearchBatchSize;
    final results = <SearchResult>[];
    final totalNodes = nodes.length;
    var processedCount = 0;

    final normalizedTerm = searchTerm.toLowerCase();
    final tracker = DefaultSearchProgressTracker(
      onProgressUpdate: onProgressUpdate,
      yieldInterval: processingPolicy.shortSearchYieldInterval,
      progressThreshold: processingPolicy.shortSearchProgressThreshold,
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
    DiagnosticProcessingPolicy processingPolicy =
        DiagnosticProcessingPolicy.balanced,
  }) {
    processingPolicy.validate();
    // Optimize for short search terms in large datasets
    if (nodeCount > processingPolicy.largeSearchNodeThreshold &&
        searchTermLength < 3) {
      return OptimizedShortTermSearchStrategy(
        matchFinder: matchFinder,
        processingPolicy: processingPolicy,
      );
    }

    return StandardBatchSearchStrategy(
      matchFinder: matchFinder,
      progressTracker: progressTracker,
      processingPolicy: processingPolicy,
    );
  }
}

/// Improved search service following SOLID principles
class JsonSearchService {
  JsonSearchService({
    SearchStrategy? strategy,
    SearchMatchFinder? matchFinder,
    SearchProgressTracker? progressTracker,
    this.processingPolicy = DiagnosticProcessingPolicy.balanced,
  }) : _strategy = strategy,
       _matchFinder = matchFinder ?? DefaultSearchMatchFinder(),
       _progressTracker = progressTracker {
    processingPolicy.validate();
  }

  final SearchStrategy? _strategy;
  final SearchMatchFinder _matchFinder;
  final SearchProgressTracker? _progressTracker;
  final DiagnosticProcessingPolicy processingPolicy;

  /// Main search method using strategy pattern
  Future<List<SearchResult>> searchInNodes({
    required UnmodifiableListView<NodeViewModelState> allNodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    final effectiveStrategy =
        _strategy ??
        SearchStrategyFactory.createStrategy(
          nodeCount: allNodes.length,
          searchTermLength: searchTerm.length,
          matchFinder: _matchFinder,
          progressTracker: _progressTracker,
          processingPolicy: processingPolicy,
        );

    return effectiveStrategy.search(
      nodes: allNodes,
      searchTerm: searchTerm,
      isMounted: isMounted,
      onProgressUpdate: onProgressUpdate,
    );
  }
}
