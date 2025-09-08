import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// Service responsible for searching within JSON tree structures
class JsonSearchService {
  static const Duration _searchDebounceTime = Duration(milliseconds: 300);

  /// Optimized search algorithm that processes data in batches to avoid UI blocking
  static Future<List<SearchResult>> searchInNodes({
    required UnmodifiableListView<NodeViewModelState> allNodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    if (searchTerm.isEmpty || allNodes.isEmpty) {
      return const <SearchResult>[];
    }

    final normalizedTerm = searchTerm.toLowerCase();

    // Optimize for short search terms in large datasets
    if (allNodes.length > 5000 && searchTerm.length < 3) {
      return _optimizedSearchForShortTerms(
        allNodes: allNodes,
        searchTerm: normalizedTerm,
        isMounted: isMounted,
        onProgressUpdate: onProgressUpdate,
      );
    }

    // Standard batch processing for normal cases
    return _processSearchInBatches(
      allNodes: allNodes,
      searchTerm: normalizedTerm,
      isMounted: isMounted,
      onProgressUpdate: onProgressUpdate,
    );
  }

  /// Fast search for short search terms in large datasets
  static Future<List<SearchResult>> _optimizedSearchForShortTerms({
    required UnmodifiableListView<NodeViewModelState> allNodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    const batchSize = 300;
    final results = <SearchResult>[];
    final totalNodes = allNodes.length;
    var processedCount = 0;

    var nextUIUpdateTime =
        DateTime.now().add(const Duration(milliseconds: 150));
    var resultsFoundSinceLastUpdate = 0;

    while (processedCount < totalNodes && isMounted()) {
      final end = (processedCount + batchSize).clamp(0, totalNodes);
      final batch = allNodes.sublist(processedCount, end);

      for (final node in batch) {
        if (!isMounted()) return results;

        // Process key matches
        _addKeyMatches(node, searchTerm, results);

        // Process value matches for non-root nodes
        if (!node.isRoot) {
          _addValueMatches(node, searchTerm, results);
        }
      }

      processedCount = end;
      resultsFoundSinceLastUpdate += results.length;

      // Check if we should update the UI
      final now = DateTime.now();
      if (now.isAfter(nextUIUpdateTime) ||
          resultsFoundSinceLastUpdate >= 20 ||
          processedCount >= totalNodes) {
        onProgressUpdate?.call();
        nextUIUpdateTime = now.add(const Duration(milliseconds: 150));
        resultsFoundSinceLastUpdate = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }

    return results;
  }

  /// Standard batch processing for normal search cases
  static Future<List<SearchResult>> _processSearchInBatches({
    required UnmodifiableListView<NodeViewModelState> allNodes,
    required String searchTerm,
    required bool Function() isMounted,
    void Function()? onProgressUpdate,
  }) async {
    final results = <SearchResult>[];
    var processedCount = 0;

    // Adjust batch size based on node complexity
    final batchSize = allNodes.length > 10000
        ? 80
        : allNodes.length > 5000
            ? 120
            : 200;

    final totalNodes = allNodes.length;
    var nextUIUpdateTime = DateTime.now().add(const Duration(milliseconds: 80));
    var resultsFoundSinceLastUpdate = 0;

    while (processedCount < totalNodes && isMounted()) {
      final end = (processedCount + batchSize).clamp(0, totalNodes);
      final batch = allNodes.sublist(processedCount, end);
      final initialResultsCount = results.length;

      for (final node in batch) {
        if (!isMounted()) return results;

        // Process key matches
        _addKeyMatches(node, searchTerm, results);

        // Process value matches for non-root nodes
        if (!node.isRoot) {
          _addValueMatches(node, searchTerm, results);
        }
      }

      processedCount = end;
      resultsFoundSinceLastUpdate += results.length - initialResultsCount;

      // Check if we should update the UI
      final now = DateTime.now();
      if (now.isAfter(nextUIUpdateTime) ||
          resultsFoundSinceLastUpdate >= 15 ||
          processedCount >= totalNodes) {
        onProgressUpdate?.call();
        nextUIUpdateTime = now.add(const Duration(milliseconds: 80));
        resultsFoundSinceLastUpdate = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }

    return results;
  }

  /// Add key matches to results
  static void _addKeyMatches(
    NodeViewModelState node,
    String searchTerm,
    List<SearchResult> results,
  ) {
    final nodeKey = node.key;
    if (nodeKey.isNotEmpty) {
      final keyLower = nodeKey.toLowerCase();
      if (keyLower.contains(searchTerm)) {
        final keyMatches = findAllOccurrences(keyLower, searchTerm);
        for (final matchIndex in keyMatches) {
          results.add(
            SearchResult(
              node,
              matchLocation: SearchMatchLocation.key,
              matchIndex: matchIndex,
            ),
          );
        }
      }
    }
  }

  /// Add value matches to results
  static void _addValueMatches(
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
          final valueMatches = findAllOccurrences(valueLower, searchTerm);
          for (final matchIndex in valueMatches) {
            results.add(
              SearchResult(
                node,
                matchLocation: SearchMatchLocation.value,
                matchIndex: matchIndex,
              ),
            );
          }
        }
      }
    }
  }

  /// Fast algorithm to find all occurrences without using RegExp
  static List<int> findAllOccurrences(String text, String pattern) {
    if (text.isEmpty || pattern.isEmpty) {
      return const <int>[];
    }

    final indices = <int>[];
    var startIndex = 0;

    while (true) {
      final index = text.indexOf(pattern, startIndex);
      if (index == -1) break;
      indices.add(index);
      startIndex = index + 1;
    }

    return indices;
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
}
