import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:meta/meta.dart';

/// Cooperative scheduling used by diagnostic import and export operations.
@immutable
final class DiagnosticProcessingPolicy {
  const DiagnosticProcessingPolicy({
    this.exportChunkSize = 50,
    this.importChunkSize = 25,
    this.yieldEveryExportChunks = 10,
    this.yieldEveryImportChunks = 4,
    this.backgroundProcessingThresholdBytes = 256 * 1024,
    this.backgroundExportEntryThreshold = 50,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.searchYieldInterval = const Duration(milliseconds: 80),
    this.shortSearchYieldInterval = const Duration(milliseconds: 150),
    this.searchProgressThreshold = 15,
    this.shortSearchProgressThreshold = 20,
    this.searchBatchSize = 200,
    this.largeSearchBatchSize = 120,
    this.veryLargeSearchBatchSize = 80,
    this.shortSearchBatchSize = 300,
    this.largeSearchNodeThreshold = 5000,
    this.veryLargeSearchNodeThreshold = 10000,
    this.viewerBuildYieldThreshold = 1000,
    this.viewerBuildYieldDelay = const Duration(milliseconds: 5),
  });

  /// Scheduling that preserves the 7.0 import and export behavior.
  static const balanced = DiagnosticProcessingPolicy();

  /// Yields more frequently to favor UI responsiveness.
  static const responsive = DiagnosticProcessingPolicy(
    exportChunkSize: 25,
    importChunkSize: 10,
    yieldEveryExportChunks: 2,
    yieldEveryImportChunks: 1,
    backgroundProcessingThresholdBytes: 64 * 1024,
    backgroundExportEntryThreshold: 25,
    searchDebounce: Duration(milliseconds: 200),
    searchYieldInterval: Duration(milliseconds: 40),
    shortSearchYieldInterval: Duration(milliseconds: 75),
    searchProgressThreshold: 8,
    shortSearchProgressThreshold: 10,
    searchBatchSize: 100,
    largeSearchBatchSize: 60,
    veryLargeSearchBatchSize: 40,
    shortSearchBatchSize: 150,
    viewerBuildYieldThreshold: 500,
    viewerBuildYieldDelay: Duration(milliseconds: 1),
  );

  /// Processes larger batches when throughput matters more than latency.
  static const throughput = DiagnosticProcessingPolicy(
    exportChunkSize: 200,
    importChunkSize: 100,
    yieldEveryExportChunks: 20,
    yieldEveryImportChunks: 10,
    backgroundProcessingThresholdBytes: 1024 * 1024,
    backgroundExportEntryThreshold: 200,
    searchDebounce: Duration(milliseconds: 400),
    searchYieldInterval: Duration(milliseconds: 160),
    shortSearchYieldInterval: Duration(milliseconds: 250),
    searchProgressThreshold: 50,
    shortSearchProgressThreshold: 75,
    searchBatchSize: 500,
    largeSearchBatchSize: 350,
    veryLargeSearchBatchSize: 250,
    shortSearchBatchSize: 750,
    viewerBuildYieldThreshold: 5000,
    viewerBuildYieldDelay: Duration.zero,
  );

  static const int maxAllowedChunkSize = 10000;
  static const int maxAllowedYieldInterval = 10000;
  static const int maxAllowedBackgroundProcessingThresholdBytes =
      64 * 1024 * 1024;
  static const int maxAllowedSearchBatchSize = 10000;
  static const int maxAllowedSearchProgressThreshold = 10000;
  static const int maxAllowedSearchNodeThreshold = 1000000;
  static const Duration maxAllowedDelay = Duration(seconds: 10);

  final int exportChunkSize;
  final int importChunkSize;
  final int yieldEveryExportChunks;
  final int yieldEveryImportChunks;
  final int backgroundProcessingThresholdBytes;
  final int backgroundExportEntryThreshold;
  final Duration searchDebounce;
  final Duration searchYieldInterval;
  final Duration shortSearchYieldInterval;
  final int searchProgressThreshold;
  final int shortSearchProgressThreshold;
  final int searchBatchSize;
  final int largeSearchBatchSize;
  final int veryLargeSearchBatchSize;
  final int shortSearchBatchSize;
  final int largeSearchNodeThreshold;
  final int veryLargeSearchNodeThreshold;
  final int viewerBuildYieldThreshold;
  final Duration viewerBuildYieldDelay;

  /// Restores a validated scheduling policy from [toMap] output.
  // ignore: sort_constructors_first
  factory DiagnosticProcessingPolicy.fromMap(Map<String, Object?> map) {
    const defaults = balanced;
    final policy = DiagnosticProcessingPolicy(
      exportChunkSize:
          _readInt(map, 'export_chunk_size', defaults.exportChunkSize),
      importChunkSize:
          _readInt(map, 'import_chunk_size', defaults.importChunkSize),
      yieldEveryExportChunks: _readInt(
        map,
        'yield_every_export_chunks',
        defaults.yieldEveryExportChunks,
      ),
      yieldEveryImportChunks: _readInt(
        map,
        'yield_every_import_chunks',
        defaults.yieldEveryImportChunks,
      ),
      backgroundProcessingThresholdBytes: _readInt(
        map,
        'background_processing_threshold_bytes',
        defaults.backgroundProcessingThresholdBytes,
      ),
      backgroundExportEntryThreshold: _readInt(
        map,
        'background_export_entry_threshold',
        defaults.backgroundExportEntryThreshold,
      ),
      searchDebounce: Duration(
        microseconds: _readInt(
          map,
          'search_debounce_microseconds',
          defaults.searchDebounce.inMicroseconds,
        ),
      ),
      searchYieldInterval: Duration(
        microseconds: _readInt(
          map,
          'search_yield_interval_microseconds',
          defaults.searchYieldInterval.inMicroseconds,
        ),
      ),
      shortSearchYieldInterval: Duration(
        microseconds: _readInt(
          map,
          'short_search_yield_interval_microseconds',
          defaults.shortSearchYieldInterval.inMicroseconds,
        ),
      ),
      searchProgressThreshold: _readInt(
        map,
        'search_progress_threshold',
        defaults.searchProgressThreshold,
      ),
      shortSearchProgressThreshold: _readInt(
        map,
        'short_search_progress_threshold',
        defaults.shortSearchProgressThreshold,
      ),
      searchBatchSize:
          _readInt(map, 'search_batch_size', defaults.searchBatchSize),
      largeSearchBatchSize: _readInt(
        map,
        'large_search_batch_size',
        defaults.largeSearchBatchSize,
      ),
      veryLargeSearchBatchSize: _readInt(
        map,
        'very_large_search_batch_size',
        defaults.veryLargeSearchBatchSize,
      ),
      shortSearchBatchSize: _readInt(
        map,
        'short_search_batch_size',
        defaults.shortSearchBatchSize,
      ),
      largeSearchNodeThreshold: _readInt(
        map,
        'large_search_node_threshold',
        defaults.largeSearchNodeThreshold,
      ),
      veryLargeSearchNodeThreshold: _readInt(
        map,
        'very_large_search_node_threshold',
        defaults.veryLargeSearchNodeThreshold,
      ),
      viewerBuildYieldThreshold: _readInt(
        map,
        'viewer_build_yield_threshold',
        defaults.viewerBuildYieldThreshold,
      ),
      viewerBuildYieldDelay: Duration(
        microseconds: _readInt(
          map,
          'viewer_build_yield_delay_microseconds',
          defaults.viewerBuildYieldDelay.inMicroseconds,
        ),
      ),
    );
    return policy..validate();
  }

  /// Serializes every scheduling value, including exact duration precision.
  Map<String, int> toMap() => {
        'export_chunk_size': exportChunkSize,
        'import_chunk_size': importChunkSize,
        'yield_every_export_chunks': yieldEveryExportChunks,
        'yield_every_import_chunks': yieldEveryImportChunks,
        'background_processing_threshold_bytes':
            backgroundProcessingThresholdBytes,
        'background_export_entry_threshold': backgroundExportEntryThreshold,
        'search_debounce_microseconds': searchDebounce.inMicroseconds,
        'search_yield_interval_microseconds':
            searchYieldInterval.inMicroseconds,
        'short_search_yield_interval_microseconds':
            shortSearchYieldInterval.inMicroseconds,
        'search_progress_threshold': searchProgressThreshold,
        'short_search_progress_threshold': shortSearchProgressThreshold,
        'search_batch_size': searchBatchSize,
        'large_search_batch_size': largeSearchBatchSize,
        'very_large_search_batch_size': veryLargeSearchBatchSize,
        'short_search_batch_size': shortSearchBatchSize,
        'large_search_node_threshold': largeSearchNodeThreshold,
        'very_large_search_node_threshold': veryLargeSearchNodeThreshold,
        'viewer_build_yield_threshold': viewerBuildYieldThreshold,
        'viewer_build_yield_delay_microseconds':
            viewerBuildYieldDelay.inMicroseconds,
      };

  /// Throws [ArgumentError] when scheduling would be unsafe or unbounded.
  void validate() {
    _requireRange(exportChunkSize, 'exportChunkSize', maxAllowedChunkSize);
    _requireRange(importChunkSize, 'importChunkSize', maxAllowedChunkSize);
    _requireRange(
      yieldEveryExportChunks,
      'yieldEveryExportChunks',
      maxAllowedYieldInterval,
    );
    _requireRange(
      yieldEveryImportChunks,
      'yieldEveryImportChunks',
      maxAllowedYieldInterval,
    );
    _requireRange(
      backgroundProcessingThresholdBytes,
      'backgroundProcessingThresholdBytes',
      maxAllowedBackgroundProcessingThresholdBytes,
    );
    _requireRange(
      backgroundExportEntryThreshold,
      'backgroundExportEntryThreshold',
      DiagnosticResourceLimits.maxAllowedExportEntries,
    );
    _requireDuration(searchDebounce, 'searchDebounce');
    _requireDuration(searchYieldInterval, 'searchYieldInterval');
    _requireDuration(
      shortSearchYieldInterval,
      'shortSearchYieldInterval',
    );
    _requireRange(
      searchProgressThreshold,
      'searchProgressThreshold',
      maxAllowedSearchProgressThreshold,
    );
    _requireRange(
      shortSearchProgressThreshold,
      'shortSearchProgressThreshold',
      maxAllowedSearchProgressThreshold,
    );
    _requireRange(
      searchBatchSize,
      'searchBatchSize',
      maxAllowedSearchBatchSize,
    );
    _requireRange(
      largeSearchBatchSize,
      'largeSearchBatchSize',
      maxAllowedSearchBatchSize,
    );
    _requireRange(
      veryLargeSearchBatchSize,
      'veryLargeSearchBatchSize',
      maxAllowedSearchBatchSize,
    );
    _requireRange(
      shortSearchBatchSize,
      'shortSearchBatchSize',
      maxAllowedSearchBatchSize,
    );
    _requireRange(
      largeSearchNodeThreshold,
      'largeSearchNodeThreshold',
      maxAllowedSearchNodeThreshold,
    );
    _requireRange(
      veryLargeSearchNodeThreshold,
      'veryLargeSearchNodeThreshold',
      maxAllowedSearchNodeThreshold,
    );
    _requireRange(
      viewerBuildYieldThreshold,
      'viewerBuildYieldThreshold',
      maxAllowedSearchNodeThreshold,
    );
    _requireDuration(viewerBuildYieldDelay, 'viewerBuildYieldDelay');
    if (veryLargeSearchNodeThreshold <= largeSearchNodeThreshold) {
      throw ArgumentError.value(
        veryLargeSearchNodeThreshold,
        'veryLargeSearchNodeThreshold',
        'must be greater than largeSearchNodeThreshold',
      );
    }
  }

  DiagnosticProcessingPolicy copyWith({
    int? exportChunkSize,
    int? importChunkSize,
    int? yieldEveryExportChunks,
    int? yieldEveryImportChunks,
    int? backgroundProcessingThresholdBytes,
    int? backgroundExportEntryThreshold,
    Duration? searchDebounce,
    Duration? searchYieldInterval,
    Duration? shortSearchYieldInterval,
    int? searchProgressThreshold,
    int? shortSearchProgressThreshold,
    int? searchBatchSize,
    int? largeSearchBatchSize,
    int? veryLargeSearchBatchSize,
    int? shortSearchBatchSize,
    int? largeSearchNodeThreshold,
    int? veryLargeSearchNodeThreshold,
    int? viewerBuildYieldThreshold,
    Duration? viewerBuildYieldDelay,
  }) =>
      DiagnosticProcessingPolicy(
        exportChunkSize: exportChunkSize ?? this.exportChunkSize,
        importChunkSize: importChunkSize ?? this.importChunkSize,
        yieldEveryExportChunks:
            yieldEveryExportChunks ?? this.yieldEveryExportChunks,
        yieldEveryImportChunks:
            yieldEveryImportChunks ?? this.yieldEveryImportChunks,
        backgroundProcessingThresholdBytes:
            backgroundProcessingThresholdBytes ??
                this.backgroundProcessingThresholdBytes,
        backgroundExportEntryThreshold: backgroundExportEntryThreshold ??
            this.backgroundExportEntryThreshold,
        searchDebounce: searchDebounce ?? this.searchDebounce,
        searchYieldInterval: searchYieldInterval ?? this.searchYieldInterval,
        shortSearchYieldInterval:
            shortSearchYieldInterval ?? this.shortSearchYieldInterval,
        searchProgressThreshold:
            searchProgressThreshold ?? this.searchProgressThreshold,
        shortSearchProgressThreshold:
            shortSearchProgressThreshold ?? this.shortSearchProgressThreshold,
        searchBatchSize: searchBatchSize ?? this.searchBatchSize,
        largeSearchBatchSize: largeSearchBatchSize ?? this.largeSearchBatchSize,
        veryLargeSearchBatchSize:
            veryLargeSearchBatchSize ?? this.veryLargeSearchBatchSize,
        shortSearchBatchSize: shortSearchBatchSize ?? this.shortSearchBatchSize,
        largeSearchNodeThreshold:
            largeSearchNodeThreshold ?? this.largeSearchNodeThreshold,
        veryLargeSearchNodeThreshold:
            veryLargeSearchNodeThreshold ?? this.veryLargeSearchNodeThreshold,
        viewerBuildYieldThreshold:
            viewerBuildYieldThreshold ?? this.viewerBuildYieldThreshold,
        viewerBuildYieldDelay:
            viewerBuildYieldDelay ?? this.viewerBuildYieldDelay,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticProcessingPolicy &&
          other.exportChunkSize == exportChunkSize &&
          other.importChunkSize == importChunkSize &&
          other.yieldEveryExportChunks == yieldEveryExportChunks &&
          other.yieldEveryImportChunks == yieldEveryImportChunks &&
          other.backgroundProcessingThresholdBytes ==
              backgroundProcessingThresholdBytes &&
          other.backgroundExportEntryThreshold ==
              backgroundExportEntryThreshold &&
          other.searchDebounce == searchDebounce &&
          other.searchYieldInterval == searchYieldInterval &&
          other.shortSearchYieldInterval == shortSearchYieldInterval &&
          other.searchProgressThreshold == searchProgressThreshold &&
          other.shortSearchProgressThreshold == shortSearchProgressThreshold &&
          other.searchBatchSize == searchBatchSize &&
          other.largeSearchBatchSize == largeSearchBatchSize &&
          other.veryLargeSearchBatchSize == veryLargeSearchBatchSize &&
          other.shortSearchBatchSize == shortSearchBatchSize &&
          other.largeSearchNodeThreshold == largeSearchNodeThreshold &&
          other.veryLargeSearchNodeThreshold == veryLargeSearchNodeThreshold &&
          other.viewerBuildYieldThreshold == viewerBuildYieldThreshold &&
          other.viewerBuildYieldDelay == viewerBuildYieldDelay;

  @override
  int get hashCode => Object.hashAll([
        exportChunkSize,
        importChunkSize,
        yieldEveryExportChunks,
        yieldEveryImportChunks,
        backgroundProcessingThresholdBytes,
        backgroundExportEntryThreshold,
        searchDebounce,
        searchYieldInterval,
        shortSearchYieldInterval,
        searchProgressThreshold,
        shortSearchProgressThreshold,
        searchBatchSize,
        largeSearchBatchSize,
        veryLargeSearchBatchSize,
        shortSearchBatchSize,
        largeSearchNodeThreshold,
        veryLargeSearchNodeThreshold,
        viewerBuildYieldThreshold,
        viewerBuildYieldDelay,
      ]);
}

int _readInt(Map<String, Object?> map, String key, int fallback) {
  final value = map[key];
  if (value == null) return fallback;
  if (value is int) return value;
  throw ArgumentError.value(value, key, 'must be an integer');
}

void _requireRange(int value, String name, int maximum) {
  if (value < 1 || value > maximum) {
    throw ArgumentError.value(value, name, 'must be between 1 and $maximum');
  }
}

void _requireDuration(Duration value, String name) {
  if (value.isNegative || value > DiagnosticProcessingPolicy.maxAllowedDelay) {
    throw ArgumentError.value(
      value,
      name,
      'must be between Duration.zero and '
      '${DiagnosticProcessingPolicy.maxAllowedDelay}',
    );
  }
}
