import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:pub_semver/pub_semver.dart';

import '../core/exceptions.dart';
import '../core/next_version.dart';
import '../core/release_prep.dart';
import '../core/version_config.dart';
import '../core/version_sync.dart';

/// Version inspection and bumping.
final class VersionCommand extends Command<int> {
  VersionCommand(this.repoRoot) {
    addSubcommand(_VersionBumpCommand(repoRoot));
    addSubcommand(_VersionCheckCommand(repoRoot));
  }

  final String repoRoot;

  @override
  String get name => 'version';

  @override
  String get description => 'Inspect and advance the repository version.';
}

final class _VersionBumpCommand extends Command<int> {
  _VersionBumpCommand(this.repoRoot) {
    argParser.addFlag(
      'sync',
      defaultsTo: true,
      help: 'Propagate the new version to every package.',
    );
  }

  final String repoRoot;

  @override
  String get name => 'bump';

  @override
  String get description =>
      'Advance VERSION by a bump kind, the dev shorthand, or an explicit '
      'version.';

  @override
  String get invocation =>
      'ispect_tool version bump <patch|minor|major|dev|X.Y.Z>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      stderr.writeln('[ERR] Expected exactly one bump argument');
      printUsage();
      return 2;
    }

    final config = VersionConfig.forRepo(repoRoot);
    final current = config.read();
    stdout.writeln('[INFO] Current version: $current');

    final next = _resolve(rest.single, current);
    if (next == null) {
      return 2;
    }

    if (argResults!.flag('sync')) {
      VersionSync(repoRoot: repoRoot, out: stdout, err: stderr)
          .run(current: current, target: next);
    } else {
      config.write(next);
    }
    stdout.writeln('[INFO] Bumped to: $next');
    writeGluedCounterWarning(stderr, next);
    return 0;
  }

  Version? _resolve(String argument, Version current) {
    try {
      if (argument == 'dev') {
        return nextDevVersion(current);
      }
      final kind = BumpKind.tryParse(argument);
      if (kind != null) {
        return nextVersion(current, kind);
      }
      final explicit = Version.parse(argument);
      assertRises(explicit, current);
      return explicit;
    } on FormatException {
      stderr.writeln('[ERR] Invalid version format: $argument');
      printUsage();
      return null;
    } on VersionRegressionException catch (e) {
      stderr.writeln('[ERR] ${e.message}');
      return null;
    }
  }
}

final class _VersionCheckCommand extends Command<int> {
  _VersionCheckCommand(this.repoRoot);

  final String repoRoot;

  @override
  String get name => 'check';

  @override
  String get description =>
      'Verify every package version matches version.config.';

  @override
  Future<int> run() async {
    writeGluedCounterWarning(stderr, VersionConfig.forRepo(repoRoot).read());

    final status = DartReleaseSteps(
      repoRoot: repoRoot,
      out: stdout,
      err: stderr,
    ).checkVersionSync();
    if (status != 0) {
      stderr.writeln("[ERR] Run 'ispect_tool sync' to sync them.");
    }
    return status;
  }
}
