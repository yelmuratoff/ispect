/// Configuration constants for file-based log history optimization.
///
/// This class contains tuned performance parameters for the daily file history
/// implementation. These values are based on real-world usage patterns and
/// device performance characteristics.
class FileHistoryConfig {
  /// Prevents instantiation - this is a constants-only class.
  const FileHistoryConfig._();

  /// Number of logs processed in each chunk before yielding execution.
  ///
  /// **Value:** 100 entries per chunk
  ///
  /// **Purpose:** Prevents UI jank by periodically yielding to the event loop
  /// during batch operations like file writing and JSON parsing.
  static const int chunkSize = 100;

  /// Conservative byte size estimate for a single log entry.
  ///
  /// **Value:** 500 bytes per entry
  ///
  /// **Purpose:** Used for pre-allocation and size estimation when actual
  /// log sizes aren't available, helping prevent excessive file growth.
  static const int fallbackEntrySize = 500;

  /// Safety margin multiplier for file size calculations.
  ///
  /// **Value:** 1.2 (20% buffer)
  ///
  /// **Purpose:** Accounts for JSON formatting overhead, metadata, and
  /// variability in log entry sizes.
  static const double sizeSafetyMargin = 1.2;

  /// Buffer percentage for filesystem overhead calculations.
  ///
  /// **Value:** 1.1 (10% buffer)
  ///
  /// **Purpose:** Accounts for filesystem metadata, journaling, and block
  /// allocation overhead when checking available space.
  static const double filesystemOverheadMargin = 1.1;

  /// Threshold percentage of max file size before triggering rotation.
  ///
  /// **Value:** 0.9 (90% of limit)
  ///
  /// **Purpose:** Provides safety buffer to avoid edge cases when approaching
  /// the file size limit, preventing partial writes or corruption.
  static const double fileSizeThreshold = 0.9;

  /// Sample size for log entry size estimation.
  ///
  /// **Value:** 10 entries
  ///
  /// **Purpose:** When estimating average log size, sample this many entries
  /// to balance accuracy vs. performance.
  static const int sampleSizeForEstimation = 10;

  /// Number of padding zeros for date components in filenames.
  ///
  /// **Value:** 2 digits
  ///
  /// **Purpose:** Ensures proper lexicographic sorting of date-based filenames
  /// (e.g., "logs_2024-01-05.json" sorts before "logs_2024-01-15.json").
  static const int datePaddingWidth = 2;

  /// Character used for zero-padding in date strings.
  ///
  /// **Value:** '0'
  ///
  /// **Purpose:** Standard zero-padding for consistent filename formatting.
  static const String datePaddingChar = '0';
}
