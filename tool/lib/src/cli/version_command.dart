import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:pub_semver/pub_semver.dart';

import '../core/exceptions.dart';
import '../core/next_version.dart';
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

void _warnGluedCounter(Version version) {
  if (!hasGluedCounter(version)) {
    return;
  }
  stderr
    ..writeln('[WARN] $version glues its counter to the prerelease label, so '
        'Pub compares that counter as text (dev11 sorts below dev8).')
    ..writeln('[WARN] Further bumps stay monotonic by appending a numeric '
        'identifier; to sort above an already published sibling the series has '
        'to leave this label (rc.1) or the prerelease.');
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

    config.write(next);
    stdout.writeln('[INFO] Bumped to: $next');
    _warnGluedCounter(next);

    if (!argResults!.flag('sync')) {
      return 0;
    }
    return runVersionSync(repoRoot: repoRoot, arguments: const []);
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
    final expected = VersionConfig.forRepo(repoRoot).read();
    stdout.writeln('[INFO] Version from version.config: $expected');
    _warnGluedCounter(expected);

    final packages = PackageVersions(repoRoot);
    final declared = packages.read();
    for (final entry in declared.entries) {
      final matches = entry.value == expected.toString();
      stdout.writeln(
        '${matches ? "[OK ]" : "[ERR]"} ${entry.key}: ${entry.value}',
      );
    }

    try {
      packages.assertMatches(expected);
    } on VersionSyncException catch (e) {
      stderr
        ..writeln('[ERR] ${e.message}: ${e.outOfSync.join(", ")}')
        ..writeln("[ERR] Run 'ispect_tool sync' to sync them.");
      return 1;
    }

    stdout.writeln('[OK ] All ${declared.length} packages match $expected');
    return 0;
  }
}
