import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks up from [start] to the directory holding `version.config`.
///
/// Returns null when no ancestor qualifies, so the caller decides how to
/// report a run from outside the repository.
String? findRepoRoot(String start) {
  var directory = p.absolute(start);
  while (true) {
    if (File(p.join(directory, 'version.config')).existsSync()) {
      return directory;
    }
    final parent = p.dirname(directory);
    if (parent == directory) {
      return null;
    }
    directory = parent;
  }
}

/// Paths of the directories under `packages/` in [repoRoot], sorted.
///
/// Returns an empty list when `packages/` does not exist.
List<String> packageDirectories(String repoRoot) {
  final packages = Directory(p.join(repoRoot, 'packages'));
  if (!packages.existsSync()) {
    return const [];
  }
  return packages
      .listSync()
      .whereType<Directory>()
      .map((directory) => directory.path)
      .toList()
    ..sort();
}
