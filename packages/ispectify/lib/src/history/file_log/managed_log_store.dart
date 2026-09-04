import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_layout.dart';
import 'package:ispectify/src/models/log_id.dart';
import 'package:meta/meta.dart';

/// The only path through which the rolling file history touches the disk.
///
/// Every operation re-validates that the target lives under the canonical
/// session directory, matches a managed name, is a regular file or directory
/// (never a link), and is still the same inode after a handle is opened.
/// Reads are bounded by the caller's byte limit before any byte is consumed.
final class ManagedLogStore {
  ManagedLogStore({
    required FileLogDirectoryProvider directoryProvider,
    required FileLogHistoryOptions options,
    required bool providerDirectoryRequiresOwnerOnlyProtection,
    FutureOr<void> Function(File file, String operation)? ioHook,
  })  : _directoryProvider = directoryProvider,
        _options = options,
        _providerDirectoryRequiresOwnerOnlyProtection =
            providerDirectoryRequiresOwnerOnlyProtection,
        _ioHook = ioHook;

  static const int _ioChunkSize = 64 * 1024;
  static const int _groupOrWorldPermissionBits = 0x3f;
  static const int _groupOrWorldWriteBits = 0x12;

  final FileLogDirectoryProvider _directoryProvider;
  final FileLogHistoryOptions _options;
  final bool _providerDirectoryRequiresOwnerOnlyProtection;
  final FutureOr<void> Function(File file, String operation)? _ioHook;

  String? _resolvedProviderDirectory;
  String? _canonicalProviderDirectory;
  String? _resolvedSessionDirectory;
  String? _canonicalSessionDirectory;

  String? get resolvedSessionDirectory => _resolvedSessionDirectory;

  String get sessionDirectory =>
      _resolvedSessionDirectory ??
      (throw StateError('File log history is not initialized'));

  int get managedArtifactLimit {
    // Every artifact created by this implementation contains at least one
    // bounded JSONL record. The small floor also leaves room for crash
    // temporaries without coupling durable storage to the in-memory history
    // setting.
    const conservativeMinimumArtifactBytes = 64;
    return _options.maxTotalSize ~/ conservativeMinimumArtifactBytes +
        _options.maxSessionDays * 2 +
        2;
  }

  static int gzipEncodedUpperBound(int sourceBytes) =>
      sourceBytes +
      (sourceBytes >> 12) +
      (sourceBytes >> 14) +
      (sourceBytes >> 25) +
      64;

  /// Resolves the provider and session directories, creating the session
  /// directory when missing, and pins their canonical paths for every later
  /// validation.
  Future<void> initialize() async {
    final providerPath = await _directoryProvider();
    if (await FileSystemEntity.type(
          providerPath,
          followLinks: false,
        ) !=
        FileSystemEntityType.directory) {
      throw const FileLogAccessException(operation: 'initialize');
    }
    final providerDirectory = Directory(providerPath);
    await _validatePrivateDirectoryPermissions(
      providerDirectory,
      operation: 'initialize',
      requireOwnerOnlyProtection: _providerDirectoryRequiresOwnerOnlyProtection,
    );
    _resolvedProviderDirectory = providerDirectory.path;
    _canonicalProviderDirectory =
        await providerDirectory.resolveSymbolicLinks();

    final directory = Directory(
      FileLogLayout.join(
        providerDirectory.path,
        FileLogLayout.sessionDirectoryName,
      ),
    );
    final initialType = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (initialType == FileSystemEntityType.link) {
      throw const FileLogAccessException(operation: 'initialize');
    }
    if (initialType == FileSystemEntityType.notFound) {
      await directory.create();
    }
    if (await FileSystemEntity.type(
          directory.path,
          followLinks: false,
        ) !=
        FileSystemEntityType.directory) {
      throw const FileLogAccessException(operation: 'initialize');
    }
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: 'initialize',
    );
    _resolvedSessionDirectory = directory.path;
    _canonicalSessionDirectory = await directory.resolveSymbolicLinks();
    await validatedSessionDirectory(operation: 'initialize');
  }

  String dateDirectoryPath(DateTime date) =>
      FileLogLayout.join(sessionDirectory, FileLogLayout.dateName(date));

  String legacyFilePath(DateTime date) =>
      FileLogLayout.join(sessionDirectory, FileLogLayout.legacyFileName(date));

  File nextSegment(Directory directory, int highestIndex) {
    if (highestIndex >= FileLogLayout.maxSegmentIndex) {
      throw const FileLogLimitException(operation: 'appendRecord');
    }
    final nextIndex = highestIndex + 1;
    return File(
      FileLogLayout.join(
        directory.path,
        FileLogLayout.segmentName(nextIndex),
      ),
    );
  }

  Future<AcquiredWritableFile> acquireAppendHandle(
    File file, {
    required String operation,
    required bool createIfMissing,
  }) async {
    var validated = await validatedHistoryFile(
      file,
      operation: operation,
      allowMissing: createIfMissing,
      allowedKinds: const {ManagedFileKind.segment},
    );
    if (validated == null) {
      try {
        await file.create(exclusive: true);
      } on FileSystemException catch (_, stackTrace) {
        throw FileLogAccessException(
          operation: operation,
          stackTrace: stackTrace,
        );
      }
      validated = await validatedHistoryFile(
        file,
        operation: operation,
        allowedKinds: const {ManagedFileKind.segment},
      );
    }
    final before = FileIdentity.fromStat(await validated!.stat());
    final hook = _ioHook;
    if (hook != null) await hook(validated, operation);
    final handle = await validated.open(mode: FileMode.append);
    try {
      final afterFile = await validatedHistoryFile(
        validated,
        operation: operation,
        allowedKinds: const {ManagedFileKind.segment},
      );
      final after = FileIdentity.fromStat(await afterFile!.stat());
      if (before != after || await handle.length() != after.size) {
        throw FileLogAccessException(operation: operation);
      }
      return AcquiredWritableFile(file: validated, handle: handle);
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Future<void> validateWritablePath(
    AcquiredWritableFile acquired, {
    required String operation,
  }) async {
    final validated = await validatedHistoryFile(
      acquired.file,
      operation: operation,
      allowedKinds: const {ManagedFileKind.segment},
    );
    if (await validated!.length() != await acquired.handle.length()) {
      throw FileLogAccessException(operation: operation);
    }
  }

  Future<List<File>> segmentFiles(
    Directory directory, {
    bool includeArchives = false,
    bool includeTemporary = false,
    String operation = 'scanSegments',
  }) async {
    final files = <File>[];
    var managedArtifacts = 0;
    final validatedDirectory = await validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    await for (final entity in validatedDirectory!.list(followLinks: false)) {
      final name = FileLogLayout.basename(entity.path);
      final kind = FileLogLayout.dateArtifactKind(name);
      if (kind != null && ++managedArtifacts > managedArtifactLimit) {
        throw FileLogLimitException(operation: operation);
      }
      final included = kind == ManagedFileKind.segment ||
          includeArchives && kind == ManagedFileKind.archive ||
          includeTemporary && kind == ManagedFileKind.temporary;
      if (kind == null) continue;
      if (entity is! File) {
        throw FileLogAccessException(
          operation: operation,
        );
      }
      final file = await validatedDateArtifact(
        entity,
        directory: validatedDirectory,
        operation: operation,
        allowedKinds: {kind},
      );
      if (included) files.add(file!);
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  Future<List<int>> readArtifactBytes(File file) async {
    final kind =
        FileLogLayout.dateArtifactKind(FileLogLayout.basename(file.path));
    if (kind == ManagedFileKind.segment) {
      return readBoundedManagedFile(
        file,
        maxBytes: _options.maxFileSize,
        operation: 'readSegment',
        allowedKinds: const {ManagedFileKind.segment},
      );
    }
    if (kind != ManagedFileKind.archive) {
      throw const FileLogAccessException(operation: 'readSegment');
    }

    final compressedLimit = gzipEncodedUpperBound(_options.maxFileSize);
    final acquired = await acquireReadHandle(
      file,
      maxBytes: compressedLimit,
      operation: 'readCompressedSegment',
      allowedKinds: const {ManagedFileKind.archive},
    );
    final builder = BytesBuilder(copy: false);
    try {
      final compressed = boundedChunks(
        readHandleChunks(acquired.handle),
        maxBytes: compressedLimit,
        operation: 'readCompressedSegment',
        path: file.path,
      );
      final decompressed = boundedChunks(
        compressed.transform(gzip.decoder),
        maxBytes: _options.maxFileSize,
        operation: 'decompressSegment',
        path: file.path,
      );
      await decompressed.forEach(builder.add);
      await validateFileIdentity(
        acquired.file,
        acquired.identity,
        operation: 'readCompressedSegment',
        allowedKinds: const {ManagedFileKind.archive},
      );
      return builder.takeBytes();
    } finally {
      await acquired.handle.close();
    }
  }

  Future<Directory> validatedProviderDirectory({
    required String operation,
  }) async {
    final path = _resolvedProviderDirectory;
    final canonicalPath = _canonicalProviderDirectory;
    if (path == null || canonicalPath == null) {
      throw FileLogAccessException(operation: operation);
    }
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw FileLogAccessException(operation: operation);
    }
    final directory = Directory(path);
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: operation,
      requireOwnerOnlyProtection: _providerDirectoryRequiresOwnerOnlyProtection,
    );
    if (await directory.resolveSymbolicLinks() != canonicalPath) {
      throw FileLogAccessException(operation: operation);
    }
    return directory;
  }

  Future<Directory> validatedSessionDirectory({
    required String operation,
  }) async {
    final provider = await validatedProviderDirectory(operation: operation);
    final path = _resolvedSessionDirectory;
    final canonicalPath = _canonicalSessionDirectory;
    if (path == null ||
        canonicalPath == null ||
        path !=
            FileLogLayout.join(
              provider.path,
              FileLogLayout.sessionDirectoryName,
            )) {
      throw FileLogAccessException(operation: operation);
    }
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type != FileSystemEntityType.directory) {
      throw FileLogAccessException(operation: operation);
    }
    final directory = Directory(path);
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: operation,
    );
    if (await directory.resolveSymbolicLinks() != canonicalPath) {
      throw FileLogAccessException(operation: operation);
    }
    return directory;
  }

  Future<Directory?> validatedDateDirectory(
    String path, {
    required String operation,
    bool allowMissing = false,
  }) async {
    final root = await validatedSessionDirectory(operation: operation);
    final name = FileLogLayout.basename(path);
    if (!FileLogLayout.dateNamePattern.hasMatch(name) ||
        path != FileLogLayout.join(root.path, name)) {
      throw FileLogAccessException(operation: operation);
    }

    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound && allowMissing) return null;
    if (type != FileSystemEntityType.directory) {
      throw FileLogAccessException(operation: operation);
    }

    final directory = Directory(path);
    await _validatePrivateDirectoryPermissions(
      directory,
      operation: operation,
    );
    final canonicalRoot = _canonicalSessionDirectory!;
    final canonicalPath = await directory.resolveSymbolicLinks();
    if (canonicalPath != FileLogLayout.join(canonicalRoot, name)) {
      throw FileLogAccessException(operation: operation);
    }
    return directory;
  }

  Future<void> _validatePrivateDirectoryPermissions(
    Directory directory, {
    required String operation,
    bool requireOwnerOnlyProtection = false,
  }) async {
    if (Platform.isWindows) return;
    final stat = await directory.stat();
    if (stat.type != FileSystemEntityType.directory ||
        stat.mode & _groupOrWorldWriteBits != 0) {
      throw FileLogAccessException(operation: operation);
    }
    if (!requireOwnerOnlyProtection ||
        stat.mode & _groupOrWorldPermissionBits == 0) {
      return;
    }
    if (!await _hasOwnerOnlyAncestor(directory)) {
      throw FileLogAccessException(operation: operation);
    }
  }

  Future<bool> _hasOwnerOnlyAncestor(Directory directory) async {
    var current = Directory(await directory.resolveSymbolicLinks()).parent;
    while (true) {
      final stat = await current.stat();
      if (stat.type != FileSystemEntityType.directory) return false;
      if (stat.mode & _groupOrWorldPermissionBits == 0) return true;

      final parent = current.parent;
      if (parent.path == current.path) return false;
      current = parent;
    }
  }

  Future<Directory> ensureDateDirectory(
    DateTime date, {
    required String operation,
  }) async {
    final path = dateDirectoryPath(date);
    var directory = await validatedDateDirectory(
      path,
      operation: operation,
      allowMissing: true,
    );
    if (directory != null) return directory;

    await Directory(path).create();
    directory = await validatedDateDirectory(
      path,
      operation: operation,
    );
    return directory!;
  }

  Future<File?> validatedLegacyFile(
    File file, {
    required String operation,
    bool allowMissing = false,
  }) async {
    final root = await validatedSessionDirectory(operation: operation);
    final name = FileLogLayout.basename(file.path);
    if (!FileLogLayout.legacyNamePattern.hasMatch(name) ||
        file.path != FileLogLayout.join(root.path, name)) {
      throw FileLogAccessException(operation: operation);
    }

    final type = await FileSystemEntity.type(
      file.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound && allowMissing) return null;
    if (type != FileSystemEntityType.file) {
      throw FileLogAccessException(operation: operation);
    }
    final canonicalPath = await file.resolveSymbolicLinks();
    if (canonicalPath !=
        FileLogLayout.join(_canonicalSessionDirectory!, name)) {
      throw FileLogAccessException(operation: operation);
    }
    return file;
  }

  Future<File?> validatedDateArtifact(
    File file, {
    required Directory directory,
    required String operation,
    required Set<ManagedFileKind> allowedKinds,
    bool allowMissing = false,
  }) async {
    final validatedDirectory = await validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    final name = FileLogLayout.basename(file.path);
    final kind = FileLogLayout.dateArtifactKind(name);
    if (kind == null ||
        !allowedKinds.contains(kind) ||
        file.path != FileLogLayout.join(validatedDirectory!.path, name)) {
      throw FileLogAccessException(operation: operation);
    }

    final type = await FileSystemEntity.type(
      file.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound && allowMissing) return null;
    if (type != FileSystemEntityType.file) {
      throw FileLogAccessException(operation: operation);
    }
    final canonicalDirectory = FileLogLayout.join(
      _canonicalSessionDirectory!,
      FileLogLayout.basename(directory.path),
    );
    if (await file.resolveSymbolicLinks() !=
        FileLogLayout.join(canonicalDirectory, name)) {
      throw FileLogAccessException(operation: operation);
    }
    return file;
  }

  Future<File?> validatedHistoryFile(
    File file, {
    required String operation,
    bool allowMissing = false,
    Set<ManagedFileKind>? allowedKinds,
  }) {
    final name = FileLogLayout.basename(file.path);
    if (FileLogLayout.legacyNamePattern.hasMatch(name)) {
      if (allowedKinds != null &&
          !allowedKinds.contains(ManagedFileKind.legacy)) {
        throw FileLogAccessException(operation: operation);
      }
      return validatedLegacyFile(
        file,
        operation: operation,
        allowMissing: allowMissing,
      );
    }

    final kind = FileLogLayout.dateArtifactKind(name);
    if (kind == null || allowedKinds != null && !allowedKinds.contains(kind)) {
      throw FileLogAccessException(operation: operation);
    }
    return validatedDateArtifact(
      file,
      directory: file.parent,
      operation: operation,
      allowedKinds: {kind},
      allowMissing: allowMissing,
    );
  }

  Future<int> managedFileLength(
    File file, {
    required String operation,
    bool allowMissing = false,
  }) async {
    final validated = await validatedHistoryFile(
      file,
      operation: operation,
      allowMissing: allowMissing,
    );
    return validated == null ? 0 : validated.length();
  }

  Future<void> deleteManagedFile(
    File file, {
    required String operation,
  }) async {
    final validated = await validatedHistoryFile(
      file,
      operation: operation,
    );
    await validated!.delete();
  }

  Future<List<int>> readBoundedManagedFile(
    File file, {
    required int maxBytes,
    required String operation,
    required Set<ManagedFileKind> allowedKinds,
  }) async {
    final acquired = await acquireReadHandle(
      file,
      maxBytes: maxBytes,
      operation: operation,
      allowedKinds: allowedKinds,
    );
    final builder = BytesBuilder(copy: false);
    try {
      await boundedChunks(
        readHandleChunks(acquired.handle),
        maxBytes: maxBytes,
        operation: operation,
        path: file.path,
      ).forEach(builder.add);
      await validateFileIdentity(
        acquired.file,
        acquired.identity,
        operation: operation,
        allowedKinds: allowedKinds,
      );
      return builder.takeBytes();
    } finally {
      await acquired.handle.close();
    }
  }

  Future<AcquiredReadFile> acquireReadHandle(
    File file, {
    required int maxBytes,
    required String operation,
    required Set<ManagedFileKind> allowedKinds,
  }) async {
    final validated = await validatedHistoryFile(
      file,
      operation: operation,
      allowedKinds: allowedKinds,
    );
    final before = FileIdentity.fromStat(await validated!.stat());
    if (before.size > maxBytes) {
      throw FileLogLimitException(operation: operation, path: file.path);
    }
    final hook = _ioHook;
    if (hook != null) await hook(validated, operation);

    final handle = await validated.open();
    try {
      final afterFile = await validatedHistoryFile(
        validated,
        operation: operation,
        allowedKinds: allowedKinds,
      );
      final after = FileIdentity.fromStat(await afterFile!.stat());
      final openedLength = await handle.length();
      if (before != after || openedLength != after.size) {
        throw FileLogAccessException(operation: operation);
      }
      if (openedLength > maxBytes) {
        throw FileLogLimitException(operation: operation, path: file.path);
      }
      return AcquiredReadFile(
        file: validated,
        handle: handle,
        identity: after,
      );
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Stream<List<int>> readHandleChunks(RandomAccessFile handle) async* {
    while (true) {
      final chunk = await handle.read(_ioChunkSize);
      if (chunk.isEmpty) return;
      yield chunk;
    }
  }

  Stream<List<int>> boundedChunks(
    Stream<List<int>> chunks, {
    required int maxBytes,
    required String operation,
    required String path,
  }) async* {
    var total = 0;
    await for (final chunk in chunks) {
      total += chunk.length;
      if (total > maxBytes) {
        throw FileLogLimitException(
          operation: operation,
          path: path,
        );
      }
      yield chunk;
    }
  }

  Future<String> readLegacyText(File file) async {
    final bytes = await readBoundedManagedFile(
      file,
      maxBytes: _options.maxTotalSize,
      operation: 'readLegacy',
      allowedKinds: const {ManagedFileKind.legacy},
    );
    try {
      return utf8.decode(bytes);
    } on FormatException catch (_, stackTrace) {
      throw FileLogFormatException(
        operation: 'decodeLegacyUtf8',
        path: file.path,
        cause: const FormatException('Invalid file-log UTF-8'),
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteDateDirectoryIfEmpty(
    Directory directory, {
    required String operation,
  }) async {
    final validated = await validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    if (!await validated!.list(followLinks: false).isEmpty) return;
    final beforeDelete = await validatedDateDirectory(
      directory.path,
      operation: operation,
    );
    await beforeDelete!.delete();
  }

  Future<AcquiredWritableFile> createArchiveTemporary(File target) async {
    File? temporary;
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = File('${target.path}.${LogId.generate()}.tmp');
      try {
        await candidate.create(exclusive: true);
        temporary = candidate;
        break;
      } on FileSystemException {
        if (await FileSystemEntity.type(
              candidate.path,
              followLinks: false,
            ) !=
            FileSystemEntityType.notFound) {
          continue;
        }
        rethrow;
      }
    }
    if (temporary == null) {
      throw const FileLogAccessException(operation: 'archiveTemporary');
    }

    RandomAccessFile? handle;
    try {
      final validated = await validatedHistoryFile(
        temporary,
        operation: 'archiveTemporary',
        allowedKinds: const {ManagedFileKind.temporary},
      );
      final before = FileIdentity.fromStat(await validated!.stat());
      if (before.size != 0) {
        throw const FileLogAccessException(operation: 'archiveTemporary');
      }
      final hook = _ioHook;
      if (hook != null) await hook(validated, 'archiveTemporary');
      handle = await validated.open(mode: FileMode.writeOnlyAppend);
      final afterFile = await validatedHistoryFile(
        validated,
        operation: 'archiveTemporary',
        allowedKinds: const {ManagedFileKind.temporary},
      );
      final after = FileIdentity.fromStat(await afterFile!.stat());
      if (before != after || await handle.length() != 0) {
        throw const FileLogAccessException(operation: 'archiveTemporary');
      }
      return AcquiredWritableFile(file: validated, handle: handle);
    } catch (_) {
      if (handle != null) await handle.close();
      final temporaryType = await FileSystemEntity.type(
        temporary.path,
        followLinks: false,
      );
      if (temporaryType == FileSystemEntityType.file) {
        await deleteManagedFile(
          temporary,
          operation: 'archiveTemporaryCleanup',
        );
      } else if (temporaryType == FileSystemEntityType.link) {
        await Link(temporary.path).delete();
      }
      rethrow;
    }
  }

  Future<void> validateFileIdentity(
    File file,
    FileIdentity expected, {
    required String operation,
    required Set<ManagedFileKind> allowedKinds,
  }) async {
    final validated = await validatedHistoryFile(
      file,
      operation: operation,
      allowedKinds: allowedKinds,
    );
    final current = FileIdentity.fromStat(await validated!.stat());
    if (current != expected) {
      throw FileLogAccessException(operation: operation);
    }
  }
}

final class AcquiredReadFile {
  const AcquiredReadFile({
    required this.file,
    required this.handle,
    required this.identity,
  });

  final File file;
  final RandomAccessFile handle;
  final FileIdentity identity;
}

final class AcquiredWritableFile {
  const AcquiredWritableFile({
    required this.file,
    required this.handle,
  });

  final File file;
  final RandomAccessFile handle;
}

@immutable
final class FileIdentity {
  const FileIdentity({
    required this.size,
    required this.mode,
    required this.changed,
    required this.modified,
  });

  factory FileIdentity.fromStat(FileStat stat) => FileIdentity(
        size: stat.size,
        mode: stat.mode,
        changed: stat.changed,
        modified: stat.modified,
      );

  final int size;
  final int mode;
  final DateTime changed;
  final DateTime modified;

  @override
  bool operator ==(Object other) =>
      other is FileIdentity &&
      other.size == size &&
      other.mode == mode &&
      other.changed == changed &&
      other.modified == modified;

  @override
  int get hashCode => Object.hash(size, mode, changed, modified);
}
