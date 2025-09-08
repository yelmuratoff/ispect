import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ispect/src/features/json_viewer/services/json_object_pool.dart';

/// Interface for performance monitoring following SOLID principles
abstract class PerformanceMonitor {
  void startOperation(String operationName);
  void endOperation(String operationName);
  void recordMetric(String metricName, double value);
  Map<String, double> getMetrics();
  void clearMetrics();
}

/// Interface for memory tracking
abstract class MemoryTracker {
  void trackMemoryUsage(String context);
  void recordAllocation(String type, int size);
  void recordDeallocation(String type, int size);
  Map<String, int> getMemoryStats();
  void clearMemoryStats();
}

/// Interface for operation timing
abstract class OperationTimer {
  void startTimer(String operation);
  Duration? endTimer(String operation);
  Map<String, Duration> getTimings();
  void clearTimings();
}

/// Interface for performance alerting
abstract class PerformanceAlerter {
  void setThreshold(String metric, double threshold);
  void checkThresholds(Map<String, double> metrics);
  List<String> getAlerts();
  void clearAlerts();
}

/// Consolidated performance management interface
abstract class UniversalPerformanceManager
    implements
        PerformanceMonitor,
        MemoryTracker,
        OperationTimer,
        PerformanceAlerter {
  void configure({
    bool enableMetrics = true,
    bool enableMemoryTracking = true,
    bool enableTiming = true,
    bool enableAlerting = false,
  });

  void dumpPerformanceReport();
}

/// Concrete implementation of performance management with DI support
class JsonPerformanceManager implements UniversalPerformanceManager {
  JsonPerformanceManager({
    UniversalObjectPool? objectPool,
    bool enableMetrics = true,
    bool enableMemoryTracking = true,
    bool enableTiming = true,
    bool enableAlerting = false,
  }) : _objectPool = objectPool ?? JsonObjectPool.instance {
    configure(
      enableMetrics: enableMetrics,
      enableMemoryTracking: enableMemoryTracking,
      enableTiming: enableTiming,
      enableAlerting: enableAlerting,
    );
  }

  final UniversalObjectPool _objectPool;

  // Configuration flags
  bool _enableMetrics = true;
  bool _enableMemoryTracking = true;
  bool _enableTiming = true;
  bool _enableAlerting = false;

  // Performance tracking data
  final Map<String, double> _metrics = <String, double>{};
  final Map<String, int> _memoryStats = <String, int>{};
  final Map<String, Stopwatch> _activeTimers = <String, Stopwatch>{};
  final Map<String, Duration> _completedTimings = <String, Duration>{};
  final Map<String, double> _alertThresholds = <String, double>{};
  final List<String> _alerts = <String>[];

  // Common operation names
  static const String searchOperation = 'json_search';
  static const String flattenOperation = 'json_flatten';
  static const String expandOperation = 'node_expand';
  static const String renderOperation = 'widget_render';
  static const String cacheOperation = 'cache_operation';

  @override
  void configure({
    bool enableMetrics = true,
    bool enableMemoryTracking = true,
    bool enableTiming = true,
    bool enableAlerting = false,
  }) {
    _enableMetrics = enableMetrics;
    _enableMemoryTracking = enableMemoryTracking;
    _enableTiming = enableTiming;
    _enableAlerting = enableAlerting;

    // Set default thresholds if alerting is enabled
    if (_enableAlerting) {
      _setDefaultThresholds();
    }
  }

  void _setDefaultThresholds() {
    setThreshold('${searchOperation}_duration_ms', 500);
    setThreshold('${flattenOperation}_duration_ms', 200);
    setThreshold('${expandOperation}_duration_ms', 50);
    setThreshold('${renderOperation}_duration_ms', 100);
    setThreshold('memory_usage_mb', 100);
  }

  // PerformanceMonitor implementation
  @override
  void startOperation(String operationName) {
    if (!_enableTiming) return;
    startTimer(operationName);
  }

  @override
  void endOperation(String operationName) {
    if (!_enableTiming) return;

    final duration = endTimer(operationName);
    if (duration != null) {
      final durationMs = duration.inMicroseconds / 1000.0;
      recordMetric('${operationName}_duration_ms', durationMs);

      if (_enableAlerting) {
        checkThresholds({
          '${operationName}_duration_ms': durationMs,
        });
      }
    }
  }

  @override
  void recordMetric(String metricName, double value) {
    if (!_enableMetrics) return;
    _metrics[metricName] = value;
  }

  @override
  Map<String, double> getMetrics() => Map<String, double>.from(_metrics);

  @override
  void clearMetrics() => _metrics.clear();

  // MemoryTracker implementation
  @override
  void trackMemoryUsage(String context) {
    if (!_enableMemoryTracking) return;

    // Estimate memory usage based on object pool statistics
    final poolStats = _objectPool.getPoolStatistics();
    var totalObjects = 0;
    for (final count in poolStats.values) {
      totalObjects += count;
    }

    // Rough estimation: 100 bytes per pooled object
    final estimatedBytes = totalObjects * 100;
    recordAllocation('${context}_pool_memory', estimatedBytes);
  }

  @override
  void recordAllocation(String type, int size) {
    if (!_enableMemoryTracking) return;
    _memoryStats[type] = (_memoryStats[type] ?? 0) + size;
  }

  @override
  void recordDeallocation(String type, int size) {
    if (!_enableMemoryTracking) return;
    _memoryStats[type] = (_memoryStats[type] ?? 0) - size;
  }

  @override
  Map<String, int> getMemoryStats() => Map<String, int>.from(_memoryStats);

  @override
  void clearMemoryStats() => _memoryStats.clear();

  // OperationTimer implementation
  @override
  void startTimer(String operation) {
    if (!_enableTiming) return;

    final stopwatch = Stopwatch()..start();
    _activeTimers[operation] = stopwatch;
  }

  @override
  Duration? endTimer(String operation) {
    if (!_enableTiming) return null;

    final stopwatch = _activeTimers.remove(operation);
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsed;
      _completedTimings[operation] = duration;
      return duration;
    }
    return null;
  }

  @override
  Map<String, Duration> getTimings() =>
      Map<String, Duration>.from(_completedTimings);

  @override
  void clearTimings() {
    _activeTimers.clear();
    _completedTimings.clear();
  }

  // PerformanceAlerter implementation
  @override
  void setThreshold(String metric, double threshold) {
    if (!_enableAlerting) return;
    _alertThresholds[metric] = threshold;
  }

  @override
  void checkThresholds(Map<String, double> metrics) {
    if (!_enableAlerting) return;

    for (final entry in metrics.entries) {
      final threshold = _alertThresholds[entry.key];
      if (threshold != null && entry.value > threshold) {
        final alert = 'ALERT: ${entry.key} = ${entry.value.toStringAsFixed(2)} '
            'exceeds threshold ${threshold.toStringAsFixed(2)}';
        _alerts.add(alert);

        if (kDebugMode) {
          debugPrint('[JsonPerformanceManager] $alert');
        }
      }
    }
  }

  @override
  List<String> getAlerts() => List<String>.from(_alerts);

  @override
  void clearAlerts() => _alerts.clear();

  @override
  void dumpPerformanceReport() {
    if (!kDebugMode) return;

    final report = StringBuffer()
      ..writeln('=== JSON Viewer Performance Report ===');

    if (_enableMetrics && _metrics.isNotEmpty) {
      report.writeln('\n--- Metrics ---');
      _metrics.forEach((key, value) {
        report.writeln('$key: ${value.toStringAsFixed(2)}');
      });
    }

    if (_enableTiming && _completedTimings.isNotEmpty) {
      report.writeln('\n--- Timings ---');
      _completedTimings.forEach((key, duration) {
        report.writeln('$key: ${duration.inMilliseconds}ms');
      });
    }

    if (_enableMemoryTracking && _memoryStats.isNotEmpty) {
      report.writeln('\n--- Memory Stats ---');
      _memoryStats.forEach((key, size) {
        final sizeKb = (size / 1024).toStringAsFixed(2);
        report.writeln('$key: ${sizeKb}KB');
      });
    }

    if (_enableAlerting && _alerts.isNotEmpty) {
      report.writeln('\n--- Alerts ---');

      _alerts.forEach(report.writeln);
    }

    final poolStats = _objectPool.getPoolStatistics();
    report.writeln('\n--- Object Pool Stats ---');
    poolStats.forEach((key, count) {
      report.writeln('$key: $count objects');
    });

    report.writeln('==================================');
    debugPrint(report.toString());
  }

  /// Convenience method for measuring operation performance
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? context,
  }) async {
    startOperation(operationName);

    if (context != null && _enableMemoryTracking) {
      trackMemoryUsage(operationName);
    }

    try {
      final result = await operation();
      return result;
    } finally {
      endOperation(operationName);
    }
  }

  /// Convenience method for measuring synchronous operations
  T measureSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? context,
  }) {
    startOperation(operationName);

    if (context != null && _enableMemoryTracking) {
      trackMemoryUsage(operationName);
    }

    try {
      final result = operation();
      return result;
    } finally {
      endOperation(operationName);
    }
  }

  /// Batch operation for recording multiple metrics at once
  void recordBatchMetrics(Map<String, double> metrics) {
    if (!_enableMetrics) return;

    _metrics.addAll(metrics);

    if (_enableAlerting) {
      checkThresholds(metrics);
    }
  }

  /// Reset all performance data
  void reset() {
    clearMetrics();
    clearMemoryStats();
    clearTimings();
    clearAlerts();
  }

  /// Get a summary of current performance state
  Map<String, dynamic> getPerformanceSummary() => {
        'metrics_count': _metrics.length,
        'memory_tracked_types': _memoryStats.length,
        'active_timers': _activeTimers.length,
        'completed_timings': _completedTimings.length,
        'alerts_count': _alerts.length,
        'object_pool_stats': _objectPool.getPoolStatistics(),
        'configuration': {
          'metrics_enabled': _enableMetrics,
          'memory_tracking_enabled': _enableMemoryTracking,
          'timing_enabled': _enableTiming,
          'alerting_enabled': _enableAlerting,
        },
      };
}

/// Factory for creating performance managers with dependency injection
class PerformanceManagerFactory {
  static UniversalPerformanceManager createManager({
    UniversalObjectPool? objectPool,
    bool enableMetrics = true,
    bool enableMemoryTracking = true,
    bool enableTiming = true,
    bool enableAlerting = false,
  }) =>
      JsonPerformanceManager(
        objectPool: objectPool ?? JsonObjectPool.instance,
        enableMetrics: enableMetrics,
        enableMemoryTracking: enableMemoryTracking,
        enableTiming: enableTiming,
        enableAlerting: enableAlerting,
      );

  /// Create a production-optimized manager
  static UniversalPerformanceManager createProductionManager() => createManager(
        enableMetrics: false,
        enableMemoryTracking: false,
        enableTiming: false,
      );

  /// Create a development manager with full monitoring
  static UniversalPerformanceManager createDevelopmentManager() =>
      createManager(
        enableAlerting: true,
      );
}
