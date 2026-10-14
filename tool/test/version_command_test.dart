@TestOn('vm')
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ispect_tool/src/cli/version_command.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'release_fixture.dart';

void main() {
  late Directory workspace;
  late _CapturedStdout out;
  late _CapturedStdout err;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-version-bump-');
    out = _CapturedStdout();
    err = _CapturedStdout();
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
}

final class _CapturedStdout implements Stdout {
  final StringBuffer buffer = StringBuffer();

  @override
  void write(Object? object) => buffer.write(object);

  @override
  void writeln([Object? object = '']) => buffer.writeln(object);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
