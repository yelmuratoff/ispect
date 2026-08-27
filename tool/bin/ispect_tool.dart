import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ispect_tool/src/cli/deps_command.dart';
import 'package:ispect_tool/src/cli/docs_commands.dart';
import 'package:ispect_tool/src/cli/publish_command.dart';
import 'package:ispect_tool/src/cli/publish_gate_command.dart';
import 'package:ispect_tool/src/cli/release_prep_command.dart';
import 'package:ispect_tool/src/cli/sync_command.dart';
import 'package:ispect_tool/src/cli/version_command.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';

Future<void> main(List<String> arguments) async {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null) {
    stderr.writeln('[ERR] version.config not found in any parent directory');
    exitCode = 2;
    return;
  }

  final runner = CommandRunner<int>(
      'ispect_tool', 'Release tooling for the ISpect monorepo.')
    ..addCommand(VersionCommand(repoRoot))
    ..addCommand(SyncCommand(repoRoot))
    ..addCommand(DepsCommand(repoRoot))
    ..addCommand(CheckPublishedCommand(repoRoot))
    ..addCommand(ReadmeCommand(repoRoot))
    ..addCommand(LlmsCommand(repoRoot))
    ..addCommand(ChangelogCommand(repoRoot))
    ..addCommand(ReleasePrepCommand(repoRoot))
    ..addCommand(PublishCommand(repoRoot));

  try {
    exitCode = await runner.run(arguments) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  } on ToolException catch (e) {
    stderr.writeln('[ERR] ${e.message}');
    exitCode = 1;
  }
}
