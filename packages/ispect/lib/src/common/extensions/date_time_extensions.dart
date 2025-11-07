import 'package:ispect/src/common/history/file_history_config.dart';

/// Extensions for DateTime to provide common formatting and comparison operations.
///
/// These extensions eliminate code duplication and provide consistent date handling
/// throughout the application, particularly for file naming and date comparisons.
extension DateTimeFormatting on DateTime {
  /// Formats date as YYYY-MM-DD for file naming.
  ///
  /// **Format:** Year (4 digits) - Month (2 digits) - Day (2 digits)
  ///
  /// **Purpose:** Creates sortable, consistent file names for daily log files
  ///
  /// **Example:**
  /// ```dart
  /// final date = DateTime(2024, 1, 5);
  /// print(date.toFileNameFormat()); // "2024-01-05"
  /// ```
  ///
  /// **Benefits:**
  /// - Lexicographic sorting matches chronological order
  /// - Cross-platform compatible (no special characters)
  /// - Human-readable for debugging
  /// - Fixed width for alignment in listings
  String toFileNameFormat() =>
      '$year-${month.toString().padLeft(FileHistoryConfig.datePaddingWidth, FileHistoryConfig.datePaddingChar)}-${day.toString().padLeft(FileHistoryConfig.datePaddingWidth, FileHistoryConfig.datePaddingChar)}';

  /// Formats date as ISO 8601 date-only string (no time component).
  ///
  /// **Format:** YYYY-MM-DD (ISO 8601 date format)
  ///
  /// **Purpose:** Standard date representation for APIs and storage
  ///
  /// **Example:**
  /// ```dart
  /// final date = DateTime(2024, 1, 5, 14, 30, 45);
  /// print(date.toIso8601DateOnly()); // "2024-01-05"
  /// ```
  ///
  /// **Use cases:**
  /// - API requests requiring date-only parameters
  /// - Database queries filtering by date
  /// - UI displays showing dates without time
  String toIso8601DateOnly() => toIso8601String().split('T').first;

  /// Checks if this date is the same calendar day as another date.
  ///
  /// **Comparison:** Year, month, and day only (ignores time)
  ///
  /// **Purpose:** Determines if two DateTime instances represent the same day
  ///
  /// **Example:**
  /// ```dart
  /// final morning = DateTime(2024, 1, 5, 9, 0);
  /// final evening = DateTime(2024, 1, 5, 21, 0);
  /// print(morning.isSameDay(evening)); // true
  ///
  /// final nextDay = DateTime(2024, 1, 6, 9, 0);
  /// print(morning.isSameDay(nextDay)); // false
  /// ```
  ///
  /// **Use cases:**
  /// - Grouping logs by date
  /// - Checking if file exists for today
  /// - Date-based cache invalidation
  ///
  /// **Performance:** O(1) - three integer comparisons
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// Returns a new DateTime with time set to midnight (start of day).
  ///
  /// **Result:** DateTime with hours, minutes, seconds, and milliseconds set to 0
  ///
  /// **Purpose:** Normalizes date to midnight for consistent date-only operations
  ///
  /// **Example:**
  /// ```dart
  /// final now = DateTime(2024, 1, 5, 14, 30, 45, 123);
  /// final midnight = now.toMidnight();
  /// print(midnight); // 2024-01-05 00:00:00.000
  /// ```
  ///
  /// **Use cases:**
  /// - Date-only comparisons (< > == operators work correctly)
  /// - Grouping timestamps by day
  /// - Generating date ranges
  ///
  /// **Note:** Preserves the original date's timezone
  DateTime toMidnight() => DateTime(year, month, day);

  /// Checks if this date is today (current calendar day).
  ///
  /// **Comparison:** Compares against DateTime.now() using isSameDay
  ///
  /// **Purpose:** Quick check for "today" without manual DateTime.now() calls
  ///
  /// **Example:**
  /// ```dart
  /// final yesterday = DateTime.now().subtract(Duration(days: 1));
  /// print(yesterday.isToday); // false
  ///
  /// final now = DateTime.now();
  /// print(now.isToday); // true
  /// ```
  ///
  /// **Use cases:**
  /// - UI conditional logic (show "Today" vs date string)
  /// - Today's log file checks
  /// - Recent activity detection
  ///
  /// **Warning:** Uses DateTime.now() internally, not suitable for unit tests
  /// without mocking time
  bool get isToday {
    final now = DateTime.now();
    return isSameDay(now);
  }

  /// Checks if this date is yesterday (previous calendar day).
  ///
  /// **Comparison:** Compares against yesterday derived from DateTime.now()
  ///
  /// **Purpose:** Quick check for "yesterday" for UI and logic
  ///
  /// **Example:**
  /// ```dart
  /// final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
  /// print(twoDaysAgo.isYesterday); // false
  ///
  /// final yesterday = DateTime.now().subtract(Duration(days: 1));
  /// print(yesterday.isYesterday); // true
  /// ```
  ///
  /// **Use cases:**
  /// - UI labels ("Yesterday" vs specific date)
  /// - Recent activity detection
  /// - Rollover notifications
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Returns the age of this date in days from now.
  ///
  /// **Calculation:** Difference in calendar days, not 24-hour periods
  ///
  /// **Purpose:** Determines how many days ago a date occurred
  ///
  /// **Example:**
  /// ```dart
  /// final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
  /// print(threeDaysAgo.ageInDays); // 3
  ///
  /// final future = DateTime.now().add(Duration(days: 2));
  /// print(future.ageInDays); // -2 (negative for future dates)
  /// ```
  ///
  /// **Use cases:**
  /// - Session cleanup (delete logs older than N days)
  /// - Cache expiration checks
  /// - Activity timeline generation
  ///
  /// **Note:** Returns negative values for future dates
  /// **Performance:** O(1)
  int get ageInDays {
    final now = DateTime.now();
    final difference = now.toMidnight().difference(toMidnight());
    return difference.inDays;
  }
}
