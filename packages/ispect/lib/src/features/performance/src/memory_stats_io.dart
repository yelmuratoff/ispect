import 'dart:io';

/// Resident set size of the current process in bytes, or null when the
/// underlying platform does not report it (rare; OS hook may return `-1`).
int? readCurrentRssBytes() {
  try {
    final rss = ProcessInfo.currentRss;
    return rss > 0 ? rss : null;
  } catch (_) {
    return null;
  }
}
