import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/release_prep.dart';

/// Runs every repository check in one process.
///
/// CI and the pre-commit hook call this instead of the four commands it
/// covers: one process pays the VM start once, and the set of checks stays
/// defined in a single place next to the release run that validates with it.
final class CheckCommand extends Command<int> {
  CheckCommand(this.repoRoot);

  final String repoRoot;

  @override
  String get name => 'check';

  @override
  String get description =>
      'Verify versions, internal constraints, and generated docs are in sync.';

  @override
  Future<int> run() async {
    final steps = DartReleaseSteps(
      repoRoot: repoRoot,
      out: stdout,
      err: stderr,
    );

    var failed = 0;
    for (final check in repositoryChecks(steps)) {
      if (check() != 0) {
        failed++;
      }
    }

    if (failed == 0) {
      stdout.writeln('[OK ] Repository is in a releasable state');
      return 0;
    }
    stderr.writeln(
      "[ERR] $failed check(s) failed. Run 'ispect_tool release-prep "
      "--skip-bump' to resynchronize.",
    );
    return 1;
  }
}
