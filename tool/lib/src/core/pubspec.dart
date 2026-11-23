import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'exceptions.dart';

/// A pubspec read from disk as a YAML mapping with a declared `name:`.
final class Pubspec {
  const Pubspec({
    required this.file,
    required this.document,
    required this.name,
  });

  /// Reads [file], naming it relative to [repoRoot] in failures.
  ///
  /// Throws [PubspecException] when the file is not a valid YAML mapping and
  /// [ManifestException] when it declares no `name:`.
  factory Pubspec.read(File file, {required String repoRoot}) {
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
    if (name is! String || name.isEmpty) {
      throw ManifestException(
        'Package name not found in ${p.relative(file.path, from: repoRoot)}',
      );
    }
    return Pubspec(file: file, document: document, name: name);
  }

  final File file;
  final YamlMap document;
  final String name;

  /// The `environment: flutter:` constraint, or `null` for a package that
  /// does not declare one.
  ///
  /// Throws [PubspecException] when the constraint does not parse.
  VersionConstraint? get flutterConstraint {
    final environment = document['environment'];
    if (environment is! YamlMap) return null;
    final raw = environment['flutter'];
    if (raw == null) return null;
    try {
      return VersionConstraint.parse(raw.toString());
    } on FormatException catch (e) {
      throw PubspecException(
        '${file.path} declares an invalid flutter constraint: ${e.message}',
      );
    }
  }
}
