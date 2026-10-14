@TestOn('vm')
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ispect_tool/src/cli/version_command.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'captured_stdout.dart';
import 'release_fixture.dart';

void main() {
  late Directory workspace;
  late CapturedStdout out;
  late CapturedStdout err;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-version-bump-');
    out = CapturedStdout();
    err = CapturedStdout();
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  Future<int?> bump(String repo, List<String> arguments) =>
      IOOverrides.runZoned(
        () => (CommandRunner<int>('ispect_tool', 'test')
              ..addCommand(VersionCommand(repo)))
            .run(['version', 'bump', ...arguments]),
        stdout: () => out,
        stderr: () => err,
      );

  String readConfig(String repo) =>
      File(p.join(repo, 'version.config')).readAsStringSync();

  group('version bump', () {
    test('leaves version.config untouched when the sync fails', () async {
      final repo = createReleaseFixture(
        destination: p.join(workspace.path, 'repo'),
        version: '7.0.0-dev.1',
      );
      writeFixtureFile(
        p.join(repo, 'packages', 'ispect', 'pubspec.yaml'),
        'version: 0.0.1\n',
      );

      await expectLater(
        bump(repo, ['dev']),
        throwsA(isA<ManifestException>()),
      );
      expect(readConfig(repo), 'VERSION=7.0.0-dev.1\n');
    });

    test('persists the bumped version when the sync succeeds', () async {
      final repo = createReleaseFixture(
        destination: p.join(workspace.path, 'repo'),
        version: '7.0.0-dev.1',
      );

      await expectLater(bump(repo, ['dev']), completion(0));
      expect(readConfig(repo), 'VERSION=7.0.0-dev.2\n');
      expect(
        File(p.join(repo, 'packages', 'ispect', 'pubspec.yaml'))
            .readAsStringSync(),
        contains('version: 7.0.0-dev.2\n'),
      );
    });

    test('--no-sync persists the version without touching packages', () async {
      final repo = createReleaseFixture(
        destination: p.join(workspace.path, 'repo'),
        version: '7.0.0-dev.1',
      );

      await expectLater(bump(repo, ['--no-sync', 'dev']), completion(0));
      expect(readConfig(repo), 'VERSION=7.0.0-dev.2\n');
      expect(
        File(p.join(repo, 'packages', 'ispect', 'pubspec.yaml'))
            .readAsStringSync(),
        contains('version: 0.0.1\n'),
      );
    });

    test('warns about a glued prerelease counter once', () async {
      final repo = createReleaseFixture(
        destination: p.join(workspace.path, 'repo'),
        version: '7.0.0-dev8',
      );

      await expectLater(bump(repo, ['dev']), completion(0));
      expect(
        'glues its counter'.allMatches(err.buffer.toString()),
        hasLength(1),
      );
    });
  });

  group('version bump argument', () {
    String repoAt(String version) => createReleaseFixture(
          destination: p.join(workspace.path, 'repo'),
          version: version,
        );

    for (final (argument, from, to) in [
      ('patch', '7.0.1', '7.0.2'),
      ('minor', '7.0.1', '7.1.0'),
      ('major', '7.0.1', '8.0.0'),
      ('dev', '7.1.0-dev.4', '7.1.0-dev.5'),
      ('7.2.0-rc.1', '7.1.0', '7.2.0-rc.1'),
    ]) {
      test('$argument advances $from to $to', () async {
        final repo = repoAt(from);

        await expectLater(bump(repo, ['--no-sync', argument]), completion(0));
        expect(readConfig(repo), 'VERSION=$to\n');
      });
    }

    test('an unparsable version exits 2 and leaves VERSION alone', () async {
      final repo = repoAt('7.0.1');

      await expectLater(bump(repo, ['--no-sync', 'seven']), completion(2));
      expect(err.buffer.toString(), contains('Invalid version format: seven'));
      expect(readConfig(repo), 'VERSION=7.0.1\n');
    });

    test('an explicit version below the current one exits 2', () async {
      final repo = repoAt('7.0.1');

      await expectLater(bump(repo, ['--no-sync', '7.0.0']), completion(2));
      expect(err.buffer.toString(), startsWith('[ERR] '));
      expect(readConfig(repo), 'VERSION=7.0.1\n');
    });

    test('an explicit version equal to the current one exits 2', () async {
      final repo = repoAt('7.0.1');

      await expectLater(bump(repo, ['--no-sync', '7.0.1']), completion(2));
      expect(readConfig(repo), 'VERSION=7.0.1\n');
    });
  });
}
