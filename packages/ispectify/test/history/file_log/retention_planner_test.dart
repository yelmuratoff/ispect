import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/retention_planner.dart';
import 'package:test/test.dart';

void main() {
  test('removes expired dates before applying the size strategy', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxSessionDays: 2,
        maxFileSize: 100,
        maxTotalSize: 300,
      ),
    ).plan([
      artifact('old', DateTime(2026, 7, 8), size: 50),
      artifact('middle', DateTime(2026, 7, 9), size: 50),
      artifact('active', DateTime(2026, 7, 10), size: 50, active: true),
    ]);

    expect(actions, [
      isA<DeleteArtifact>().having((action) => action.path, 'path', 'old'),
    ]);
  });

  test('counts distinct dates rather than artifacts for the day limit', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxSessionDays: 2,
        maxFileSize: 100,
        maxTotalSize: 500,
      ),
    ).plan([
      artifact('old-a', DateTime(2026, 7, 8), size: 10),
      artifact('old-b', DateTime(2026, 7, 8), size: 10),
      artifact('middle', DateTime(2026, 7, 9), size: 10),
      artifact('active', DateTime(2026, 7, 10), size: 10, active: true),
    ]);

    expect(actions.map((action) => action.path), ['old-a', 'old-b']);
  });

  test('never selects the active artifact', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxFileSize: 100,
        maxTotalSize: 100,
      ),
    ).plan([
      artifact('closed', DateTime(2026, 7, 10), size: 80),
      artifact('active', DateTime(2026, 7, 10), size: 80, active: true),
    ]);

    expect(actions.map((action) => action.path), ['closed']);
    expect(actions.map((action) => action.path), isNot(contains('active')));
  });

  test('deleteOldest selects closed artifacts by age then path', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxFileSize: 100,
        maxTotalSize: 100,
      ),
    ).plan([
      artifact('b', DateTime(2026, 7, 9), size: 40),
      artifact('a', DateTime(2026, 7, 9), size: 40),
      artifact('newer', DateTime(2026, 7, 10), size: 40),
      artifact('active', DateTime(2026, 7, 10), size: 40, active: true),
    ]);

    expect(actions.map((action) => action.path), ['a', 'b']);
  });

  test('deleteBySize selects largest and breaks equal sizes by age', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxFileSize: 100,
        maxTotalSize: 100,
        cleanupStrategy: SessionCleanupStrategy.deleteBySize,
      ),
    ).plan([
      artifact('small', DateTime(2026, 7, 8), size: 20),
      artifact('large-new', DateTime(2026, 7, 10), size: 60),
      artifact('large-old', DateTime(2026, 7, 9), size: 60),
      artifact('active', DateTime(2026, 7, 10), size: 40, active: true),
    ]);

    expect(actions.map((action) => action.path), ['large-old', 'large-new']);
  });

  test('archiveOldest selects one oldest uncompressed artifact per plan', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxFileSize: 100,
        maxTotalSize: 100,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    ).plan([
      artifact('old', DateTime(2026, 7, 8), size: 80),
      artifact('new', DateTime(2026, 7, 9), size: 80),
      artifact('active', DateTime(2026, 7, 10), size: 20, active: true),
    ]);

    expect(actions, [
      isA<ArchiveArtifact>().having((action) => action.path, 'path', 'old'),
    ]);
  });

  test('archiveOldest deletes oldest archives when no segments remain', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxFileSize: 100,
        maxTotalSize: 100,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    ).plan([
      artifact('archive-old', DateTime(2026, 7, 8), size: 70, archive: true),
      artifact('archive-new', DateTime(2026, 7, 9), size: 50, archive: true),
      artifact('active', DateTime(2026, 7, 10), size: 20, active: true),
    ]);

    expect(actions.map((action) => action.path), ['archive-old']);
    expect(actions.single, isA<DeleteArtifact>());
  });

  test('temporary artifacts are cleaned first and never archived', () {
    final actions = RetentionPlanner(
      const FileLogHistoryOptions(
        maxFileSize: 100,
        maxTotalSize: 100,
        cleanupStrategy: SessionCleanupStrategy.archiveOldest,
      ),
    ).plan([
      artifact('failed.tmp', DateTime(2026, 7, 8), size: 30, temporary: true),
      artifact('closed', DateTime(2026, 7, 9), size: 80),
      artifact('active', DateTime(2026, 7, 10), size: 20, active: true),
    ]);

    expect(actions.map((action) => action.path), ['failed.tmp']);
    expect(actions.single, isA<DeleteArtifact>());
  });
}

FileLogArtifact artifact(
  String path,
  DateTime date, {
  required int size,
  bool active = false,
  bool archive = false,
  bool temporary = false,
}) =>
    FileLogArtifact(
      path: path,
      date: date,
      size: size,
      isActive: active,
      isArchive: archive,
      isTemporary: temporary,
    );
