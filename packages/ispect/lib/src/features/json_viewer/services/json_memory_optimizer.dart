import 'dart:collection';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// Service responsible for memory optimization in JSON viewer
class JsonMemoryOptimizer {
  static const int _largeJsonThreshold = 5000;
  static const int _deepNestingThreshold = 10;

  /// Analyzes JSON structure and returns optimization recommendations
  static JsonOptimizationReport analyzeJsonStructure(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    var maxDepth = 0;
    var largeArraysCount = 0;
    var deepObjectsCount = 0;
    var totalLeafNodes = 0;

    for (final node in allNodes) {
      if (node.treeDepth > maxDepth) {
        maxDepth = node.treeDepth;
      }

      if (node.isArray && node.children.length > 100) {
        largeArraysCount++;
      }

      if (node.treeDepth > _deepNestingThreshold) {
        deepObjectsCount++;
      }

      if (!node.isRoot) {
        totalLeafNodes++;
      }
    }

    return JsonOptimizationReport(
      totalNodes: allNodes.length,
      maxDepth: maxDepth,
      largeArraysCount: largeArraysCount,
      deepObjectsCount: deepObjectsCount,
      totalLeafNodes: totalLeafNodes,
      isLargeJson: allNodes.length > _largeJsonThreshold,
      hasDeepNesting: maxDepth > _deepNestingThreshold,
    );
  }

  /// Suggests optimal batch sizes based on JSON structure
  static JsonBatchConfig calculateOptimalBatchSizes(
    JsonOptimizationReport report,
  ) {
    int searchBatchSize;
    int renderBatchSize;
    int cacheMaintenanceThreshold;

    if (report.isLargeJson) {
      // For large JSON files, use smaller batches to prevent UI blocking
      searchBatchSize = report.hasDeepNesting ? 50 : 80;
      renderBatchSize = 20;
      cacheMaintenanceThreshold = 2000;
    } else if (report.hasDeepNesting) {
      // For deeply nested structures, use smaller batches
      searchBatchSize = 100;
      renderBatchSize = 30;
      cacheMaintenanceThreshold = 1500;
    } else {
      // For normal structures, use standard batches
      searchBatchSize = 200;
      renderBatchSize = 50;
      cacheMaintenanceThreshold = 1000;
    }

    return JsonBatchConfig(
      searchBatchSize: searchBatchSize,
      renderBatchSize: renderBatchSize,
      cacheMaintenanceThreshold: cacheMaintenanceThreshold,
      debounceTimeMs: report.isLargeJson ? 400 : 300,
    );
  }

  /// Optimizes display nodes by lazy loading deep structures
  static List<NodeViewModelState> optimizeDisplayNodes(
    List<NodeViewModelState> displayNodes,
    JsonOptimizationReport report,
  ) {
    if (!report.hasDeepNesting && !report.isLargeJson) {
      return displayNodes;
    }

    // For very large structures, limit initial display to first few levels
    if (report.isLargeJson) {
      return displayNodes.where((node) => node.treeDepth <= 3).toList();
    }

    return displayNodes;
  }

  /// Suggests memory cleanup intervals based on usage patterns
  static Duration calculateCleanupInterval(JsonOptimizationReport report) {
    if (report.isLargeJson) {
      return const Duration(seconds: 30);
    } else if (report.hasDeepNesting) {
      return const Duration(minutes: 1);
    } else {
      return const Duration(minutes: 2);
    }
  }

  /// Determines if virtualization should be enabled
  static bool shouldUseVirtualization(JsonOptimizationReport report) =>
      report.totalNodes > 1000 || report.isLargeJson;
}

/// Report containing JSON structure analysis
class JsonOptimizationReport {
  const JsonOptimizationReport({
    required this.totalNodes,
    required this.maxDepth,
    required this.largeArraysCount,
    required this.deepObjectsCount,
    required this.totalLeafNodes,
    required this.isLargeJson,
    required this.hasDeepNesting,
  });

  final int totalNodes;
  final int maxDepth;
  final int largeArraysCount;
  final int deepObjectsCount;
  final int totalLeafNodes;
  final bool isLargeJson;
  final bool hasDeepNesting;

  @override
  String toString() => 'JsonOptimizationReport('
      'totalNodes: $totalNodes, '
      'maxDepth: $maxDepth, '
      'largeArrays: $largeArraysCount, '
      'isLarge: $isLargeJson, '
      'hasDeepNesting: $hasDeepNesting)';
}

/// Configuration for batch processing
class JsonBatchConfig {
  const JsonBatchConfig({
    required this.searchBatchSize,
    required this.renderBatchSize,
    required this.cacheMaintenanceThreshold,
    required this.debounceTimeMs,
  });

  final int searchBatchSize;
  final int renderBatchSize;
  final int cacheMaintenanceThreshold;
  final int debounceTimeMs;
}
