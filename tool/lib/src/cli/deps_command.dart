import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/release_prep.dart';
import '../core/version_config.dart';

/// Verifies every internal `^<version>` constraint matches `version.config`.
final class DepsCommand extends Command<int> {
  DepsCommand(this.repoRoot);

  final String repoRoot;

  @override
  String get name => 'deps';

  @override
  String get description =>
      'Check internal dependency constraints across the monorepo.';

  @override
  Future<int> run() async {
    final expected = VersionConfig.forRepo(repoRoot).read();
    stdout.writeln('[INFO] Expected internal constraint: ^$expected');

    return DartReleaseSteps(
      repoRoot: repoRoot,
      out: stdout,
      err: stderr,
    ).checkDependencies();
  }
}
