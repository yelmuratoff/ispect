import 'dart:io';

import 'package:path/path.dart' as p;

/// The packages `bash/tests/release_prep_test.sh` builds into its fixture.
const List<String> releaseFixturePackages = [
  'ispect',
  'ispect_layout',
  'ispectify',
  'ispectify_bloc',
  'ispectify_db',
  'ispectify_dio',
  'ispectify_http',
  'ispectify_riverpod',
  'ispectify_ws',
];

/// The root changelog a fresh fixture carries, and the exact content a carry
/// or a recovery must move onto the new version.
String fixtureChangelog(String version) => '''
# Changelog

## $version

### Improvements

- Carry these release notes unchanged.
''';

/// Builds the release fixture repository under [destination] and returns its
/// path.
String createReleaseFixture({
  required String destination,
  String version = '7.0.0-dev.1',
  String? changelogVersion,
}) {
  final repo = destination;

  writeFixtureFile(p.join(repo, 'version.config'), 'VERSION=$version\n');
  writeFixtureFile(
    p.join(repo, 'CHANGELOG.md'),
    fixtureChangelog(changelogVersion ?? version),
  );
  writeFixtureFile(
    p.join(repo, 'README.md'),
    '# Stale fixture README\n\nispect: ^0.0.1\n',
  );
  writeFixtureFile(
    p.join(repo, 'docs', 'readme', 'root.md'),
    '# Fixture root\n\nRoot release {{version}} for {{package}}.\n',
  );
  writeFixtureFile(p.join(repo, 'docs', 'guide.md'), '# Fixture guide\n');
  Directory(p.join(repo, 'docs', 'readme', '_partials'))
      .createSync(recursive: true);

  for (final package in releaseFixturePackages) {
    writeFixtureFile(p.join(repo, 'packages', package, 'pubspec.yaml'), '''
name: $package
description: $package fixture
version: 0.0.1
repository: https://example.invalid/ispect
environment:
  sdk: ^3.6.0
''');
    writeFixtureFile(p.join(repo, 'packages', package, 'CHANGELOG.md'), '''
# Changelog

## 0.0.1

### Improvements

- Stale package notes.
''');
    writeFixtureFile(
      p.join(repo, 'packages', package, 'README.md'),
      '# Stale $package README\n',
    );
    writeFixtureFile(
      p.join(repo, 'docs', 'readme', '$package.md'),
      '# $package fixture\n\nPackage {{package}} release {{version}}.\n',
    );
  }

  writeFixtureFile(p.join(repo, 'web_logs_viewer', 'pubspec.yaml'), '''
name: web_logs_viewer
environment:
  sdk: ^3.6.0
dependencies:
  ispect: ^0.0.1
''');
  writeFixtureFile(
    p.join(repo, 'web_logs_viewer', 'pubspec.lock'),
    'fixture-lock: 0.0.1\n',
  );
  writeFixtureFile(p.join(repo, 'llms.txt'), 'stale llms index\n');

  return repo;
}

/// Writes a fake `$EDITOR` that appends a marker line to the file it is given
/// and exits with [exitStatus], asserting it kept its own arguments.
String writeFakeEditor(String path, {int exitStatus = 0}) {
  writeFixtureFile(path, '''
#!/usr/bin/env bash

set -euo pipefail

[[ \${1:-} == "--wait" ]]
[[ \${2:-} == "CHANGELOG.md" ]]
printf '\\n### Editor\\n\\n- Editor arguments were preserved.\\n' >> "\$2"
exit $exitStatus
''');
  makeExecutable(path);
  return path;
}

void writeFixtureFile(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void makeExecutable(String path) {
  final result = Process.runSync('chmod', ['+x', path]);
  if (result.exitCode != 0) {
    throw StateError('cannot make $path executable: ${result.stderr}');
  }
}

void copyTree(String from, String to) {
  Directory(to).createSync(recursive: true);
  for (final entity
      in Directory(from).listSync(recursive: true, followLinks: false)) {
    final target = p.join(to, p.relative(entity.path, from: from));
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is Link) {
      Directory(p.dirname(target)).createSync(recursive: true);
      Link(target).createSync(entity.targetSync());
    } else if (entity is File) {
      Directory(p.dirname(target)).createSync(recursive: true);
      entity.copySync(target);
      final mode = entity.statSync().mode & 0xFFF;
      Process.runSync(
        'chmod',
        [mode.toRadixString(8).padLeft(4, '0'), target],
      );
    }
  }
}

/// Every regular file under [root], keyed by its repository-relative path.
Map<String, List<int>> treeSnapshot(String root) => {
      for (final file in Directory(root)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>())
        p.relative(file.path, from: root): file.readAsBytesSync(),
    };
