import 'package:meta/meta.dart';

/// Resource budgets applied while diagnostics are captured and handed off.
///
/// Values may be raised for controlled internal builds, but [validate] keeps
/// them within host-protection ceilings. Output and input bounds cannot be
/// disabled.
@immutable
final class DiagnosticResourceLimits {
  const DiagnosticResourceLimits({
    this.maxCapturedValueBytes = 256 * 1024,
    this.maxLogRecordBytes = 1024 * 1024,
    this.maxExportDocumentBytes = 32 * 1024 * 1024,
    this.maxTraversalDepth = 64,
    this.maxTraversalNodes = 10000,
    this.maxCollectionItems = 1000,
    this.maxImportCharacters = 32 * 1024 * 1024,
    this.maxImportBytes = 32 * 1024 * 1024,
    this.maxImportNodes = 100000,
    this.maxImportEntries = 100000,
    this.maxViewerBytes = 1024 * 1024,
    this.maxViewerNodes = 20000,
    this.maxClipboardBytes = 100000,
    this.maxExportEntries = 5000,
    this.maxExportNodes = 100000,
    this.maxNetworkHeaders = 100,
    this.maxNetworkBodyBytes = 128 * 1024,
    this.maxPendingCorrelations = 1000,
    this.maxStateTraceBytes = 128 * 1024,
    this.maxDatabaseScalarBytes = 4 * 1024,
    this.maxDatabaseDiagnosticsBytes = 16 * 1024,
    this.maxDatabaseMetadataBytes = 24 * 1024,
    this.maxUiDiagnosticBytes = 8 * 1024,
    this.maxSearchQueryBytes = 4096,
    this.maxConsoleStackTraceFrames = 30,
  });

  /// Default policy for useful bounded diagnostics.
  static const balanced = DiagnosticResourceLimits();

  /// Lower-memory policy for long sessions and constrained devices.
  static const constrained = DiagnosticResourceLimits(
    maxCapturedValueBytes: 64 * 1024,
    maxLogRecordBytes: 256 * 1024,
    maxExportDocumentBytes: 8 * 1024 * 1024,
    maxTraversalDepth: 48,
    maxTraversalNodes: 5000,
    maxCollectionItems: 500,
    maxImportCharacters: 8 * 1024 * 1024,
    maxImportBytes: 8 * 1024 * 1024,
    maxImportNodes: 25000,
    maxImportEntries: 25000,
    maxViewerBytes: 512 * 1024,
    maxViewerNodes: 10000,
    maxClipboardBytes: 64 * 1024,
    maxExportEntries: 2000,
    maxExportNodes: 25000,
    maxNetworkBodyBytes: 32 * 1024,
    maxPendingCorrelations: 500,
    maxStateTraceBytes: 32 * 1024,
    maxDatabaseScalarBytes: 2 * 1024,
    maxDatabaseDiagnosticsBytes: 8 * 1024,
    maxDatabaseMetadataBytes: 12 * 1024,
    maxUiDiagnosticBytes: 4 * 1024,
    maxSearchQueryBytes: 2048,
    maxConsoleStackTraceFrames: 15,
  );

  /// Higher-capacity policy for deliberately large internal handoffs.
  static const extended = DiagnosticResourceLimits(
    maxCapturedValueBytes: 1024 * 1024,
    maxLogRecordBytes: 4 * 1024 * 1024,
    maxExportDocumentBytes: 128 * 1024 * 1024,
    maxTraversalDepth: 128,
    maxTraversalNodes: 100000,
    maxCollectionItems: 10000,
    maxImportCharacters: 128 * 1024 * 1024,
    maxImportBytes: 128 * 1024 * 1024,
    maxImportNodes: 500000,
    maxImportEntries: 500000,
    maxViewerBytes: 4 * 1024 * 1024,
    maxViewerNodes: 100000,
    maxClipboardBytes: 1024 * 1024,
    maxExportEntries: 25000,
    maxExportNodes: 500000,
    maxNetworkHeaders: 1000,
    maxNetworkBodyBytes: 512 * 1024,
    maxPendingCorrelations: 10000,
    maxStateTraceBytes: 512 * 1024,
    maxDatabaseScalarBytes: 16 * 1024,
    maxDatabaseDiagnosticsBytes: 64 * 1024,
    maxDatabaseMetadataBytes: 96 * 1024,
    maxUiDiagnosticBytes: 32 * 1024,
    maxSearchQueryBytes: 16 * 1024,
    maxConsoleStackTraceFrames: 100,
  );

  static const int maxAllowedCapturedValueBytes = 16 * 1024 * 1024;
  static const int maxAllowedLogRecordBytes = 32 * 1024 * 1024;
  static const int maxAllowedExportDocumentBytes = 256 * 1024 * 1024;
  static const int maxAllowedTraversalDepth = 256;
  static const int maxAllowedTraversalNodes = 1000000;
  static const int maxAllowedCollectionItems = 100000;
  static const int maxAllowedImportCharacters = 256 * 1024 * 1024;
  static const int maxAllowedImportBytes = 256 * 1024 * 1024;
  static const int maxAllowedImportNodes = 1000000;
  static const int maxAllowedImportEntries = 1000000;
  static const int maxAllowedViewerBytes = 16 * 1024 * 1024;
  static const int maxAllowedViewerNodes = 250000;
  static const int maxAllowedClipboardBytes = 4 * 1024 * 1024;
  static const int maxAllowedExportEntries = 100000;
  static const int maxAllowedExportNodes = 1000000;
  static const int maxAllowedNetworkHeaders = 10000;
  static const int maxAllowedNetworkBodyBytes = 16 * 1024 * 1024;
  static const int maxAllowedPendingCorrelations = 100000;
  static const int maxAllowedStateTraceBytes = 16 * 1024 * 1024;
  static const int maxAllowedDatabaseScalarBytes = 1024 * 1024;
  static const int maxAllowedDatabaseDiagnosticsBytes = 16 * 1024 * 1024;
  static const int maxAllowedDatabaseMetadataBytes = 16 * 1024 * 1024;
  static const int maxAllowedUiDiagnosticBytes = 1024 * 1024;
  static const int maxAllowedSearchQueryBytes = 64 * 1024;
  static const int maxAllowedConsoleStackTraceFrames = 1000;

  final int maxCapturedValueBytes;
  final int maxLogRecordBytes;
  final int maxExportDocumentBytes;
  final int maxTraversalDepth;
  final int maxTraversalNodes;
  final int maxCollectionItems;
  final int maxImportCharacters;
  final int maxImportBytes;
  final int maxImportNodes;
  final int maxImportEntries;
  final int maxViewerBytes;
  final int maxViewerNodes;
  final int maxClipboardBytes;
  final int maxExportEntries;
  final int maxExportNodes;
  final int maxNetworkHeaders;
  final int maxNetworkBodyBytes;
  final int maxPendingCorrelations;
  final int maxStateTraceBytes;
  final int maxDatabaseScalarBytes;
  final int maxDatabaseDiagnosticsBytes;
  final int maxDatabaseMetadataBytes;
  final int maxUiDiagnosticBytes;
  final int maxSearchQueryBytes;
  final int maxConsoleStackTraceFrames;

  /// Restores validated limits from [toMap] output.
  // ignore: sort_constructors_first
  factory DiagnosticResourceLimits.fromMap(Map<String, Object?> map) {
    const defaults = balanced;
    final limits = DiagnosticResourceLimits(
      maxCapturedValueBytes: _readInt(
        map,
        'max_captured_value_bytes',
        defaults.maxCapturedValueBytes,
      ),
      maxLogRecordBytes: _readInt(
        map,
        'max_log_record_bytes',
        defaults.maxLogRecordBytes,
      ),
      maxExportDocumentBytes: _readInt(
        map,
        'max_export_document_bytes',
        defaults.maxExportDocumentBytes,
      ),
      maxTraversalDepth: _readInt(
        map,
        'max_traversal_depth',
        defaults.maxTraversalDepth,
      ),
      maxTraversalNodes: _readInt(
        map,
        'max_traversal_nodes',
        defaults.maxTraversalNodes,
      ),
      maxCollectionItems: _readInt(
        map,
        'max_collection_items',
        defaults.maxCollectionItems,
      ),
      maxImportCharacters: _readInt(
        map,
        'max_import_characters',
        defaults.maxImportCharacters,
      ),
      maxImportBytes: _readInt(
        map,
        'max_import_bytes',
        defaults.maxImportBytes,
      ),
      maxImportNodes: _readInt(
        map,
        'max_import_nodes',
        defaults.maxImportNodes,
      ),
      maxImportEntries: _readInt(
        map,
        'max_import_entries',
        defaults.maxImportEntries,
      ),
      maxViewerBytes: _readInt(
        map,
        'max_viewer_bytes',
        defaults.maxViewerBytes,
      ),
      maxViewerNodes: _readInt(
        map,
        'max_viewer_nodes',
        defaults.maxViewerNodes,
      ),
      maxClipboardBytes: _readInt(
        map,
        'max_clipboard_bytes',
        defaults.maxClipboardBytes,
      ),
      maxExportEntries: _readInt(
        map,
        'max_export_entries',
        defaults.maxExportEntries,
      ),
      maxExportNodes: _readInt(
        map,
        'max_export_nodes',
        defaults.maxExportNodes,
      ),
      maxNetworkHeaders: _readInt(
        map,
        'max_network_headers',
        defaults.maxNetworkHeaders,
      ),
      maxNetworkBodyBytes: _readInt(
        map,
        'max_network_body_bytes',
        defaults.maxNetworkBodyBytes,
      ),
      maxPendingCorrelations: _readInt(
        map,
        'max_pending_correlations',
        defaults.maxPendingCorrelations,
      ),
      maxStateTraceBytes: _readInt(
        map,
        'max_state_trace_bytes',
        defaults.maxStateTraceBytes,
      ),
      maxDatabaseScalarBytes: _readInt(
        map,
        'max_database_scalar_bytes',
        defaults.maxDatabaseScalarBytes,
      ),
      maxDatabaseDiagnosticsBytes: _readInt(
        map,
        'max_database_diagnostics_bytes',
        defaults.maxDatabaseDiagnosticsBytes,
      ),
      maxDatabaseMetadataBytes: _readInt(
        map,
        'max_database_metadata_bytes',
        defaults.maxDatabaseMetadataBytes,
      ),
      maxUiDiagnosticBytes: _readInt(
        map,
        'max_ui_diagnostic_bytes',
        defaults.maxUiDiagnosticBytes,
      ),
      maxSearchQueryBytes: _readInt(
        map,
        'max_search_query_bytes',
        defaults.maxSearchQueryBytes,
      ),
      maxConsoleStackTraceFrames: _readInt(
        map,
        'max_console_stack_trace_frames',
        defaults.maxConsoleStackTraceFrames,
      ),
    );
    return limits..validate();
  }

  /// Serializes every budget so custom policies can be persisted exactly.
  Map<String, int> toMap() => {
        'max_captured_value_bytes': maxCapturedValueBytes,
        'max_log_record_bytes': maxLogRecordBytes,
        'max_export_document_bytes': maxExportDocumentBytes,
        'max_traversal_depth': maxTraversalDepth,
        'max_traversal_nodes': maxTraversalNodes,
        'max_collection_items': maxCollectionItems,
        'max_import_characters': maxImportCharacters,
        'max_import_bytes': maxImportBytes,
        'max_import_nodes': maxImportNodes,
        'max_import_entries': maxImportEntries,
        'max_viewer_bytes': maxViewerBytes,
        'max_viewer_nodes': maxViewerNodes,
        'max_clipboard_bytes': maxClipboardBytes,
        'max_export_entries': maxExportEntries,
        'max_export_nodes': maxExportNodes,
        'max_network_headers': maxNetworkHeaders,
        'max_network_body_bytes': maxNetworkBodyBytes,
        'max_pending_correlations': maxPendingCorrelations,
        'max_state_trace_bytes': maxStateTraceBytes,
        'max_database_scalar_bytes': maxDatabaseScalarBytes,
        'max_database_diagnostics_bytes': maxDatabaseDiagnosticsBytes,
        'max_database_metadata_bytes': maxDatabaseMetadataBytes,
        'max_ui_diagnostic_bytes': maxUiDiagnosticBytes,
        'max_search_query_bytes': maxSearchQueryBytes,
        'max_console_stack_trace_frames': maxConsoleStackTraceFrames,
      };

  static final Expando<bool> _validated = Expando<bool>('validated');

  /// Throws [ArgumentError] when a limit is unsafe or internally inconsistent.
  ///
  /// The result is memoized per instance, so repeated calls on a shared
  /// preset cost one lookup.
  void validate() {
    if (_validated[this] ?? false) return;
    _runValidation();
    _validated[this] = true;
  }

  void _runValidation() {
    _requireRange(
      maxCapturedValueBytes,
      'maxCapturedValueBytes',
      maxAllowedCapturedValueBytes,
    );
    _requireRange(
      maxLogRecordBytes,
      'maxLogRecordBytes',
      maxAllowedLogRecordBytes,
    );
    _requireRange(
      maxExportDocumentBytes,
      'maxExportDocumentBytes',
      maxAllowedExportDocumentBytes,
    );
    _requireRange(
      maxTraversalDepth,
      'maxTraversalDepth',
      maxAllowedTraversalDepth,
    );
    _requireRange(
      maxTraversalNodes,
      'maxTraversalNodes',
      maxAllowedTraversalNodes,
    );
    _requireRange(
      maxCollectionItems,
      'maxCollectionItems',
      maxAllowedCollectionItems,
    );
    _requireRange(
      maxImportCharacters,
      'maxImportCharacters',
      maxAllowedImportCharacters,
    );
    _requireRange(maxImportBytes, 'maxImportBytes', maxAllowedImportBytes);
    _requireRange(maxImportNodes, 'maxImportNodes', maxAllowedImportNodes);
    _requireRange(
      maxImportEntries,
      'maxImportEntries',
      maxAllowedImportEntries,
    );
    _requireRange(maxViewerBytes, 'maxViewerBytes', maxAllowedViewerBytes);
    _requireRange(maxViewerNodes, 'maxViewerNodes', maxAllowedViewerNodes);
    _requireRange(
      maxClipboardBytes,
      'maxClipboardBytes',
      maxAllowedClipboardBytes,
    );
    _requireRange(
      maxExportEntries,
      'maxExportEntries',
      maxAllowedExportEntries,
    );
    _requireRange(maxExportNodes, 'maxExportNodes', maxAllowedExportNodes);
    _requireRange(
      maxNetworkHeaders,
      'maxNetworkHeaders',
      maxAllowedNetworkHeaders,
    );
    _requireRange(
      maxNetworkBodyBytes,
      'maxNetworkBodyBytes',
      maxAllowedNetworkBodyBytes,
    );
    _requireRange(
      maxPendingCorrelations,
      'maxPendingCorrelations',
      maxAllowedPendingCorrelations,
    );
    _requireRange(
      maxStateTraceBytes,
      'maxStateTraceBytes',
      maxAllowedStateTraceBytes,
    );
    _requireRange(
      maxDatabaseScalarBytes,
      'maxDatabaseScalarBytes',
      maxAllowedDatabaseScalarBytes,
    );
    _requireRange(
      maxDatabaseDiagnosticsBytes,
      'maxDatabaseDiagnosticsBytes',
      maxAllowedDatabaseDiagnosticsBytes,
    );
    _requireRange(
      maxDatabaseMetadataBytes,
      'maxDatabaseMetadataBytes',
      maxAllowedDatabaseMetadataBytes,
    );
    _requireRange(
      maxUiDiagnosticBytes,
      'maxUiDiagnosticBytes',
      maxAllowedUiDiagnosticBytes,
    );
    _requireRange(
      maxSearchQueryBytes,
      'maxSearchQueryBytes',
      maxAllowedSearchQueryBytes,
    );
    _requireRange(
      maxConsoleStackTraceFrames,
      'maxConsoleStackTraceFrames',
      maxAllowedConsoleStackTraceFrames,
    );
    _requireAtLeast(
      maxLogRecordBytes,
      maxCapturedValueBytes,
      'maxLogRecordBytes',
      'maxCapturedValueBytes',
    );
    _requireAtLeast(
      maxExportDocumentBytes,
      maxLogRecordBytes,
      'maxExportDocumentBytes',
      'maxLogRecordBytes',
    );
    _requireAtLeast(
      maxDatabaseDiagnosticsBytes,
      maxDatabaseScalarBytes,
      'maxDatabaseDiagnosticsBytes',
      'maxDatabaseScalarBytes',
    );
    _requireAtLeast(
      maxDatabaseMetadataBytes,
      maxDatabaseDiagnosticsBytes,
      'maxDatabaseMetadataBytes',
      'maxDatabaseDiagnosticsBytes',
    );
  }

  DiagnosticResourceLimits copyWith({
    int? maxCapturedValueBytes,
    int? maxLogRecordBytes,
    int? maxExportDocumentBytes,
    int? maxTraversalDepth,
    int? maxTraversalNodes,
    int? maxCollectionItems,
    int? maxImportCharacters,
    int? maxImportBytes,
    int? maxImportNodes,
    int? maxImportEntries,
    int? maxViewerBytes,
    int? maxViewerNodes,
    int? maxClipboardBytes,
    int? maxExportEntries,
    int? maxExportNodes,
    int? maxNetworkHeaders,
    int? maxNetworkBodyBytes,
    int? maxPendingCorrelations,
    int? maxStateTraceBytes,
    int? maxDatabaseScalarBytes,
    int? maxDatabaseDiagnosticsBytes,
    int? maxDatabaseMetadataBytes,
    int? maxUiDiagnosticBytes,
    int? maxSearchQueryBytes,
    int? maxConsoleStackTraceFrames,
  }) =>
      DiagnosticResourceLimits(
        maxCapturedValueBytes:
            maxCapturedValueBytes ?? this.maxCapturedValueBytes,
        maxLogRecordBytes: maxLogRecordBytes ?? this.maxLogRecordBytes,
        maxExportDocumentBytes:
            maxExportDocumentBytes ?? this.maxExportDocumentBytes,
        maxTraversalDepth: maxTraversalDepth ?? this.maxTraversalDepth,
        maxTraversalNodes: maxTraversalNodes ?? this.maxTraversalNodes,
        maxCollectionItems: maxCollectionItems ?? this.maxCollectionItems,
        maxImportCharacters: maxImportCharacters ?? this.maxImportCharacters,
        maxImportBytes: maxImportBytes ?? this.maxImportBytes,
        maxImportNodes: maxImportNodes ?? this.maxImportNodes,
        maxImportEntries: maxImportEntries ?? this.maxImportEntries,
        maxViewerBytes: maxViewerBytes ?? this.maxViewerBytes,
        maxViewerNodes: maxViewerNodes ?? this.maxViewerNodes,
        maxClipboardBytes: maxClipboardBytes ?? this.maxClipboardBytes,
        maxExportEntries: maxExportEntries ?? this.maxExportEntries,
        maxExportNodes: maxExportNodes ?? this.maxExportNodes,
        maxNetworkHeaders: maxNetworkHeaders ?? this.maxNetworkHeaders,
        maxNetworkBodyBytes: maxNetworkBodyBytes ?? this.maxNetworkBodyBytes,
        maxPendingCorrelations:
            maxPendingCorrelations ?? this.maxPendingCorrelations,
        maxStateTraceBytes: maxStateTraceBytes ?? this.maxStateTraceBytes,
        maxDatabaseScalarBytes:
            maxDatabaseScalarBytes ?? this.maxDatabaseScalarBytes,
        maxDatabaseDiagnosticsBytes:
            maxDatabaseDiagnosticsBytes ?? this.maxDatabaseDiagnosticsBytes,
        maxDatabaseMetadataBytes:
            maxDatabaseMetadataBytes ?? this.maxDatabaseMetadataBytes,
        maxUiDiagnosticBytes: maxUiDiagnosticBytes ?? this.maxUiDiagnosticBytes,
        maxSearchQueryBytes: maxSearchQueryBytes ?? this.maxSearchQueryBytes,
        maxConsoleStackTraceFrames:
            maxConsoleStackTraceFrames ?? this.maxConsoleStackTraceFrames,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticResourceLimits &&
          other.maxCapturedValueBytes == maxCapturedValueBytes &&
          other.maxLogRecordBytes == maxLogRecordBytes &&
          other.maxExportDocumentBytes == maxExportDocumentBytes &&
          other.maxTraversalDepth == maxTraversalDepth &&
          other.maxTraversalNodes == maxTraversalNodes &&
          other.maxCollectionItems == maxCollectionItems &&
          other.maxImportCharacters == maxImportCharacters &&
          other.maxImportBytes == maxImportBytes &&
          other.maxImportNodes == maxImportNodes &&
          other.maxImportEntries == maxImportEntries &&
          other.maxViewerBytes == maxViewerBytes &&
          other.maxViewerNodes == maxViewerNodes &&
          other.maxClipboardBytes == maxClipboardBytes &&
          other.maxExportEntries == maxExportEntries &&
          other.maxExportNodes == maxExportNodes &&
          other.maxNetworkHeaders == maxNetworkHeaders &&
          other.maxNetworkBodyBytes == maxNetworkBodyBytes &&
          other.maxPendingCorrelations == maxPendingCorrelations &&
          other.maxStateTraceBytes == maxStateTraceBytes &&
          other.maxDatabaseScalarBytes == maxDatabaseScalarBytes &&
          other.maxDatabaseDiagnosticsBytes == maxDatabaseDiagnosticsBytes &&
          other.maxDatabaseMetadataBytes == maxDatabaseMetadataBytes &&
          other.maxUiDiagnosticBytes == maxUiDiagnosticBytes &&
          other.maxSearchQueryBytes == maxSearchQueryBytes &&
          other.maxConsoleStackTraceFrames == maxConsoleStackTraceFrames;

  @override
  int get hashCode => Object.hashAll([
        maxCapturedValueBytes,
        maxLogRecordBytes,
        maxExportDocumentBytes,
        maxTraversalDepth,
        maxTraversalNodes,
        maxCollectionItems,
        maxImportCharacters,
        maxImportBytes,
        maxImportNodes,
        maxImportEntries,
        maxViewerBytes,
        maxViewerNodes,
        maxClipboardBytes,
        maxExportEntries,
        maxExportNodes,
        maxNetworkHeaders,
        maxNetworkBodyBytes,
        maxPendingCorrelations,
        maxStateTraceBytes,
        maxDatabaseScalarBytes,
        maxDatabaseDiagnosticsBytes,
        maxDatabaseMetadataBytes,
        maxUiDiagnosticBytes,
        maxSearchQueryBytes,
        maxConsoleStackTraceFrames,
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

void _requireAtLeast(
  int value,
  int minimum,
  String name,
  String minimumName,
) {
  if (value < minimum) {
    throw ArgumentError.value(value, name, 'must be at least $minimumName');
  }
}
