import 'dart:io';

import 'package:path/path.dart' as p;
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
}
