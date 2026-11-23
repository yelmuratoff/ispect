@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/flutter_sdk.dart';
import 'package:ispect_tool/src/core/publish.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'publish_fixture.dart';

final class _RecordingRunner implements ProcessRunner {
  final List<String> executables = [];

  @override
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) {
    executables.add(executable);
    return const CommandResult(exitCode: 0, output: '');
  }
}

void main() {
  late Directory scratch;

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('ispect_flutter_sdk_test');
  });

  tearDown(() {
    scratch.deleteSync(recursive: true);
  });

  void pin(String contents) =>
      writeFixtureFile(p.join(scratch.path, '.fvmrc'), contents);

  group('readFlutterPin', () {
    test('returns null when the repository pins no Flutter', () {
      expect(readFlutterPin(scratch.path), isNull);
    });

    test('reads the exact release .fvmrc pins', () {
      pin('{\n  "flutter": "3.47.5"\n}');

      expect(readFlutterPin(scratch.path), Version.parse('3.47.5'));
    });

    test('rejects a channel in place of a release', () {
      pin('{"flutter": "stable"}');

      expect(
        () => readFlutterPin(scratch.path),
        throwsA(
          isA<FlutterPinException>().having(
            (e) => e.message,
            'message',
            contains("pins 'stable'"),
          ),
        ),
      );
    });

    test('rejects a file that is not JSON', () {
      pin('flutter: 3.47.5');

      expect(
        () => readFlutterPin(scratch.path),
        throwsA(isA<FlutterPinException>()),
      );
    });

    test('rejects a file without a flutter release', () {
      pin('{"flavors": {}}');

      expect(
        () => readFlutterPin(scratch.path),
        throwsA(isA<FlutterPinException>()),
      );
    });
  });

  group('PinnedFlutterRunner', () {
    void runAll(ProcessRunner runner) {
      for (final executable in const ['flutter', 'dart', 'git']) {
        runner.run(executable, const [], workingDirectory: scratch.path);
      }
    }

    test('starts flutter and dart from the SDK FVM linked for the pin', () {
      pin('{"flutter": "3.47.5"}');
      final bin = p.join(scratch.path, '.fvm', 'versions', '3.47.5', 'bin');
      writeFixtureFile(p.join(bin, 'flutter'), '');
      final delegate = _RecordingRunner();

      runAll(PinnedFlutterRunner.forRepo(scratch.path, delegate: delegate));

      expect(delegate.executables, [
        p.join(bin, 'flutter'),
        p.join(bin, 'dart'),
        'git',
      ]);
    });

    test('falls back to PATH until FVM links the pinned SDK', () {
      pin('{"flutter": "3.47.5"}');
      final delegate = _RecordingRunner();

      runAll(PinnedFlutterRunner.forRepo(scratch.path, delegate: delegate));

      expect(delegate.executables, ['flutter', 'dart', 'git']);
    });

    test('ignores an SDK FVM linked for another release', () {
      pin('{"flutter": "3.47.5"}');
      writeFixtureFile(
        p.join(scratch.path, '.fvm', 'versions', '3.44.2', 'bin', 'flutter'),
        '',
      );
      final delegate = _RecordingRunner();

      runAll(PinnedFlutterRunner.forRepo(scratch.path, delegate: delegate));

      expect(delegate.executables, ['flutter', 'dart', 'git']);
    });

    test('uses PATH in a repository without a pin', () {
      final delegate = _RecordingRunner();

      runAll(PinnedFlutterRunner.forRepo(scratch.path, delegate: delegate));

      expect(delegate.executables, ['flutter', 'dart', 'git']);
    });
  });
}
