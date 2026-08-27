import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/dependency_check.dart';
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

    final found = DependencyCheck(repoRoot).findInconsistencies(expected);
    for (final inconsistency in found) {
      stderr.writeln('[ERR] ${inconsistency.describe(expected)}');
    }
    if (found.isNotEmpty) {
      stderr.writeln(
        '[ERR] ${found.length} internal constraint(s) do not match $expected',
      );
      return 1;
    }

    stdout.writeln('[OK ] Every internal constraint matches $expected');
    return 0;
  }
}
