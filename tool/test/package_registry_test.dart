@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/publish.dart';
import 'package:ispect_tool/src/core/readme_builder.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:ispect_tool/src/core/version_config.dart';
import 'package:test/test.dart';

void main() {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null) {
    throw StateError('package registry tests must run inside the repository');
  }
  final packageNames = PackageVersions(repoRoot).read().keys.toSet();

  test('the repository declares packages to compare against', () {
    expect(packageNames, isNotEmpty);
  });

  test('publishOrder lists every package under packages/ exactly once', () {
    expect(publishOrder.toSet(), packageNames);
    expect(publishOrder, hasLength(packageNames.length));
  });

  test('readmeTargets generate a README for every package under packages/', () {
    final packageTargets = readmeTargets
        .where((target) => target.outputPath.startsWith('packages/'))
        .toList();

    expect(
      packageTargets.map((target) => target.packageName).toSet(),
      packageNames,
    );
    for (final target in packageTargets) {
      expect(target.outputPath, 'packages/${target.packageName}/README.md');
    }
  });
}
