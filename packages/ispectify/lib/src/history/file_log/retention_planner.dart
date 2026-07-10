import 'package:ispectify/ispectify.dart';
import 'package:meta/meta.dart';

@immutable
final class FileLogArtifact {
  const FileLogArtifact({
    required this.path,
    required this.date,
    required this.size,
    this.isActive = false,
    this.isArchive = false,
    this.isTemporary = false,
    this.canArchive = true,
  });

  final String path;
  final DateTime date;
  final int size;
  final bool isActive;
  final bool isArchive;
  final bool isTemporary;
  final bool canArchive;
}

@immutable
sealed class RetentionAction {
  const RetentionAction(this.artifact);

  final FileLogArtifact artifact;

  String get path => artifact.path;
}

final class DeleteArtifact extends RetentionAction {
  const DeleteArtifact(super.artifact);
}

final class ArchiveArtifact extends RetentionAction {
  const ArchiveArtifact(super.artifact);
}

final class RetentionPlanner {
  RetentionPlanner(this.options) {
    options.validate();
  }

  final FileLogHistoryOptions options;

  List<RetentionAction> plan(Iterable<FileLogArtifact> artifacts) {
    final all = List<FileLogArtifact>.of(artifacts);
    final actions = <RetentionAction>[];
    final deletedPaths = <String>{};
    var projectedSize = all.fold<int>(
      0,
      (total, artifact) => total + artifact.size,
    );

    final temporary = all
        .where((artifact) => artifact.isTemporary && !artifact.isActive)
        .toList()
      ..sort(_compareOldest);
    for (final artifact in temporary) {
      actions.add(DeleteArtifact(artifact));
      deletedPaths.add(artifact.path);
      projectedSize -= artifact.size;
    }

    final live =
        all.where((artifact) => !artifact.isTemporary).toList(growable: false);
    final dates = live.map(_calendarDate).toSet().toList()..sort();
    final expiredDateCount = dates.length - options.maxSessionDays;
    if (expiredDateCount > 0) {
      final expiredDates = dates.take(expiredDateCount).toSet();
      final expired = live
          .where(
            (artifact) =>
                expiredDates.contains(_calendarDate(artifact)) &&
                !artifact.isActive,
          )
          .toList()
        ..sort(_compareOldest);
      for (final artifact in expired) {
        actions.add(DeleteArtifact(artifact));
        deletedPaths.add(artifact.path);
        projectedSize -= artifact.size;
      }
    }

    if (projectedSize <= options.maxTotalSize) return actions;

    final candidates = live
        .where(
          (artifact) =>
              !artifact.isActive && !deletedPaths.contains(artifact.path),
        )
        .toList();

    switch (options.cleanupStrategy) {
      case SessionCleanupStrategy.deleteOldest:
        candidates.sort(_compareOldest);
        _appendDeletesUntilBounded(
          candidates,
          actions,
          projectedSize: projectedSize,
        );
      case SessionCleanupStrategy.deleteBySize:
        candidates.sort(_compareLargest);
        _appendDeletesUntilBounded(
          candidates,
          actions,
          projectedSize: projectedSize,
        );
      case SessionCleanupStrategy.archiveOldest:
        final segments = candidates
            .where(
              (artifact) => !artifact.isArchive && artifact.canArchive,
            )
            .toList()
          ..sort(_compareOldest);
        if (segments.isNotEmpty) {
          actions.add(ArchiveArtifact(segments.first));
          return actions;
        }
        candidates.sort(_compareOldest);
        _appendDeletesUntilBounded(
          candidates,
          actions,
          projectedSize: projectedSize,
        );
    }

    return actions;
  }

  void _appendDeletesUntilBounded(
    Iterable<FileLogArtifact> candidates,
    List<RetentionAction> actions, {
    required int projectedSize,
  }) {
    var remainingSize = projectedSize;
    for (final artifact in candidates) {
      if (remainingSize <= options.maxTotalSize) break;
      actions.add(DeleteArtifact(artifact));
      remainingSize -= artifact.size;
    }
  }

  DateTime _calendarDate(FileLogArtifact artifact) => DateTime(
        artifact.date.year,
        artifact.date.month,
        artifact.date.day,
      );

  int _compareOldest(FileLogArtifact left, FileLogArtifact right) {
    final byDate = left.date.compareTo(right.date);
    return byDate != 0 ? byDate : left.path.compareTo(right.path);
  }

  int _compareLargest(FileLogArtifact left, FileLogArtifact right) {
    final bySize = right.size.compareTo(left.size);
    return bySize != 0 ? bySize : _compareOldest(left, right);
  }
}
