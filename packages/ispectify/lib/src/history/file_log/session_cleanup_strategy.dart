// ignore_for_file: avoid_print

/// Strategy for cleaning up old log files when session limit is exceeded.
///
/// - deleteOldest: Remove oldest files first (default)
/// - deleteBySize: Remove largest files first
/// - archiveOldest: Archive oldest files before deletion
enum SessionCleanupStrategy {
  /// Delete oldest files first when limit exceeded
  deleteOldest,

  /// Delete largest files first when limit exceeded
  deleteBySize,

  /// Archive oldest files before deletion
  archiveOldest,
}
