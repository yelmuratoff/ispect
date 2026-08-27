import 'dart:io';

import 'package:path/path.dart' as p;

import 'exceptions.dart';

const String _snapshotPrefix = 'ispect-release-prep.';
const String _manifestName = 'existing';
const String _filesDirectory = 'files';

/// Snapshots a fixed set of repository files and restores every one of them to
/// its exact pre-run state when any step of a run fails.
///
/// A transaction runs in three phases. [begin] validates the managed paths and
/// copies the ones that exist into a snapshot directory; [commit] declares the
/// run successful; [rollback] puts the tree back. [dispose] removes the
/// snapshot, and refuses to remove a directory that is not one it created.
///
/// Paths are repository-relative. A path that escapes the repository, is a
/// symlink, resolves through a symlinked ancestor, or names anything other
/// than a regular file is rejected before the first byte is copied.
final class ManagedFileTransaction {
  ManagedFileTransaction({
    required this.repoRoot,
    required Iterable<String> targets,
    required this.err,
    Directory? tempRoot,
  })  : targets = List.unmodifiable(targets),
        _tempRoot = tempRoot ?? Directory.systemTemp;

  final String repoRoot;

  /// Repository-relative paths the run may rewrite, in validation order.
  final List<String> targets;

  final StringSink err;
  final Directory _tempRoot;

  Directory? _snapshot;
  var _committed = false;

  /// The snapshot directory, or null before [begin] and after [dispose].
  String? get snapshotPath => _snapshot?.path;

  /// Whether a snapshot exists that no [commit] has released.
  bool get isPending => _snapshot != null && !_committed;

  /// Rejects every managed path a run must not touch, before it writes any.
  ///
  /// Throws [ManagedPathException] for the first path that escapes the
  /// repository, is or resolves through a symlink, exists as something other
  /// than a regular file, or has an existing ancestor that is not a directory.
  void validate() {
    for (final target in targets) {
      if (_escapesRepository(target)) {
        throw ManagedPathException(
          'Managed path escapes the repository: $target',
          path: target,
        );
      }
      if (_isLink(target) || _hasSymlinkAncestor(target)) {
        throw ManagedPathException(
          'Managed paths cannot contain symlinks: $target',
          path: target,
        );
      }
      if (_typeOf(target) == FileSystemEntityType.directory) {
        throw ManagedPathException(
          'Managed target must be a regular file: $target',
          path: target,
        );
      }
      for (final ancestor in _ancestors(target)) {
        final type = _typeOf(ancestor);
        if (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory) {
          throw ManagedPathException(
            'Managed path parent must be a directory: $ancestor',
            path: ancestor,
          );
        }
      }
    }
  }

  /// Validates the managed paths, then copies the existing ones aside.
  ///
  /// Throws [ManagedPathException] when [validate] rejects a path, leaving the
  /// working tree and the temp directory untouched.
  void begin() {
    validate();

    final snapshot = _tempRoot.createTempSync(_snapshotPrefix);
    Directory(p.join(snapshot.path, _filesDirectory)).createSync();

    final existing = <String>[];
    for (final target in targets) {
      if (_typeOf(target, followLinks: false) ==
          FileSystemEntityType.notFound) {
        continue;
      }
      final copy = File(p.join(snapshot.path, _filesDirectory, target));
      copy.parent.createSync(recursive: true);
      _copyPreservingMode(File(_absolute(target)), copy);
      existing.add(target);
    }
    File(p.join(snapshot.path, _manifestName))
        .writeAsStringSync(existing.map((path) => '$path\n').join());

    _snapshot = snapshot;
  }

  /// Declares the run successful, so [rollback] is no longer owed.
  void commit() {
    _committed = true;
  }

  /// Restores every managed file to the state [begin] recorded.
  ///
  /// A file that existed is rewritten from the snapshot; a file the run
  /// created is removed. Returns false when any target could not be restored,
  /// having reported each failure and attempted the remaining targets — a
  /// partial rollback still recovers everything it can.
  bool rollback() {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return true;
    }

    final manifest = File(p.join(snapshot.path, _manifestName));
    final Set<String> existedBefore;
    try {
      existedBefore = manifest.readAsLinesSync().toSet();
    } on FileSystemException {
      err.writeln('[ERR] Recovery snapshot manifest is not readable');
      return false;
    }

    var restored = true;
    for (final target in targets) {
      if (_hasSymlinkAncestor(target)) {
        err.writeln('[ERR] Cannot safely restore through a symlink: $target');
        restored = false;
        continue;
      }

      final existed = existedBefore.contains(target);
      final absolute = _absolute(target);
      if (existed) {
        try {
          Directory(p.dirname(absolute)).createSync(recursive: true);
        } on FileSystemException {
          err.writeln('[ERR] Cannot recreate parent directory for $target');
          restored = false;
          continue;
        }
      }

      final type = _typeOf(target, followLinks: false);
      if (type != FileSystemEntityType.notFound) {
        if (type == FileSystemEntityType.directory) {
          err.writeln('[ERR] Cannot replace directory while restoring $target');
          restored = false;
          continue;
        }
        try {
          File(absolute).deleteSync();
        } on FileSystemException {
          err.writeln(
            '[ERR] Cannot remove changed target during rollback: $target',
          );
          restored = false;
          continue;
        }
      }

      if (!existed) {
        continue;
      }
      try {
        _copyPreservingMode(
          File(p.join(snapshot.path, _filesDirectory, target)),
          File(absolute),
        );
      } on FileSystemException {
        err.writeln('[ERR] Cannot restore $target from snapshot');
        restored = false;
      }
    }
    return restored;
  }

  /// Removes the snapshot directory.
  ///
  /// Returns false without deleting anything when the recorded path is not one
  /// this class created, so a corrupted path never turns into a recursive
  /// delete of an unrelated directory.
  bool dispose() {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.existsSync()) {
      _snapshot = null;
      return true;
    }
    if (!_isOwnSnapshot(snapshot.path)) {
      err.writeln(
        '[ERR] Refusing to remove unexpected snapshot path: ${snapshot.path}',
      );
      return false;
    }
    snapshot.deleteSync(recursive: true);
    _snapshot = null;
    return true;
  }

  bool _isOwnSnapshot(String path) {
    if (!p.basename(path).startsWith(_snapshotPrefix)) {
      return false;
    }
    final parent = Directory(p.dirname(path));
    return parent.existsSync() &&
        p.equals(
          parent.resolveSymbolicLinksSync(),
          _tempRoot.resolveSymbolicLinksSync(),
        );
  }

  String _absolute(String target) => p.join(repoRoot, target);

  FileSystemEntityType _typeOf(String target, {bool followLinks = true}) =>
      FileSystemEntity.typeSync(_absolute(target), followLinks: followLinks);

  bool _isLink(String target) => FileSystemEntity.isLinkSync(_absolute(target));

  bool _hasSymlinkAncestor(String target) =>
      _ancestors(target).any((ancestor) => _isLink(ancestor));

  /// The directories between [target] and the repository root, nearest first.
  ///
  /// The root itself is excluded: the bash original walks a relative path and
  /// stops at `.`, so a repository reached through a symlink — every temp
  /// directory on macOS — stays usable.
  Iterable<String> _ancestors(String target) sync* {
    var ancestor = p.dirname(target);
    while (ancestor != '.' && ancestor != '/' && ancestor.isNotEmpty) {
      yield ancestor;
      ancestor = p.dirname(ancestor);
    }
  }
}

/// Whether [target] would resolve outside the repository it is relative to.
bool _escapesRepository(String target) =>
    target.startsWith('/') ||
    target.startsWith('../') ||
    target.contains('/../') ||
    target.endsWith('/..');

void _copyPreservingMode(File from, File to) {
  to.writeAsBytesSync(from.readAsBytesSync());
  final mode = from.statSync().mode & 0xFFF;
  if (to.statSync().mode & 0xFFF == mode) {
    return;
  }
  final chmod = Process.runSync(
    'chmod',
    [mode.toRadixString(8).padLeft(4, '0'), to.path],
  );
  if (chmod.exitCode != 0) {
    throw FileSystemException('Cannot restore permissions', to.path);
  }
}
