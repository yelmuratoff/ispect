import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'exceptions.dart';

/// The `VERSION=` line in `version.config`, the source of truth for the
/// version every package carries.
final class VersionConfig {
  const VersionConfig(this.file);

  factory VersionConfig.forRepo(String repoRoot) =>
      VersionConfig(File(p.join(repoRoot, 'version.config')));

  static final _line = RegExp(r'^VERSION=(.*)$');

  final File file;

  /// Throws [VersionConfigException] when the file is missing or the version
  /// is absent, empty, or not a semantic version.
  Version read() {
    if (!file.existsSync()) {
      throw VersionConfigException('${file.path} not found');
    }

    for (final line in file.readAsLinesSync()) {
      final match = _line.firstMatch(line);
      if (match == null) {
        continue;
      }
      final raw = match.group(1)!.trim();
      if (raw.isEmpty) {
        throw VersionConfigException('VERSION is empty in ${file.path}');
      }
      try {
        return Version.parse(raw);
      } on FormatException {
        throw VersionConfigException('Invalid VERSION in ${file.path}: $raw');
      }
    }

    throw VersionConfigException('VERSION not defined in ${file.path}');
  }

  /// Rewrites only the `VERSION=` line, leaving every other line untouched.
  void write(Version version) {
    final contents = file.readAsStringSync();
    final endsWithNewline = contents.endsWith('\n');
    final lines = contents.split('\n');
    if (endsWithNewline) {
      lines.removeLast();
    }

    var replaced = false;
    for (var index = 0; index < lines.length; index++) {
      if (replaced || !_line.hasMatch(lines[index])) {
        continue;
      }
      lines[index] = 'VERSION=$version';
      replaced = true;
    }
    if (!replaced) {
      throw VersionConfigException('VERSION not defined in ${file.path}');
    }

    file.writeAsStringSync(lines.join('\n') + (endsWithNewline ? '\n' : ''));
  }
}

/// The `version:` line each package under `packages/` declares.
final class PackageVersions {
  const PackageVersions(this.repoRoot);

  static final _name = RegExp(r'^name:\s*(\S+)', multiLine: true);
  static final _version = RegExp(r'^version:\s*(\S+)', multiLine: true);

  final String repoRoot;

  /// Package name to declared version, ordered by directory name.
  Map<String, String> read() {
    final packages = Directory(p.join(repoRoot, 'packages'));
    if (!packages.existsSync()) {
      return const {};
    }

    final result = <String, String>{};
    final directories = packages.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final directory in directories) {
      final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
      if (!pubspec.existsSync()) {
        continue;
      }
      final contents = pubspec.readAsStringSync();
      final name =
          _name.firstMatch(contents)?.group(1) ?? p.basename(directory.path);
      result[name] = _version.firstMatch(contents)?.group(1) ?? '';
    }
    return result;
  }

  /// Throws [VersionSyncException] naming every package that disagrees.
  void assertMatches(Version expected) {
    final outOfSync = [
      for (final entry in read().entries)
        if (entry.value != expected.toString()) entry.key,
    ];
    if (outOfSync.isEmpty) {
      return;
    }
    throw VersionSyncException(
      '${outOfSync.length} package(s) do not match $expected',
      outOfSync: outOfSync,
    );
  }
}
