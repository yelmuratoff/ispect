import 'package:args/command_runner.dart';

import 'argv.dart';

import '../core/version_sync.dart';

/// Propagates `version.config` to every package manifest and the web lockfile.
final class SyncCommand extends Command<int> {
  SyncCommand(this.repoRoot) {
    argParser
      ..addFlag('dry-run', help: 'Show changes without modifying files.')
      ..addOption(
        'bump',
        allowed: ['patch', 'minor', 'major'],
        help: 'Compute the next version and persist it before syncing.',
      );
  }

  final String repoRoot;

  @override
  String get name => 'sync';

  @override
  String get description =>
      'Synchronize package versions and internal constraints with '
      'version.config.';

  @override
  Future<int> run() async => runVersionSync(
      repoRoot: repoRoot,
      arguments: normalizeOptionValues(argResults!.arguments));
}
