import 'package:args/command_runner.dart';

import 'argv.dart';

import '../core/changelog.dart';
import '../core/llms_builder.dart';
import '../core/readme_builder.dart';

/// Regenerates every package README from `docs/readme/**`.
final class ReadmeCommand extends Command<int> {
  ReadmeCommand(this.repoRoot) {
    argParser
      ..addFlag('check', help: 'Report drift without writing; exit 1 on drift.')
      ..addFlag('dry-run', help: 'Print the generated content without writing.')
      ..addOption('package', help: 'Build a single target by name.');
  }

  final String repoRoot;

  @override
  String get name => 'readme';

  @override
  String get description => 'Build the generated READMEs from docs/readme.';

  @override
  Future<int> run() async => runReadmeBuild(
      repoRoot: repoRoot,
      arguments: normalizeOptionValues(argResults!.arguments));
}

/// Regenerates the repo-root `llms.txt` index.
final class LlmsCommand extends Command<int> {
  LlmsCommand(this.repoRoot) {
    argParser
      ..addFlag('check', help: 'Report drift without writing; exit 1 on drift.')
      ..addFlag('dry-run',
          help: 'Print the generated content without writing.');
  }

  final String repoRoot;

  @override
  String get name => 'llms';

  @override
  String get description => 'Build llms.txt from repository metadata.';

  @override
  Future<int> run() async => runLlmsBuild(
      repoRoot: repoRoot,
      arguments: normalizeOptionValues(argResults!.arguments));
}

/// Propagates the root changelog to every package changelog.
final class ChangelogCommand extends Command<int> {
  ChangelogCommand(this.repoRoot) {
    argParser
      ..addFlag('full-copy', help: 'Overwrite package changelogs entirely.')
      ..addFlag('yes', help: 'Answer the overwrite confirmation with yes.')
      ..addOption('version', help: 'Propagate a specific version section.');
  }

  final String repoRoot;

  @override
  String get name => 'changelog';

  @override
  String get description =>
      'Propagate a root CHANGELOG.md section to the packages.';

  @override
  Future<int> run() async => runChangelogPropagation(
        repoRoot: repoRoot,
        arguments: normalizeOptionValues(argResults!.arguments),
      );
}
