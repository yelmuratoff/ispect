import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'exceptions.dart';

/// The pubspec sections that carry publishable version constraints.
///
/// `dependency_overrides` is deliberately absent: local path overrides exist
/// for monorepo development and never ship to pub.dev.
enum PubspecSection {
  dependencies('dependencies'),
  devDependencies('dev_dependencies');

  const PubspecSection(this.key);

  final String key;
}

/// One internal `^` constraint that disagrees with `version.config`.
final class DependencyInconsistency {
  const DependencyInconsistency({
    required this.pubspec,
    required this.owner,
    required this.dependency,
    required this.section,
    required this.constraint,
  });

  /// Repository-relative path of the pubspec declaring the constraint.
  final String pubspec;

  /// The `name:` of the package or project declaring the constraint.
  final String owner;

  /// The monorepo package being depended on.
  final String dependency;

  final PubspecSection section;

  /// The constraint as written, caret included.
  final String constraint;

  String describe(Version expected) => '$owner (${section.key}) depends on '
      '$dependency $constraint, should be ^$expected [$pubspec]';

  @override
  String toString() => '$pubspec:${section.key}:$dependency=$constraint';
}

/// Verifies that every internal `^` constraint between monorepo packages
/// matches the version in `version.config`.
///
/// Covers the package pubspecs under `packages/`, their `example/` projects,
/// and the standalone `web_logs_viewer` project.
final class DependencyCheck {
  const DependencyCheck(this.repoRoot);

  static const _webViewer = 'web_logs_viewer';

  final String repoRoot;

  /// Names declared by `packages/*/pubspec.yaml`, ordered by directory name.
  List<String> packageNames() => [
        for (final pubspec in _packagePubspecs()) pubspec.name,
      ];

  /// Every internal constraint that does not resolve to [expected].
  List<DependencyInconsistency> findInconsistencies(Version expected) {
    final packages = _packagePubspecs();
    final names = {for (final pubspec in packages) pubspec.name};

    final found = <DependencyInconsistency>[];
    for (final pubspec in packages) {
      found.addAll(
        _scan(pubspec, expected, names.difference({pubspec.name})),
      );

      final example = _readOrNull(
        File(p.join(p.dirname(pubspec.file.path), 'example', 'pubspec.yaml')),
      );
      if (example != null) {
        found.addAll(_scan(example, expected, names));
      }
    }

    final viewer =
        _readOrNull(File(p.join(repoRoot, _webViewer, 'pubspec.yaml')));
    if (viewer != null) {
      found.addAll(_scan(viewer, expected, names));
    }
    return found;
  }

  /// Throws [DependencyConsistencyException] listing every disagreement.
  void assertConsistent(Version expected) {
    final found = findInconsistencies(expected);
    if (found.isEmpty) {
      return;
    }
    throw DependencyConsistencyException(
      '${found.length} internal dependency constraint(s) do not match '
      '$expected',
      inconsistencies: [
        for (final inconsistency in found) inconsistency.describe(expected),
      ],
    );
  }

  List<_Pubspec> _packagePubspecs() {
    final packages = Directory(p.join(repoRoot, 'packages'));
    if (!packages.existsSync()) {
      return const [];
    }
    final directories = packages.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final directory in directories)
        if (_readOrNull(File(p.join(directory.path, 'pubspec.yaml')))
            case final _Pubspec pubspec)
          pubspec,
    ];
  }

  List<DependencyInconsistency> _scan(
    _Pubspec pubspec,
    Version expected,
    Set<String> candidates,
  ) {
    final relative = p.relative(pubspec.file.path, from: repoRoot);

    final found = <DependencyInconsistency>[];
    for (final section in PubspecSection.values) {
      final entries = pubspec.document[section.key];
      if (entries is! YamlMap) {
        continue;
      }
      for (final entry in entries.entries) {
        final dependency = entry.key;
        if (dependency is! String || !candidates.contains(dependency)) {
          continue;
        }
        final constraint = _caretConstraint(entry.value);
        if (constraint == null ||
            constraint.substring(1) == expected.toString()) {
          continue;
        }
        found.add(
          DependencyInconsistency(
            pubspec: relative,
            owner: pubspec.name,
            dependency: dependency,
            section: section,
            constraint: constraint,
          ),
        );
      }
    }
    return found;
  }

  static String? _caretConstraint(Object? value) {
    if (value is String) {
      return value.startsWith('^') ? value : null;
    }
    if (value is YamlMap) {
      final version = value['version'];
      return version is String && version.startsWith('^') ? version : null;
    }
    return null;
  }

  /// Throws [PubspecException] when the file exists but does not parse.
  _Pubspec? _readOrNull(File file) {
    if (!file.existsSync()) {
      return null;
    }
    final Object? document;
    try {
      document = loadYaml(file.readAsStringSync(), sourceUrl: file.uri);
    } on YamlException catch (e) {
      throw PubspecException('${file.path} is not valid YAML: ${e.message}');
    }
    if (document is! YamlMap) {
      throw PubspecException('${file.path} is not a YAML mapping');
    }
    final name = document['name'];
    return _Pubspec(
      file: file,
      document: document,
      name: name is String ? name : p.relative(file.path, from: repoRoot),
    );
  }
}

final class _Pubspec {
  const _Pubspec({
    required this.file,
    required this.document,
    required this.name,
  });

  final File file;
  final YamlMap document;
  final String name;
}
