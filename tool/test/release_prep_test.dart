@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/next_version.dart';
import 'package:ispect_tool/src/core/release_prep.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'release_fixture.dart';

/// The behaviour contract `bash/tests/release_prep_test.sh` pins, scenario for
/// scenario, exercised through [runReleasePrep] instead of the script.
void main() {
  final sourceRepo = findRepoRoot(Directory.current.path);
  if (sourceRepo == null) {
    throw StateError('release prep tests must run inside the repository');
  }

  late Directory workspace;
  late Directory runtimeTemp;
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-release-prep-');
    runtimeTemp = Directory(p.join(workspace.path, 'runtime'))..createSync();
    out = StringBuffer();
    err = StringBuffer();
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  String fixture(
    String name, {
    String version = '7.0.0-dev.1',
    String? changelogVersion,
  }) =>
      createReleaseFixture(
        destination: p.join(workspace.path, name, 'repo'),
        version: version,
        changelogVersion: changelogVersion,
      );

  Future<int> release(
    String repo,
    List<String> arguments, {
    ReleaseSteps Function(ReleaseSteps)? wrapSteps,
    Map<String, String>? environment,
  }) {
    final base = DartReleaseSteps(repoRoot: repo, out: out, err: err);
    return runReleasePrep(
      repoRoot: repo,
      arguments: arguments,
      out: out,
      err: err,
      steps: wrapSteps == null ? base : wrapSteps(base),
      tempRoot: runtimeTemp,
      environment: environment ?? {'PATH': Platform.environment['PATH'] ?? ''},
    );
  }

  String read(String repo, String relative) =>
      File(p.join(repo, relative)).readAsStringSync();

  group('version synchronization', () {
    test('--skip-bump leaves version.config untouched', () async {
      final repo = fixture('skip-bump-version');

      await expectLater(release(repo, ['--skip-bump']), completion(0));
      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.1\n');
    });

    test('--skip-bump synchronizes changelog, README, and llms.txt', () async {
      final repo = fixture('skip-bump');

      await expectLater(release(repo, ['--skip-bump']), completion(0));
      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.1\n');

      final rootChangelog = read(repo, 'CHANGELOG.md');
      for (final package in releaseFixturePackages) {
        expect(
          read(repo, 'packages/$package/pubspec.yaml'),
          contains('version: 7.0.0-dev.1'),
          reason: package,
        );
        expect(
          read(repo, 'packages/$package/CHANGELOG.md'),
          rootChangelog,
          reason: package,
        );
      }

      expect(
        read(repo, 'README.md'),
        contains('Root release 7.0.0-dev.1 for ispect.'),
      );
      expect(
        read(repo, 'packages/ispectify_ws/README.md'),
        contains('Package ispectify_ws release 7.0.0-dev.1.'),
      );
      expect(read(repo, 'llms.txt'), contains('- Version: 7.0.0-dev.1'));
      expect(read(repo, 'llms.txt'), isNot(contains('stale llms index')));
    });
  });

  group('changelog section handling', () {
    test('--skip-bump recovers notes from an interrupted carry', () async {
      final repo = fixture(
        'recover-carry',
        version: '7.0.0-dev.2',
        changelogVersion: '7.0.0-dev.1',
      );

      await expectLater(
        release(repo, ['--skip-bump', '--recover-changelog']),
        completion(0),
      );

      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.2\n');
      expect(read(repo, 'CHANGELOG.md'), fixtureChangelog('7.0.0-dev.2'));
      expect(read(repo, 'CHANGELOG.md'), isNot(contains('### Added')));
      for (final package in releaseFixturePackages) {
        expect(
          read(repo, 'packages/$package/CHANGELOG.md'),
          fixtureChangelog('7.0.0-dev.2'),
          reason: package,
        );
      }
    });

    test('--skip-bump preserves prerelease history without recovery', () async {
      final repo = fixture(
        'preserve-prerelease',
        version: '7.0.0-dev.2',
        changelogVersion: '7.0.0-dev.1',
      );

      await expectLater(release(repo, ['--skip-bump']), completion(0));

      final changelog = read(repo, 'CHANGELOG.md');
      expect(changelog, contains('## 7.0.0-dev.2'));
      expect(changelog, contains('## 7.0.0-dev.1'));
      expect(changelog, contains('- Carry these release notes unchanged.'));
    });

    test('--carry-changelog advances the counter with heading and notes',
        () async {
      final repo = fixture('carry-bump');

      await expectLater(release(repo, ['--carry-changelog']), completion(0));

      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.2\n');
      expect(read(repo, 'CHANGELOG.md'), fixtureChangelog('7.0.0-dev.2'));
      for (final package in releaseFixturePackages) {
        expect(
          read(repo, 'packages/$package/CHANGELOG.md'),
          fixtureChangelog('7.0.0-dev.2'),
          reason: package,
        );
      }
    });

    test('recovery never renames stable changelog history', () async {
      final repo = fixture(
        'stable-recovery',
        version: '7.0.1',
        changelogVersion: '7.0.0',
      );

      await expectLater(
        release(repo, ['--skip-bump', '--recover-changelog']),
        completion(isNot(0)),
      );

      expect(
        err.toString(),
        contains('--recover-changelog requires the immediately previous '
            'prerelease'),
      );
      expect(read(repo, 'CHANGELOG.md'), contains('## 7.0.0'));
      expect(read(repo, 'CHANGELOG.md'), isNot(contains('## 7.0.1')));
    });

    test('recovery requires a missing target section', () async {
      final repo = fixture('existing-recovery-target');

      await expectLater(
        release(repo, ['--skip-bump', '--recover-changelog']),
        completion(isNot(0)),
      );

      expect(
        err.toString(),
        contains('--recover-changelog requires the target section to be '
            'missing'),
      );
      expect(read(repo, 'CHANGELOG.md'), contains('## 7.0.0-dev.1'));
    });
  });

  group('argument validation', () {
    test('conflicting bump modes fail before writes', () async {
      final repo = fixture('conflicting-bump');

      await expectLater(
        release(repo, ['patch', '--bump', 'minor']),
        completion(isNot(0)),
      );

      expect(err.toString(), contains('Specify the bump kind only once'));
      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.1\n');
    });

    test('a bump kind combined with --skip-bump fails before writes', () async {
      final repo = fixture('bump-and-skip');

      await expectLater(
        release(repo, ['minor', '--skip-bump']),
        completion(1),
      );

      expect(
        err.toString(),
        contains('A bump kind cannot be combined with --skip-bump'),
      );
      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.1\n');
    });

    test('--carry-changelog combined with --skip-bump fails before writes',
        () async {
      final repo = fixture('carry-and-skip');

      await expectLater(
        release(repo, ['--skip-bump', '--carry-changelog']),
        completion(1),
      );

      expect(
        err.toString(),
        contains('--carry-changelog cannot be combined with --skip-bump'),
      );
    });

    test('--recover-changelog without --skip-bump fails before writes',
        () async {
      final repo = fixture('recover-without-skip');

      await expectLater(
        release(repo, ['--recover-changelog']),
        completion(1),
      );

      expect(
        err.toString(),
        contains('--recover-changelog requires --skip-bump'),
      );
    });

    test('an unknown argument is rejected with the usage block', () async {
      final repo = fixture('unknown-argument');

      await expectLater(release(repo, ['--nope']), completion(2));
      expect(err.toString(), contains('Unknown argument: --nope'));
      expect(err.toString(), contains('release_prep.sh'));
    });

    test('a changelog without the expected first heading is rejected',
        () async {
      final repo = fixture('bad-changelog');
      writeFixtureFile(p.join(repo, 'CHANGELOG.md'), '# Notes\n\n## 1.0.0\n');

      await expectLater(release(repo, ['--skip-bump']), completion(1));
      expect(
        err.toString(),
        contains("CHANGELOG.md must start with '# Changelog'"),
      );
    });

    test('an invalid VERSION is rejected before the snapshot', () async {
      final repo = fixture('bad-version');
      writeFixtureFile(
          p.join(repo, 'version.config'), 'VERSION=not-a-version\n');

      await expectLater(release(repo, ['--skip-bump']), completion(1));
      expect(
        err.toString(),
        contains('Invalid VERSION in version.config: not-a-version'),
      );
      expect(runtimeTemp.listSync(), isEmpty);
    });
  });

  group('managed target safety', () {
    test('a symlinked managed target is rejected before writes', () async {
      final repo = fixture('symlink');
      final outside = p.join(workspace.path, 'outside-readme.md');
      writeFixtureFile(outside, 'outside sentinel\n');
      File(p.join(repo, 'README.md')).deleteSync();
      Link(p.join(repo, 'README.md')).createSync(outside);

      await expectLater(release(repo, ['--skip-bump']), completion(1));

      expect(
        err.toString(),
        contains('Managed paths cannot contain symlinks: README.md'),
      );
      expect(FileSystemEntity.isLinkSync(p.join(repo, 'README.md')), isTrue);
      expect(File(outside).readAsStringSync(), 'outside sentinel\n');
      expect(read(repo, 'version.config'), 'VERSION=7.0.0-dev.1\n');
    });
  });

  group('rollback', () {
    test('a step that fails before any write leaves the tree untouched',
        () async {
      final repo = fixture('fail-first-step');
      final before = treeSnapshot(repo);

      final status = await release(
        repo,
        const [],
        wrapSteps: (base) => _FailingSteps(
          base,
          failing: _Step.syncVersions,
          exitCode: 71,
        ),
      );

      expect(status, 71);
      expect(treeSnapshot(repo), before);
      expect(
        err.toString(),
        contains('Release preparation failed; restoring the pre-run state'),
      );
    });

    test('a step that fails after several writes restores every artifact',
        () async {
      final repo = fixture('fail-late-step');
      final before = treeSnapshot(repo);

      final status = await release(
        repo,
        const [],
        wrapSteps: (base) => _FailingSteps(
          base,
          failing: _Step.buildReadmes,
          exitCode: 73,
          onFailure: () {
            writeFixtureFile(
              p.join(repo, 'README.md'),
              'partially generated root README\n',
            );
            writeFixtureFile(
              p.join(repo, 'packages', 'ispect', 'README.md'),
              'partially generated package README\n',
            );
          },
        ),
      );

      expect(status, 73);
      expect(
        treeSnapshot(repo),
        before,
        reason: 'the fixture was not restored exactly after a helper failure',
      );
    });

    test('a validation failure after generation restores every artifact',
        () async {
      final repo = fixture('fail-validation');
      final before = treeSnapshot(repo);

      final status = await release(
        repo,
        const [],
        wrapSteps: (base) => _FailingSteps(
          base,
          failing: _Step.checkDependencies,
          exitCode: 1,
        ),
      );

      expect(status, 1);
      expect(treeSnapshot(repo), before);
    });

    test('a missing snapshot manifest retains the recovery copy', () async {
      final repo = fixture('missing-manifest');

      final status = await release(
        repo,
        const [],
        wrapSteps: (base) => _FailingSteps(
          base,
          failing: _Step.buildReadmes,
          exitCode: 74,
          onFailure: () => _deleteSnapshotManifest(runtimeTemp),
        ),
      );

      expect(status, 1);
      expect(
        err.toString(),
        contains('Recovery snapshot manifest is not readable'),
      );

      final retained = _reportedPath(
        err.toString(),
        '[INFO] Recovery snapshot retained at ',
      );
      expect(p.dirname(retained), runtimeTemp.path);
      expect(p.basename(retained), startsWith('ispect-release-prep.'));
      expect(Directory(retained).existsSync(), isTrue);
      expect(File(p.join(repo, 'version.config')).existsSync(), isTrue);
    });
  });

  group('--edit', () {
    test('the editor command keeps its own arguments', () async {
      final repo = fixture('editor');
      final editor = writeFakeEditor(p.join(workspace.path, 'bin', 'editor'));

      await expectLater(
        release(
          repo,
          ['--skip-bump', '--edit'],
          environment: {
            'EDITOR': '$editor --wait',
            'PATH': Platform.environment['PATH'] ?? '',
          },
        ),
        completion(0),
      );

      expect(
        read(repo, 'CHANGELOG.md'),
        contains('- Editor arguments were preserved.'),
      );
      expect(
        read(repo, 'packages/ispect/CHANGELOG.md'),
        contains('- Editor arguments were preserved.'),
      );
    });

    test('an editor failure preserves the saved changelog outside the repo',
        () async {
      final repo = fixture('editor-failure');
      final editor = writeFakeEditor(
        p.join(workspace.path, 'bin', 'editor'),
        exitStatus: 73,
      );

      await expectLater(
        release(
          repo,
          ['--skip-bump', '--edit'],
          environment: {
            'EDITOR': '$editor --wait',
            'PATH': Platform.environment['PATH'] ?? '',
          },
        ),
        completion(isNot(0)),
      );

      final backup = _reportedPath(
        err.toString(),
        '[INFO] Edited changelog preserved at ',
      );
      expect(p.dirname(backup), runtimeTemp.path);
      expect(p.basename(backup), startsWith('ispect-changelog-edit.'));
      expect(
        File(backup).readAsStringSync(),
        contains('- Editor arguments were preserved.'),
      );
      expect(
        read(repo, 'CHANGELOG.md'),
        isNot(contains('- Editor arguments were preserved.')),
      );
    });

    test('--edit without an editor on PATH is rejected', () async {
      final repo = fixture('no-editor');
      final before = treeSnapshot(repo);

      final status = await release(
        repo,
        ['--skip-bump', '--edit'],
        environment: {'PATH': p.join(workspace.path, 'empty-bin')},
      );

      expect(status, 1);
      expect(
        err.toString(),
        contains('No editor found; set EDITOR or omit --edit'),
      );
      expect(treeSnapshot(repo), before);
    });
  });
}

enum _Step {
  syncVersions,
  propagateChangelog,
  buildReadmes,
  buildLlms,
  checkVersionSync,
  checkDependencies,
}

/// Runs the real steps up to [failing], then reports [exitCode] instead of
/// running it — the Dart stand-in for the bash fixture's sabotaged helper.
final class _FailingSteps implements ReleaseSteps {
  _FailingSteps(
    this._delegate, {
    required this.failing,
    required this.exitCode,
    this.onFailure,
  });

  final ReleaseSteps _delegate;
  final _Step failing;
  final int exitCode;
  final void Function()? onFailure;

  int _reportFailure() {
    onFailure?.call();
    return exitCode;
  }

  int _runOrFail(_Step step, int Function() action) =>
      step == failing ? _reportFailure() : action();

  @override
  List<String> get requiredScripts => _delegate.requiredScripts;

  @override
  int syncVersions(BumpKind? bump) =>
      _runOrFail(_Step.syncVersions, () => _delegate.syncVersions(bump));

  @override
  int propagateChangelog() =>
      _runOrFail(_Step.propagateChangelog, _delegate.propagateChangelog);

  @override
  int buildReadmes() => _runOrFail(_Step.buildReadmes, _delegate.buildReadmes);

  @override
  int buildLlms() => _runOrFail(_Step.buildLlms, _delegate.buildLlms);

  @override
  int checkVersionSync() =>
      _runOrFail(_Step.checkVersionSync, _delegate.checkVersionSync);

  @override
  int checkDependencies() =>
      _runOrFail(_Step.checkDependencies, _delegate.checkDependencies);

  @override
  int checkReadmes() => _delegate.checkReadmes();

  @override
  int checkLlms() => _delegate.checkLlms();
}

void _deleteSnapshotManifest(Directory tempRoot) {
  for (final entity in tempRoot.listSync(recursive: true).whereType<File>()) {
    if (p.basename(entity.path) == 'existing' &&
        p.basename(p.dirname(entity.path)).startsWith('ispect-release-prep.')) {
      entity.deleteSync();
      return;
    }
  }
  throw StateError('no snapshot manifest found under ${tempRoot.path}');
}

String _reportedPath(String output, String prefix) {
  for (final line in output.split('\n')) {
    if (line.startsWith(prefix)) {
      return line.substring(prefix.length);
    }
  }
  throw StateError('no line starting with "$prefix" in:\n$output');
}
