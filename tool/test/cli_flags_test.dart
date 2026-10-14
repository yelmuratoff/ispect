@TestOn('vm')
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ispect_tool/src/cli/docs_commands.dart';
import 'package:ispect_tool/src/cli/release_prep_command.dart';
import 'package:ispect_tool/src/cli/sync_command.dart';
import 'package:ispect_tool/src/core/changelog.dart';
import 'package:ispect_tool/src/core/llms_builder.dart';
import 'package:ispect_tool/src/core/readme_builder.dart';
import 'package:ispect_tool/src/core/release_prep.dart';
import 'package:ispect_tool/src/core/version_sync.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'release_fixture.dart';

typedef _CoreEntry = Future<int> Function(
  String repoRoot,
  List<String> arguments,
  StringSink out,
  StringSink err,
);

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-cli-flags-');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  final entries = <String, _CoreEntry>{
    'release-prep': (repoRoot, arguments, out, err) => runReleasePrep(
          repoRoot: repoRoot,
          arguments: arguments,
          out: out,
          err: err,
          tempRoot: Directory(p.join(repoRoot, '..', 'runtime'))
            ..createSync(recursive: true),
          environment: const {'PATH': ''},
        ),
    'readme': (repoRoot, arguments, out, err) async => runReadmeBuild(
        repoRoot: repoRoot, arguments: arguments, out: out, err: err),
    'llms': (repoRoot, arguments, out, err) async => runLlmsBuild(
        repoRoot: repoRoot, arguments: arguments, out: out, err: err),
    'changelog': (repoRoot, arguments, out, err) async =>
        runChangelogPropagation(
            repoRoot: repoRoot, arguments: arguments, out: out, err: err),
    'sync': (repoRoot, arguments, out, err) async => runVersionSync(
        repoRoot: repoRoot, arguments: arguments, out: out, err: err),
  };

  List<Command<int>> commands(String repoRoot) => [
        ReleasePrepCommand(repoRoot),
        ReadmeCommand(repoRoot),
        LlmsCommand(repoRoot),
        ChangelogCommand(repoRoot),
        SyncCommand(repoRoot),
      ];

  for (final command in commands('unused')) {
    group('${command.name} flags', () {
      test('help advertises no negated form', () {
        expect(command.argParser.usage, isNot(contains('[no-]')));
      });

      final flags = command.argParser.options.values
          .where((option) => option.isFlag && option.name != 'help')
          .map((option) => option.name);

      for (final flag in flags) {
        test('the core entry point accepts --$flag', () async {
          final repo = createReleaseFixture(
            destination: p.join(workspace.path, 'repo'),
          );
          final out = StringBuffer();
          final err = StringBuffer();

          await entries[command.name]!(repo, ['--$flag'], out, err);

          expect('$out$err', isNot(contains('Unknown')));
        });
      }
    });
  }
}
