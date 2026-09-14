import 'dart:io';

import 'package:ispect_tool/src/core/publish.dart';
import 'package:path/path.dart' as p;

/// The scripts `bash/publish.sh` sources, relative to the repository root.
const List<String> publishFixtureScripts = [
  'bash/publish.sh',
  'bash/lib/semver.sh',
  'bash/lib/pub_api.sh',
];

/// Builds a repository holding `version.config` and every package in
/// [publishOrder], and returns its path.
///
/// [constraint] is written into every package's `dependencies`, so a scenario
/// can plant the unconstrained `any` the preflight refuses.
String createPublishFixture({
  required String destination,
  String version = '7.0.0-dev.1',
  String constraint = '^1.0.0',
  Map<String, String> packageVersions = const {},
}) {
  writeFixtureFile(p.join(destination, 'version.config'), 'VERSION=$version\n');

  for (final package in publishOrder) {
    writeFixtureFile(
      p.join(destination, 'packages', package, 'pubspec.yaml'),
      '''
name: $package
description: $package fixture package for the publish preflight.
version: ${packageVersions[package] ?? version}
repository: https://example.invalid/ispect
environment:
  sdk: ^3.6.0
dependencies:
  meta: $constraint
''',
    );
    writeFixtureFile(
      p.join(destination, 'packages', package, 'CHANGELOG.md'),
      '# Changelog\n\n## $version\n',
    );
  }
  return destination;
}

/// Copies `bash/publish.sh` and the libraries it sources into [destination].
void copyPublishScripts({
  required String sourceRepo,
  required String destination,
}) {
  for (final script in publishFixtureScripts) {
    final target = p.join(destination, script);
    writeFixtureFile(
      target,
      File(p.join(sourceRepo, script)).readAsStringSync(),
    );
    makeExecutable(target);
  }
}

/// Turns [repo] into a git repository whose working tree is clean.
void commitFixture(String repo) {
  _git(repo, const ['init', '--quiet', '--initial-branch=main']);
  _git(repo, const ['add', '--all']);
  _git(repo, const [
    '-c',
    'user.name=Fixture',
    '-c',
    'user.email=fixture@example.invalid',
    '-c',
    'commit.gpgsign=false',
    'commit',
    '--quiet',
    '--message',
    'fixture',
  ]);
}

void _git(String repo, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: repo,
    environment: const {
      'GIT_CONFIG_GLOBAL': '/dev/null',
      'GIT_CONFIG_SYSTEM': '/dev/null',
    },
  );
  if (result.exitCode != 0) {
    throw StateError('git ${arguments.join(" ")} failed: ${result.stderr}');
  }
}

void writeFixtureFile(String path, String contents) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void makeExecutable(String path) {
  final result = Process.runSync('chmod', ['+x', path]);
  if (result.exitCode != 0) {
    throw StateError('cannot make $path executable: ${result.stderr}');
  }
}
