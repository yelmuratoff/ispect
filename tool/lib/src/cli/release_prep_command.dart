import 'package:args/command_runner.dart';

import 'argv.dart';

import '../core/release_prep.dart';

/// Synchronizes every release-managed artefact, with or without a bump.
final class ReleasePrepCommand extends Command<int> {
  ReleasePrepCommand(this.repoRoot) {
    argParser
      ..addOption(
        'bump',
        allowed: ['patch', 'minor', 'major'],
        help: 'Bump kind (default: patch).',
      )
      ..addFlag('skip-bump', help: 'Keep VERSION and synchronize everything.')
      ..addFlag('no-bump', help: 'Alias for --skip-bump.')
      ..addFlag(
        'carry-changelog',
        help: 'Move the previous prerelease notes to the next prerelease.',
      )
      ..addFlag(
        'recover-changelog',
        help: 'Resume an interrupted prerelease sync without a bump.',
      )
      ..addFlag('edit', help: 'Open CHANGELOG.md before generating artefacts.');
  }

  final String repoRoot;

  @override
  String get name => 'release-prep';

  @override
  String get description =>
      'Synchronize versions, changelogs, READMEs, and llms.txt, then validate.';

  @override
  String get invocation =>
      'ispect_tool release-prep [patch|minor|major] [options]';

  @override
  Future<int> run() => runReleasePrep(
      repoRoot: repoRoot,
      arguments: normalizeOptionValues(argResults!.arguments));
}
