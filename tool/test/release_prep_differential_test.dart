@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/release_prep.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'release_fixture.dart';

/// Runs `bash/release_prep.sh` and [runReleasePrep] over identical copies of
/// one fixture repository and requires the two to agree on the exit code and
/// on every byte of the resulting tree.
///
/// stdout and stderr are deliberately not compared: the two orchestrators
/// drive different generators, whose progress reporting is their own contract.
///
/// Delete this file together with `bash/release_prep.sh`.
void main() {
  final sourceRepo = findRepoRoot(Directory.current.path);
  if (sourceRepo == null) {
    throw StateError('differential test must run inside the repository');
  }
  final script = File(p.join(sourceRepo, 'bash', 'release_prep.sh'));

  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-release-diff-');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  /// Builds the fixture, copies it twice, runs both orchestrators, and asserts
  /// they agree. [customize] runs against each copy, so a scenario can plant a
  /// symlink that must not be duplicated through the shared source.
  Future<void> expectAgreement(
    String scenario,
    List<String> arguments, {
    String version = '7.0.0-dev.1',
    String? changelogVersion,
    void Function(String repo)? customize,
  }) async {
    if (!script.existsSync()) {
      markTestSkipped('bash/release_prep.sh is gone; parity no longer applies');
      return;
    }

    final source = p.join(workspace.path, scenario, 'source');
    createReleaseFixture(
      sourceRepo: sourceRepo,
      destination: source,
      version: version,
      changelogVersion: changelogVersion,
    );

    final bashRepo = p.join(workspace.path, scenario, 'bash-side');
    final dartRepo = p.join(workspace.path, scenario, 'dart-side');
    copyTree(source, bashRepo);
    copyTree(source, dartRepo);
    customize?.call(bashRepo);
    customize?.call(dartRepo);

    final bashTemp = Directory(p.join(workspace.path, scenario, 'bash-tmp'))
      ..createSync(recursive: true);
    final dartTemp = Directory(p.join(workspace.path, scenario, 'dart-tmp'))
      ..createSync(recursive: true);

    final bashRun = Process.runSync(
      p.join(bashRepo, 'bash', 'release_prep.sh'),
      arguments,
      workingDirectory: bashRepo,
      environment: {'TMPDIR': bashTemp.path},
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    final dartOut = StringBuffer();
    final dartErr = StringBuffer();
    final dartExitCode = await runReleasePrep(
      repoRoot: dartRepo,
      arguments: arguments,
      out: dartOut,
      err: dartErr,
      tempRoot: dartTemp,
      environment: const {'PATH': ''},
    );

    expect(
      dartExitCode,
      bashRun.exitCode,
      reason: 'exit codes differ\nbash stdout:\n${bashRun.stdout}\n'
          'bash stderr:\n${bashRun.stderr}\n'
          'dart stdout:\n$dartOut\ndart stderr:\n$dartErr',
    );
    _expectIdenticalTrees(bashRepo, dartRepo);
    expect(bashTemp.listSync(), isEmpty, reason: 'bash retained a snapshot');
    expect(dartTemp.listSync(), isEmpty, reason: 'dart retained a snapshot');
  }

  test('a default patch bump lands identically', () async {
    await expectAgreement('patch-bump', const []);
  });

  test('an explicit patch bump lands identically', () async {
    await expectAgreement('explicit-patch', const ['--bump', 'patch']);
  });

  test('a minor bump lands identically', () async {
    await expectAgreement('minor-bump', const ['minor']);
  });

  test('--skip-bump lands identically', () async {
    await expectAgreement('skip-bump', const ['--skip-bump']);
  });

  test('--carry-changelog lands identically', () async {
    await expectAgreement('carry-changelog', const ['--carry-changelog']);
  });

  test('--skip-bump --recover-changelog lands identically', () async {
    await expectAgreement(
      'recover-changelog',
      const ['--skip-bump', '--recover-changelog'],
      version: '7.0.0-dev.2',
      changelogVersion: '7.0.0-dev.1',
    );
  });

  test('a rejected recovery over stable history fails identically', () async {
    await expectAgreement(
      'stable-recovery',
      const ['--skip-bump', '--recover-changelog'],
      version: '7.0.1',
      changelogVersion: '7.0.0',
    );
  });

  test('a recovery with the target already present fails identically',
      () async {
    await expectAgreement(
      'existing-recovery-target',
      const ['--skip-bump', '--recover-changelog'],
    );
  });

  test('conflicting bump modes fail identically', () async {
    await expectAgreement(
      'conflicting-bump',
      const ['patch', '--bump', 'minor'],
    );
  });

  test('a bump kind combined with --skip-bump fails identically', () async {
    await expectAgreement('bump-and-skip', const ['minor', '--skip-bump']);
  });

  test('--carry-changelog combined with --skip-bump fails identically',
      () async {
    await expectAgreement(
      'carry-and-skip',
      const ['--skip-bump', '--carry-changelog'],
    );
  });

  test('--recover-changelog without --skip-bump fails identically', () async {
    await expectAgreement(
        'recover-without-skip', const ['--recover-changelog']);
  });

  test('an unknown argument is rejected with the same exit code', () async {
    await expectAgreement('unknown-argument', const ['--nope']);
  });

  test('a bump without a kind is rejected with the same exit code', () async {
    await expectAgreement('bump-without-kind', const ['--bump']);
  });

  test('an invalid VERSION fails identically before any write', () async {
    await expectAgreement(
      'invalid-version',
      const ['--skip-bump'],
      customize: (repo) => writeFixtureFile(
        p.join(repo, 'version.config'),
        'VERSION=not-a-version\n',
      ),
    );
  });

  test('a changelog with the wrong first heading fails identically', () async {
    await expectAgreement(
      'bad-changelog',
      const ['--skip-bump'],
      customize: (repo) => writeFixtureFile(
        p.join(repo, 'CHANGELOG.md'),
        '# Notes\n\n## 7.0.0-dev.1\n',
      ),
    );
  });

  test('a symlinked managed target is refused identically', () async {
    await expectAgreement(
      'symlinked-target',
      const ['--skip-bump'],
      customize: (repo) {
        final outside = p.normalize(p.join(repo, '..', 'outside-readme.md'));
        writeFixtureFile(outside, 'outside sentinel\n');
        File(p.join(repo, 'README.md')).deleteSync();
        Link(p.join(repo, 'README.md')).createSync(outside);
      },
    );
  });

  test('a managed target that is a directory is refused identically', () async {
    await expectAgreement(
      'directory-target',
      const ['--skip-bump'],
      customize: (repo) {
        File(p.join(repo, 'llms.txt')).deleteSync();
        Directory(p.join(repo, 'llms.txt')).createSync();
      },
    );
  });

  test('a duplicated target section fails identically', () async {
    await expectAgreement(
      'duplicate-section',
      const ['--skip-bump'],
      customize: (repo) => writeFixtureFile(
        p.join(repo, 'CHANGELOG.md'),
        '# Changelog\n\n## 7.0.0-dev.1\n\n- one\n\n## 7.0.0-dev.1\n\n- two\n',
      ),
    );
  });
}

void _expectIdenticalTrees(String expected, String actual) {
  final expectedFiles = treeSnapshot(expected);
  final actualFiles = treeSnapshot(actual);

  expect(
    actualFiles.keys.toSet(),
    expectedFiles.keys.toSet(),
    reason: 'the two trees hold different files',
  );

  final differing = [
    for (final entry in expectedFiles.entries)
      if (!_sameBytes(entry.value, actualFiles[entry.key]))
        '--- ${entry.key} ---\n'
            'bash:\n${_text(entry.value)}\n'
            'dart:\n${_text(actualFiles[entry.key] ?? const [])}',
  ];
  expect(differing, isEmpty, reason: differing.join('\n'));
}

String _text(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return '<${bytes.length} binary bytes>';
  }
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
