import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_layout.dart';
import 'package:ispectify/src/history/file_log/managed_log_store.dart';
import 'package:ispectify/src/history/file_log/retention_planner.dart';

/// Applies [RetentionPlanner] decisions to the managed store: scans the
/// artifacts on disk, deletes or gzip-archives them, and prunes empty date
/// directories. Repeats until the planner has nothing left to do.
final class RetentionExecutor {
  RetentionExecutor({
    required ManagedLogStore store,
    required FileLogHistoryOptions options,
    int? archiveCompressedByteLimit,
  })  : _store = store,
        _options = options,
        _archiveCompressedByteLimit = archiveCompressedByteLimit;

  final ManagedLogStore _store;
  final FileLogHistoryOptions _options;
  final int? _archiveCompressedByteLimit;

  Future<void> apply() async {
    while (true) {
      final artifacts = await scanArtifacts();
      final actions = RetentionPlanner(_options).plan(artifacts);
      if (actions.isEmpty) return;

      for (final action in actions) {
        switch (action) {
          case DeleteArtifact():
            await deleteArtifact(action.artifact);
          case ArchiveArtifact():
            await _archiveArtifact(action.artifact);
        }
      }
      await deleteEmptyDateDirectories();
    }
  }

  Future<List<FileLogArtifact>> scanArtifacts() async {
    final artifacts = <FileLogArtifact>[];
    var managedArtifacts = 0;
    var managedDates = 0;
    final root = await _store.validatedSessionDirectory(
      operation: 'scanArtifacts',
    );
    await for (final entity in root.list(followLinks: false)) {
      final name = FileLogLayout.basename(entity.path);
      if (FileLogLayout.dateNamePattern.hasMatch(name)) {
        if (++managedDates > _store.managedArtifactLimit) {
          throw const FileLogLimitException(operation: 'scanArtifacts');
        }
        if (entity is! Directory) {
          throw const FileLogAccessException(operation: 'scanArtifacts');
        }
        final directory = await _store.validatedDateDirectory(
          entity.path,
          operation: 'scanArtifacts',
        );
        final date = DateTime.tryParse(name);
        if (date == null) continue;
        final files = <File>[];
        await for (final child in directory!.list(followLinks: false)) {
          final kind = FileLogLayout.dateArtifactKind(
            FileLogLayout.basename(child.path),
          );
          if (kind == null) continue;
          if (++managedArtifacts > _store.managedArtifactLimit) {
            throw const FileLogLimitException(operation: 'scanArtifacts');
          }
          if (child is! File) {
            throw const FileLogAccessException(operation: 'scanArtifacts');
          }
          final file = await _store.validatedDateArtifact(
            child,
            directory: directory,
            operation: 'scanArtifacts',
            allowedKinds: {kind},
          );
          files.add(file!);
        }
        final liveSegments = files
            .where(
              (file) => FileLogLayout.segmentNamePattern
                  .hasMatch(FileLogLayout.basename(file.path)),
            )
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
        final activePath = name == FileLogLayout.dateName(DateTime.now()) &&
                liveSegments.isNotEmpty
            ? liveSegments.last.path
            : null;
        for (final file in files) {
          final fileName = FileLogLayout.basename(file.path);
          final isSegment = FileLogLayout.segmentNamePattern.hasMatch(fileName);
          final isArchive = FileLogLayout.archiveNamePattern.hasMatch(fileName);
          final isTemporary = fileName.endsWith('.tmp');
          if (!isSegment && !isArchive && !isTemporary) continue;
          artifacts.add(
            FileLogArtifact(
              path: file.path,
              date: date,
              size: await _store.managedFileLength(
                file,
                operation: 'scanArtifacts',
              ),
              isActive: file.path == activePath,
              isArchive: isArchive,
              isTemporary: isTemporary,
              canArchive: isSegment,
            ),
          );
        }
      } else if (FileLogLayout.legacyNamePattern.hasMatch(name)) {
        if (++managedArtifacts > _store.managedArtifactLimit) {
          throw const FileLogLimitException(operation: 'scanArtifacts');
        }
        if (entity is! File) {
          throw const FileLogAccessException(operation: 'scanArtifacts');
        }
        final legacy = await _store.validatedLegacyFile(
          entity,
          operation: 'scanArtifacts',
        );
        final legacyDate = FileLogLayout.legacyDate(name);
        if (legacyDate != null) {
          artifacts.add(
            FileLogArtifact(
              path: legacy!.path,
              date: legacyDate,
              size: await _store.managedFileLength(
                legacy,
                operation: 'scanArtifacts',
              ),
              canArchive: false,
            ),
          );
        }
      }
    }
    return artifacts;
  }

  Future<void> deleteArtifact(FileLogArtifact artifact) async {
    final type = await FileSystemEntity.type(
      artifact.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return;
    await _store.deleteManagedFile(
      File(artifact.path),
      operation: 'deleteArtifact',
    );
  }

  Future<void> _archiveArtifact(FileLogArtifact artifact) async {
    final source = File(artifact.path);
    final target = File('${source.path}.gz');
    File? temporary;
    AcquiredReadFile? acquiredSource;
    AcquiredWritableFile? acquiredTemporary;
    var sourceClosed = false;
    var temporaryClosed = false;
    var renamed = false;
    try {
      final existingTarget = await _store.validatedHistoryFile(
        target,
        operation: 'archive',
        allowMissing: true,
        allowedKinds: const {ManagedFileKind.archive},
      );
      if (existingTarget != null) {
        await _recoverCompletedArchive(source, existingTarget);
        return;
      }
      acquiredSource = await _store.acquireReadHandle(
        source,
        maxBytes: _options.maxFileSize,
        operation: 'archive',
        allowedKinds: const {ManagedFileKind.segment},
      );
      acquiredTemporary = await _store.createArchiveTemporary(target);
      temporary = acquiredTemporary.file;
      final compressedLimit = _archiveCompressedByteLimit ??
          ManagedLogStore.gzipEncodedUpperBound(_options.maxFileSize);
      var compressedBytes = 0;
      final sourceChunks = _store.boundedChunks(
        _store.readHandleChunks(acquiredSource.handle),
        maxBytes: _options.maxFileSize,
        operation: 'archiveSource',
        path: source.path,
      );
      await for (final chunk in sourceChunks.transform(gzip.encoder)) {
        compressedBytes += chunk.length;
        if (compressedBytes > compressedLimit) {
          throw FileLogLimitException(
            operation: 'archiveCompressedOutput',
            path: source.path,
          );
        }
        await acquiredTemporary.handle.writeFrom(chunk);
      }
      await acquiredTemporary.handle.flush();
      final temporaryLength = await acquiredTemporary.handle.length();
      if (temporaryLength != compressedBytes) {
        throw const FileLogAccessException(operation: 'archive');
      }
      await _store.validatedHistoryFile(
        temporary,
        operation: 'archive',
        allowedKinds: const {ManagedFileKind.temporary},
      );
      if (await temporary.length() != compressedBytes) {
        throw const FileLogAccessException(operation: 'archive');
      }
      await acquiredTemporary.handle.close();
      temporaryClosed = true;
      await acquiredSource.handle.close();
      sourceClosed = true;
      await _store.validateFileIdentity(
        acquiredSource.file,
        acquiredSource.identity,
        operation: 'archive',
        allowedKinds: const {ManagedFileKind.segment},
      );
      final targetType = await FileSystemEntity.type(
        target.path,
        followLinks: false,
      );
      if (targetType != FileSystemEntityType.notFound) {
        throw const FileLogAccessException(operation: 'archive');
      }
      await temporary.rename(target.path);
      renamed = true;
      await _store.validatedHistoryFile(
        target,
        operation: 'archive',
        allowedKinds: const {ManagedFileKind.archive},
      );
      await _store.deleteManagedFile(
        source,
        operation: 'archive',
      );
    } on FileLogHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileLogStorageException(
        operation: 'archive',
        path: source.path,
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!temporaryClosed && acquiredTemporary != null) {
        await acquiredTemporary.handle.close();
      }
      if (!sourceClosed && acquiredSource != null) {
        await acquiredSource.handle.close();
      }
      if (!renamed &&
          temporary != null &&
          await FileSystemEntity.type(
                temporary.path,
                followLinks: false,
              ) ==
              FileSystemEntityType.file) {
        await _store.deleteManagedFile(temporary, operation: 'archiveCleanup');
      } else if (!renamed &&
          temporary != null &&
          await FileSystemEntity.type(
                temporary.path,
                followLinks: false,
              ) ==
              FileSystemEntityType.link) {
        // Delete the managed link itself; never resolve or follow it.
        await Link(temporary.path).delete();
      }
    }
  }

  Future<void> _recoverCompletedArchive(File source, File archive) async {
    final sourceBytes = await _store.readBoundedManagedFile(
      source,
      maxBytes: _options.maxFileSize,
      operation: 'archiveRecovery',
      allowedKinds: const {ManagedFileKind.segment},
    );
    final archiveBytes = await _store.readArtifactBytes(archive);
    if (sourceBytes.length != archiveBytes.length) {
      throw const FileLogAccessException(operation: 'archiveRecovery');
    }
    for (var index = 0; index < sourceBytes.length; index++) {
      if (sourceBytes[index] != archiveBytes[index]) {
        throw const FileLogAccessException(operation: 'archiveRecovery');
      }
    }
    await _store.deleteManagedFile(source, operation: 'archiveRecovery');
  }

  Future<void> deleteEmptyDateDirectories() async {
    final root = await _store.validatedSessionDirectory(
      operation: 'deleteEmptyDateDirectories',
    );
    final directories = <Directory>[];
    await for (final entity in root.list(followLinks: false)) {
      if (!FileLogLayout.dateNamePattern
          .hasMatch(FileLogLayout.basename(entity.path))) {
        continue;
      }
      if (entity is! Directory) {
        throw const FileLogAccessException(
          operation: 'deleteEmptyDateDirectories',
        );
      }
      final directory = await _store.validatedDateDirectory(
        entity.path,
        operation: 'deleteEmptyDateDirectories',
      );
      directories.add(directory!);
    }
    for (final directory in directories) {
      await _store.deleteDateDirectoryIfEmpty(
        directory,
        operation: 'deleteEmptyDateDirectories',
      );
    }
  }
}
