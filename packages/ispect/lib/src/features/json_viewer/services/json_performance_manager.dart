import 'dart:async';
import 'dart:collection';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_cache_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_memory_optimizer.dart';
import 'package:ispect/src/features/json_viewer/services/json_object_pool.dart';

/// Coordinator service that manages all JSON viewer optimizations
class JsonPerformanceManager {
  JsonPerformanceManager(this._cacheService);

  final JsonViewerCacheService _cacheService;
  JsonOptimizationReport? _lastReport;
  JsonBatchConfig? _batchConfig;
  Timer? _cleanupTimer;

  /// Initialize performance optimizations based on JSON structure
  void initializeOptimizations(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    _lastReport = JsonMemoryOptimizer.analyzeJsonStructure(allNodes);
    _batchConfig = JsonMemoryOptimizer.calculateOptimalBatchSizes(_lastReport!);

    _schedulePeriodicCleanup();
  }

  /// Get the current optimization report
  JsonOptimizationReport? get optimizationReport => _lastReport;

  /// Get the current batch configuration
  JsonBatchConfig? get batchConfig => _batchConfig;

  /// Perform maintenance based on current usage patterns
  void performMaintenance() {
    if (_lastReport == null) return;

    // Clean up caches based on current load
    final cacheThreshold = _batchConfig?.cacheMaintenanceThreshold ?? 1000;
    _cacheService.maintainCaches(
      maxSearchEntries: cacheThreshold ~/ 10,
      maxNodeEntries: cacheThreshold,
    );

    // Clean up object pools if they're getting large
    final poolSizes = JsonObjectPool.instance.getPoolSizes();
    final totalPoolSize = poolSizes.values.fold(0, (sum, size) => sum + size);

    if (totalPoolSize > 50) {
      JsonObjectPool.instance.clearPools();
    }
  }

  /// Get recommended settings for UI rendering
  Map<String, dynamic> getRenderingSettings() {
    if (_lastReport == null || _batchConfig == null) {
      return _getDefaultSettings();
    }

    return {
      'useVirtualization':
          JsonMemoryOptimizer.shouldUseVirtualization(_lastReport!),
      'batchSize': _batchConfig!.renderBatchSize,
      'debounceMs': _batchConfig!.debounceTimeMs,
      'enableLazyLoading':
          _lastReport!.isLargeJson || _lastReport!.hasDeepNesting,
      'maxInitialDepth': _lastReport!.isLargeJson ? 3 : 5,
      'enableProgressIndicator': _lastReport!.totalNodes > 2000,
    };
  }

  /// Get performance metrics for debugging
  Map<String, dynamic> getPerformanceMetrics() => {
        'report': _lastReport?.toString() ?? 'Not initialized',
        'batchConfig': _batchConfig != null
            ? {
                'searchBatch': _batchConfig!.searchBatchSize,
                'renderBatch': _batchConfig!.renderBatchSize,
                'debounce': _batchConfig!.debounceTimeMs,
              }
            : 'Not initialized',
        'cacheStats': {
          'searchEntries': _cacheService.searchMatchesCache.length,
          'nodeEntries': _cacheService.visibleChildrenCountCache.length,
        },
        'poolStats': JsonObjectPool.instance.getPoolSizes(),
      };

  /// Schedule periodic cleanup based on JSON size
  void _schedulePeriodicCleanup() {
    _cleanupTimer?.cancel();

    if (_lastReport != null) {
      final interval =
          JsonMemoryOptimizer.calculateCleanupInterval(_lastReport!);
      _cleanupTimer = Timer.periodic(interval, (_) => performMaintenance());
    }
  }

  Map<String, dynamic> _getDefaultSettings() => {
        'useVirtualization': false,
        'batchSize': 50,
        'debounceMs': 300,
        'enableLazyLoading': false,
        'maxInitialDepth': 10,
        'enableProgressIndicator': false,
      };

  /// Dispose of resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _lastReport = null;
    _batchConfig = null;

    // Final cleanup
    JsonObjectPool.instance.clearPools();
  }
}
