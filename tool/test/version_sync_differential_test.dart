@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:ispect_tool/src/core/version_sync.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs `bash/update_versions.sh` and [runVersionSync] over identical copies of
/// one fixture repository and requires the two to be indistinguishable: same
/// exit code, same stdout, same stderr, and byte-identical trees.
///
/// Delete this file together with `bash/update_versions.sh`.
void main() {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null) {
    throw StateError('differential test must run inside the repository');
  }
  final script = File(p.join(repoRoot, 'bash', 'update_versions.sh'));
  final semverLibrary = File(p.join(repoRoot, 'bash', 'lib', 'semver.sh'));

  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-version-sync-');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  /// Builds the fixture, copies it twice, runs both implementations, and
  /// asserts they agree on everything observable. [comparesStdout] drops the
  /// stdout comparison for the usage block, the one message that names the
  /// bash script rather than the port.
  void expectAgreement(
    String scenario,
    List<String> arguments, {
    void Function(String repo) customize = _noCustomization,
    bool comparesStdout = true,
  }) {
    if (!script.existsSync()) {
      markTestSkipped('bash/update_versions.sh is gone; parity no longer '
          'applies');
      return;
    }

    final source = p.join(workspace.path, scenario, 'source');
    _writeFixture(source, script, semverLibrary);
    customize(source);

    final bashRepo = p.join(workspace.path, scenario, 'bash');
    final dartRepo = p.join(workspace.path, scenario, 'dart');
    _copyTree(source, bashRepo);
    _copyTree(source, dartRepo);

    final bashRun = Process.runSync(
      'bash',
      [p.join(bashRepo, 'bash', 'update_versions.sh'), ...arguments],
      workingDirectory: bashRepo,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    final dartOut = StringBuffer();
    final dartErr = StringBuffer();
    final dartExitCode = runVersionSync(
      repoRoot: dartRepo,
      arguments: arguments,
      out: dartOut,
      err: dartErr,
    );

    expect(
      dartExitCode,
      bashRun.exitCode,
      reason: 'exit codes differ\nbash stderr:\n${bashRun.stderr}\n'
          'dart stderr:\n$dartErr',
    );
    if (comparesStdout) {
      expect(dartOut.toString(), bashRun.stdout, reason: 'stdout differs');
    }
    expect(dartErr.toString(), bashRun.stderr, reason: 'stderr differs');
    _expectIdenticalTrees(bashRepo, dartRepo);
  }

  test('a patch bump of a dot-form prerelease lands identically', () {
    expectAgreement('prerelease-patch', ['--bump', 'patch']);
  });

  test('a patch bump of a stable version lands identically', () {
    expectAgreement(
      'stable-patch',
      ['--bump', 'patch'],
      customize: (repo) => _write(
        p.join(repo, 'version.config'),
        'VERSION=1.2.3\n',
      ),
    );
  });

  test('a minor bump leaves the prerelease behind identically', () {
    expectAgreement('minor', ['--bump', 'minor']);
  });

  test('a major bump lands identically', () {
    expectAgreement('major', ['--bump', 'major']);
  });

  test('a dry run previews the same changes and writes nothing', () {
    expectAgreement('dry-run', ['--dry-run', '--bump', 'patch']);
  });

  test('a malformed lockfile stanza aborts before either writes', () {
    expectAgreement(
      'malformed-lockfile',
      ['--bump', 'patch'],
      customize: (repo) => _write(
        p.join(repo, 'web_logs_viewer', 'pubspec.lock'),
        '''
packages:
  ispect:
    dependency: "direct main"
    description:
      path: "../packages/ispect"
      relative: true
    source: path
''',
      ),
    );
  });

  test('a repo without local web path dependencies leaves the lockfile alone',
      () {
    expectAgreement(
      'no-local-web-paths',
      const [],
      customize: (repo) {
        _write(p.join(repo, 'web_logs_viewer', 'pubspec.yaml'), '''
name: web_logs_viewer
dependencies:
  flutter:
    sdk: flutter
  ispect: ^0.0.1
  ispectify: ^0.0.1
''');
        _write(
          p.join(repo, 'web_logs_viewer', 'pubspec.lock'),
          'fixture-lock: preserved\n',
        );
      },
    );
  });

  test('a missing lockfile fails the same way on both sides', () {
    expectAgreement(
      'missing-lockfile',
      ['--bump', 'patch'],
      customize: (repo) =>
          File(p.join(repo, 'web_logs_viewer', 'pubspec.lock')).deleteSync(),
    );
  });

  test('an already synced repository reports the same no-op', () {
    expectAgreement(
      'already-synced',
      const [],
      customize: (repo) {
        _write(p.join(repo, 'version.config'), 'VERSION=0.0.1\n');
        _write(p.join(repo, 'web_logs_viewer', 'pubspec.yaml'), '''
name: web_logs_viewer
dependency_overrides:
  ispect:
    path: ../packages/ispect
dependencies:
  ispect: ^0.0.1
  ispectify: ^0.0.1
''');
      },
    );
  });

  test('sibling packages are rewritten in the same order', () {
    expectAgreement(
      'many-packages',
      ['--bump', 'patch'],
      customize: (repo) {
        _write(p.join(repo, 'packages', 'ispect_layout', 'pubspec.yaml'), '''
name: ispect_layout
version: 0.0.1
dependencies:
  ispectify: ^0.0.1
dev_dependencies:
  ispect: ^0.0.1
''');
        _write(p.join(repo, 'packages', 'ispectify_ws', 'pubspec.yaml'), '''
name: ispectify_ws
version: 0.0.1
dependencies:
  ispectify: ^0.0.1
''');
      },
    );
  });

  test('a caret constraint under dependency_overrides survives both runs', () {
    expectAgreement(
      'overridden-constraint',
      ['--bump', 'patch'],
      customize: (repo) => _write(
        p.join(repo, 'packages', 'ispect', 'pubspec.yaml'),
        '''
name: ispect
version: 0.0.1
dependencies:
  ispectify: ^0.0.1
dev_dependencies:
  ispectify: ^0.0.1
dependency_overrides:
  ispectify: ^0.0.1
''',
      ),
    );
  });

  test('a package without a name fails the same way on both sides', () {
    expectAgreement(
      'unnamed-package',
      const [],
      customize: (repo) => _write(
        p.join(repo, 'packages', 'broken', 'pubspec.yaml'),
        'version: 0.0.1\n',
      ),
    );
  });

  test('a missing version.config fails the same way on both sides', () {
    expectAgreement(
      'missing-version-config',
      const [],
      customize: (repo) => File(p.join(repo, 'version.config')).deleteSync(),
    );
  });

  test('an unknown argument is rejected with the same exit code', () {
    expectAgreement('unknown-argument', ['--nope'], comparesStdout: false);
  });

  test('an unknown bump kind is rejected with the same exit code', () {
    expectAgreement('unknown-bump-kind', ['--bump', 'huge']);
  });

  test('a bump without a kind is rejected with the same exit code', () {
    expectAgreement('bump-without-kind', ['--bump']);
  });

  test('a glued prerelease counter warns before the same sync', () {
    expectAgreement(
      'glued-counter',
      ['--bump', 'patch'],
      customize: (repo) => _write(
        p.join(repo, 'version.config'),
        'VERSION=1.2.3-dev11\n',
      ),
    );
  });
}

void _noCustomization(String repo) {}

void _writeFixture(String repo, File script, File semverLibrary) {
  Directory(repo).createSync(recursive: true);
  _write(
    p.join(repo, 'bash', 'update_versions.sh'),
    script.readAsStringSync(),
  );
  _write(
    p.join(repo, 'bash', 'lib', 'semver.sh'),
    semverLibrary.readAsStringSync(),
  );

  _write(p.join(repo, 'version.config'), 'VERSION=1.2.3-dev.1\n');
  _write(p.join(repo, 'version.config.tmp'), 'pre-existing version temp\n');
  _write(
    p.join(repo, 'README.md'),
    'README must remain byte-for-byte unchanged: ispect: ^0.0.1\n',
  );

  _write(p.join(repo, 'packages', 'ispect', 'pubspec.yaml'), '''
name: ispect
version: 0.0.1
dependencies:
  ispectify: ^0.0.1
dependency_overrides:
  ispectify:
    path: ../ispectify
''');
  _write(
    p.join(repo, 'packages', 'ispect', 'pubspec.yaml.tmp'),
    'pre-existing pubspec temp\n',
  );
  _write(p.join(repo, 'packages', 'ispect', 'example', 'pubspec.yaml'), '''
name: ispect_example
dependencies:
  ispect: ^0.0.1
  ispectify: ^0.0.1
dependency_overrides:
  ispect:
    path: ..
  ispectify:
    path: ../../ispectify
''');
  _write(p.join(repo, 'packages', 'ispectify', 'pubspec.yaml'), '''
name: ispectify
version: 0.0.1
environment:
  sdk: ^3.6.0
''');

  _write(p.join(repo, 'web_logs_viewer', 'pubspec.yaml'), '''
name: web_logs_viewer
dependency_overrides:
  ispect:
    path: ../packages/ispect
  ispectify:
    path: ../packages/ispectify
dependencies:
  flutter:
    sdk: flutter
  ispect: ^0.0.1
  ispectify: ^0.0.1
  collection: ^1.19.1
''');
  _write(p.join(repo, 'web_logs_viewer', 'pubspec.lock'), '''
# Generated by pub
packages:
  collection:
    dependency: "direct main"
    description:
      name: collection
      sha256: preserved-hosted-checksum
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  fixture_helper:
    dependency: transitive
    description:
      path: "../fixture_helper"
      relative: true
    source: path
    version: "9.9.9"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  ispect:
    dependency: "direct main"
    description:
      path: "../packages/ispect"
      relative: true
    source: path
    version: "0.0.1"
  ispectify:
    dependency: "direct main"
    description:
      path: "../packages/ispectify"
      relative: true
    source: path
    version: "0.0.1"
sdks:
  dart: ">=3.6.0 <4.0.0"
''');
}

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void _copyTree(String from, String to) {
  Directory(to).createSync(recursive: true);
  for (final entity in Directory(from).listSync(recursive: true)) {
    final target = p.join(to, p.relative(entity.path, from: from));
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      Directory(p.dirname(target)).createSync(recursive: true);
      entity.copySync(target);
    }
  }
}

Map<String, List<int>> _snapshot(String root) => {
      for (final file
          in Directory(root).listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: root): file.readAsBytesSync(),
    };

void _expectIdenticalTrees(String expected, String actual) {
  final expectedFiles = _snapshot(expected);
  final actualFiles = _snapshot(actual);

  expect(
    actualFiles.keys.toSet(),
    expectedFiles.keys.toSet(),
    reason: 'the two trees hold different files',
  );

  final differing = [
    for (final entry in expectedFiles.entries)
      if (!_sameBytes(entry.value, actualFiles[entry.key]))
        '--- ${entry.key} ---\n'
            'bash:\n${utf8.decode(entry.value)}\n'
            'dart:\n${utf8.decode(actualFiles[entry.key] ?? const [])}',
  ];
  expect(differing, isEmpty, reason: differing.join('\n'));
}

bool _sameBytes(List<int> left, List<int>? right) {
  if (right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
