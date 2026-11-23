import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/models/log_id.dart';

/// Logs written during one app launch, as recorded by [FileLogHistory].
///
/// Each persisted entry carries the launch ID under
/// [TraceKeys.sessionId] in [ISpectLogData.additionalData]. Entries without
/// a well-formed launch ID, such as legacy day files, group under a `null`
/// [id]. Each import counts as its own launch, and a launch that runs past
/// midnight appears under both days.
final class LaunchLogs {
  LaunchLogs._({
    required this.id,
    required this.logs,
    required this.startedAt,
    required this.endedAt,
    required this.errorCount,
  });

  factory LaunchLogs._from(String? id, List<ISpectLogData> logs) {
    var startedAt = logs.first.time;
    var endedAt = startedAt;
    var errorCount = 0;
    for (final log in logs) {
      if (log.time.isBefore(startedAt)) startedAt = log.time;
      if (log.time.isAfter(endedAt)) endedAt = log.time;
      if (log.isError) errorCount++;
    }
    return LaunchLogs._(
      id: id,
      logs: List<ISpectLogData>.unmodifiable(logs),
      startedAt: startedAt,
      endedAt: endedAt,
      errorCount: errorCount,
    );
  }

  /// Groups [logs] by launch, newest launch first.
  ///
  /// Entries keep their input order inside each group. The group without a
  /// launch ID, when present, comes last.
  static List<LaunchLogs> groupByLaunch(Iterable<ISpectLogData> logs) {
    final byId = <String?, List<ISpectLogData>>{};
    for (final log in logs) {
      final id = log.additionalData?[TraceKeys.sessionId];
      final launchId = id is String && LogId.isValid(id) ? id : null;
      (byId[launchId] ??= <ISpectLogData>[]).add(log);
    }

    final unlabeled = byId.remove(null);
    final launches = [
      for (final MapEntry(:key, :value) in byId.entries)
        LaunchLogs._from(key, value),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return List<LaunchLogs>.unmodifiable([
      ...launches,
      if (unlabeled != null) LaunchLogs._from(null, unlabeled),
    ]);
  }

  /// The launch ID, or `null` for entries recorded without one.
  final String? id;

  /// The launch's entries in their stored order.
  final List<ISpectLogData> logs;

  /// The time of the earliest entry.
  final DateTime startedAt;

  /// The time of the latest entry.
  final DateTime endedAt;

  /// The number of entries whose [ISpectLogData.isError] is true.
  final int errorCount;
}
