import 'dart:io';

/// Artifact kinds the rolling file history manages inside a date directory
/// or, for [legacy], directly inside the session directory.
enum ManagedFileKind {
  segment,
  archive,
  temporary,
  legacy,
}

/// Naming and path conventions of the on-disk log layout:
///
/// ```text
/// <provider>/ispect_logs/
///   YYYY-MM-DD/000000.jsonl          live segment
///   YYYY-MM-DD/000000.jsonl.gz       archived segment
///   YYYY-MM-DD/000000.jsonl.gz.<id>.tmp   in-flight archive
///   logs_YYYY-MM-DD.json             legacy single-file day
/// ```
abstract final class FileLogLayout {
  static const String sessionDirectoryName = 'ispect_logs';
  static const int maxSegmentIndex = 999999;

  static final RegExp segmentNamePattern = RegExp(r'^\d{6}\.jsonl$');
  static final RegExp archiveNamePattern = RegExp(r'^\d{6}\.jsonl\.gz$');
  static final RegExp temporaryArchiveNamePattern = RegExp(
    r'^\d{6}\.jsonl\.gz(?:\.[0-9A-HJKMNP-TV-Z]{26})?\.tmp$',
  );
  static final RegExp dateNamePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp legacyNamePattern =
      RegExp(r'^logs_(\d{4}-\d{2}-\d{2})\.json$');

  static ManagedFileKind? dateArtifactKind(String name) {
    if (segmentNamePattern.hasMatch(name)) return ManagedFileKind.segment;
    if (archiveNamePattern.hasMatch(name)) return ManagedFileKind.archive;
    if (temporaryArchiveNamePattern.hasMatch(name)) {
      return ManagedFileKind.temporary;
    }
    return null;
  }

  static DateTime? legacyDate(String name) {
    final match = legacyNamePattern.firstMatch(name);
    return DateTime.tryParse(match?.group(1) ?? '');
  }

  static String segmentName(int index) =>
      '${index.toString().padLeft(6, '0')}.jsonl';

  static int segmentIndex(String name) => int.parse(name.substring(0, 6));

  static String dateName(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String legacyFileName(DateTime date) => 'logs_${dateName(date)}.json';

  static String join(String parent, String child) =>
      parent.endsWith(Platform.pathSeparator)
          ? '$parent$child'
          : '$parent${Platform.pathSeparator}$child';

  static String basename(String path) =>
      path.split(Platform.pathSeparator).last;

  static bool isWithinRoot(String path, String root) =>
      path == root || path.startsWith('$root${Platform.pathSeparator}');
}
