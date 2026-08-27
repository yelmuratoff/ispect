@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/next_version.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// `bash/lib/semver.sh` still backs `update_versions.sh` and `release_prep.sh`
/// until those are ported. While both implementations exist they must agree,
/// or a release computed by one and validated by the other silently diverges.
///
/// Delete this file together with the last consumer of the bash library.
void main() {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null) {
    throw StateError('conformance test must run inside the repository');
  }
  final library = File(p.join(repoRoot, 'bash', 'lib', 'semver.sh'));
  final libraryPath = library.path;

  /// Runs one bash helper and returns its trimmed stdout.
  String bash(String function, List<String> args) {
    final result = Process.runSync('bash', [
      '-c',
      'source "\$1"; shift; "\$@"',
      'bash',
      libraryPath,
      function,
      ...args,
    ]);
    if (result.exitCode != 0) {
      return '<exit ${result.exitCode}>';
    }
    return (result.stdout as String).trim();
  }

  const versions = [
    '7.0.0-dev1',
    '7.0.0-dev2',
    '7.0.0-dev8',
    '7.0.0-dev9',
    '7.0.0-dev10',
    '7.0.0-dev11',
    '7.0.0-dev.1',
    '7.0.0-dev.2',
    '7.0.0-dev.10',
    '7.0.0-dev.11',
    '7.0.0-dev9.1',
    '7.0.0-dev9.10',
    '7.0.0-dev11.1',
    '7.0.0-alpha',
    '7.0.0-alpha.1',
    '7.0.0-alpha.beta',
    '7.0.0-beta.2',
    '7.0.0-beta.11',
    '7.0.0-rc.1',
    '7.0.0',
    '7.0.1',
    '7.1.0',
    '8.0.0',
    '6.9.9',
    '7.0.0-0',
    '7.0.0-a',
    '7.0.0-x-y-z.1',
    '7.0.0-dev.1+build1',
    '7.0.0+meta',
  ];

  test('semver_compare agrees with pub_semver on every ordered pair', () {
    if (!library.existsSync()) {
      markTestSkipped(
          'bash/lib/semver.sh is gone; conformance no longer applies');
      return;
    }

    final mismatches = <String>[];
    for (final left in versions) {
      for (final right in versions) {
        final fromBash = bash('semver_compare', [left, right]);
        final raw = Version.parse(left).compareTo(Version.parse(right));
        final fromDart = raw < 0
            ? '-1'
            : raw > 0
                ? '1'
                : '0';
        if (fromBash != fromDart) {
          mismatches.add('$left vs $right: bash=$fromBash dart=$fromDart');
        }
      }
    }

    expect(
      mismatches,
      isEmpty,
      reason: 'bash and pub_semver disagree on ${mismatches.length} pair(s)',
    );
  });

  test('semver_next_prerelease agrees with nextPrerelease', () {
    if (!library.existsSync()) {
      markTestSkipped(
          'bash/lib/semver.sh is gone; conformance no longer applies');
      return;
    }

    final mismatches = <String>[];
    for (final value in versions) {
      final parsed = Version.parse(value);
      if (!parsed.isPreRelease) {
        continue;
      }
      final fromBash = bash('semver_next_prerelease', [value]);
      final fromDart = nextPrerelease(parsed).toString();
      if (fromBash != fromDart) {
        mismatches.add('$value: bash=$fromBash dart=$fromDart');
      }
    }

    expect(mismatches, isEmpty);
  });

  test('semver_has_glued_counter agrees with hasGluedCounter', () {
    if (!library.existsSync()) {
      markTestSkipped(
          'bash/lib/semver.sh is gone; conformance no longer applies');
      return;
    }

    final mismatches = <String>[];
    for (final value in versions) {
      final result = Process.runSync('bash', [
        '-c',
        'source "\$1"; semver_has_glued_counter "\$2"',
        'bash',
        libraryPath,
        value,
      ]);
      final fromBash = result.exitCode == 0;
      final fromDart = hasGluedCounter(Version.parse(value));
      if (fromBash != fromDart) {
        mismatches.add('$value: bash=$fromBash dart=$fromDart');
      }
    }

    expect(mismatches, isEmpty);
  });
}
