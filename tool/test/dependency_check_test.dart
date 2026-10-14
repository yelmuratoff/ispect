@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/dependency_check.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/version_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

const _version = '7.0.0-rc.1';
const _stale = '6.9.0';

String _pubspec({
  required String name,
  String version = _version,
  String body = '',
}) =>
    '''
name: $name
version: $version
description: fixture package.

environment:
  sdk: ">=3.6.0 <4.0.0"
$body''';

/// A three-package monorepo whose files each variant overrides by path.
Map<String, String> _baseRepo() => {
      'version.config': 'VERSION=$_version\n',
      'packages/alpha/pubspec.yaml': _pubspec(
        name: 'alpha',
        body: '''
dependency_overrides:
  beta:
    path: ../beta

dependencies:
  beta: ^$_version

dev_dependencies:
  gamma: ^$_version
''',
      ),
      'packages/beta/pubspec.yaml': _pubspec(name: 'beta'),
      'packages/gamma/pubspec.yaml': _pubspec(name: 'gamma'),
      'packages/alpha/example/pubspec.yaml': '''
name: alpha_example
description: fixture example.
publish_to: none
version: 1.0.0

environment:
  sdk: ">=3.6.0 <4.0.0"

dependencies:
  alpha: ^$_version
  beta: ^$_version

dev_dependencies:
  gamma: ^$_version

dependency_overrides:
  alpha:
    path: ../
  beta:
    path: ../../beta
''',
      'web_logs_viewer/pubspec.yaml': '''
name: web_logs_viewer
description: fixture viewer.
publish_to: none
version: 1.0.0

environment:
  sdk: ">=3.6.0 <4.0.0"

dependency_overrides:
  alpha:
    path: ../packages/alpha

dependencies:
  alpha: ^$_version

dev_dependencies:
  gamma: ^$_version
''',
    };

Directory _writeRepo(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('ispect_dep_check');
  addTearDown(() => root.deleteSync(recursive: true));
  files.forEach((relative, contents) {
    final file = File(p.join(root.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  });
  return root;
}

Map<String, String> _repoWith(Map<String, String> overrides) =>
    _baseRepo()..addAll(overrides);

List<DependencyInconsistency> _dartFindings(Directory root) =>
    DependencyCheck(root.path)
        .findInconsistencies(VersionConfig.forRepo(root.path).read());

/// `(dependency, constraint)` pairs, sorted, so bash output and Dart findings
/// compare without depending on traversal order.
List<String> _dartPairs(List<DependencyInconsistency> found) =>
    [for (final f in found) '${f.dependency} ${f.constraint}']..sort();

void main() {
  group('DependencyCheck', () {
    test('accepts a repository whose internal constraints all match', () {
      final root = _writeRepo(_baseRepo());
      expect(_dartFindings(root), isEmpty);
      expect(
        () => DependencyCheck(root.path).assertConsistent(
          Version.parse(_version),
        ),
        returnsNormally,
      );
    });

    test('reports the package, the constraint, and the expected constraint',
        () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta: ^$_stale\n',
          ),
        }),
      );

      final found = _dartFindings(root);
      expect(found, hasLength(1));
      expect(found.single.owner, 'alpha');
      expect(found.single.dependency, 'beta');
      expect(found.single.constraint, '^$_stale');
      expect(found.single.section, PubspecSection.dependencies);
      expect(found.single.pubspec, p.join('packages', 'alpha', 'pubspec.yaml'));
      expect(
        found.single.describe(Version.parse(_version)),
        contains('should be ^$_version'),
      );
    });

    test('separates a stale dev_dependencies constraint from dependencies', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta: ^$_version\n'
                '\ndev_dependencies:\n  gamma: ^$_stale\n',
          ),
        }),
      );

      final found = _dartFindings(root);
      expect(found, hasLength(1));
      expect(found.single.section, PubspecSection.devDependencies);
      expect(found.single.dependency, 'gamma');
    });

    test('ignores a stale dependency_overrides constraint', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependency_overrides:\n  beta: ^$_stale\n'
                '\ndependencies:\n  beta: ^$_version\n',
          ),
        }),
      );

      expect(_dartFindings(root), isEmpty);
    });

    test('ignores a self-referencing constraint in a package pubspec', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  alpha: ^$_stale\n',
          ),
        }),
      );

      expect(_dartFindings(root), isEmpty);
    });

    test('flags the parent package constraint inside an example project', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/example/pubspec.yaml': '''
name: alpha_example
publish_to: none
version: 1.0.0

dependencies:
  alpha: ^$_stale
''',
        }),
      );

      final found = _dartFindings(root);
      expect(found, hasLength(1));
      expect(found.single.owner, 'alpha_example');
      expect(found.single.dependency, 'alpha');
    });

    test('flags a stale constraint in the standalone web viewer', () {
      final root = _writeRepo(
        _repoWith({
          'web_logs_viewer/pubspec.yaml': '''
name: web_logs_viewer
publish_to: none
version: 1.0.0

dependencies:
  alpha: ^$_stale

dev_dependencies:
  gamma: ^$_stale
''',
        }),
      );

      expect(
        _dartPairs(_dartFindings(root)),
        ['alpha ^$_stale', 'gamma ^$_stale'],
      );
    });

    test('ignores a path dependency, which declares no version', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta:\n    path: ../beta\n',
          ),
        }),
      );

      expect(_dartFindings(root), isEmpty);
    });

    for (final (form, constraint) in [
      ('an exact', _stale),
      ('an exact current', _version),
      ('a range', "'>=$_stale <8.0.0'"),
      ('an unconstrained', 'any'),
    ]) {
      test('flags $form constraint that is not ^VERSION', () {
        final root = _writeRepo(
          _repoWith({
            'packages/alpha/pubspec.yaml': _pubspec(
              name: 'alpha',
              body: '\ndependencies:\n  beta: $constraint\n',
            ),
          }),
        );

        final found = _dartFindings(root);
        expect(found, hasLength(1));
        expect(found.single.dependency, 'beta');
        expect(found.single.constraint, isNot('^$_version'));
      });
    }

    test('flags a bare entry, which pub reads as any', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta:\n',
          ),
        }),
      );

      expect(_dartPairs(_dartFindings(root)), ['beta any']);
    });

    test('flags an exact version written in the long hosted form', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta: {version: $_version}\n',
          ),
        }),
      );

      expect(_dartPairs(_dartFindings(root)), ['beta $_version']);
    });

    test('accepts ^VERSION written in the long hosted form', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta:\n    version: ^$_version\n',
          ),
        }),
      );

      expect(_dartFindings(root), isEmpty);
    });

    test('ignores third-party packages that are not part of the monorepo', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body:
                '\ndependencies:\n  collection: ^1.19.0\n  beta: ^$_version\n',
          ),
        }),
      );

      expect(_dartFindings(root), isEmpty);
    });

    test('reads a repository with no packages directory as consistent', () {
      final root = _writeRepo({'version.config': 'VERSION=$_version\n'});
      expect(_dartFindings(root), isEmpty);
      expect(DependencyCheck(root.path).packageNames(), isEmpty);
    });

    test('names every offending constraint when asserting consistency', () {
      final root = _writeRepo(
        _repoWith({
          'packages/alpha/pubspec.yaml': _pubspec(
            name: 'alpha',
            body: '\ndependencies:\n  beta: ^$_stale\n'
                '\ndev_dependencies:\n  gamma: ^$_stale\n',
          ),
        }),
      );

      expect(
        () => DependencyCheck(root.path)
            .assertConsistent(Version.parse(_version)),
        throwsA(
          isA<DependencyConsistencyException>()
              .having((e) => e.inconsistencies, 'inconsistencies', hasLength(2))
              .having((e) => e.message, 'message', contains('2 internal')),
        ),
      );
    });

    test('rejects a pubspec that is not valid YAML', () {
      final root = _writeRepo(
        _repoWith({'packages/alpha/pubspec.yaml': 'name: alpha\n\tbad: [\n'}),
      );

      expect(
        () => _dartFindings(root),
        throwsA(isA<PubspecException>()),
      );
    });

    test('rejects a missing version.config before reading any pubspec', () {
      final root = _writeRepo(_baseRepo());
      File(p.join(root.path, 'version.config')).deleteSync();

      expect(
        () => VersionConfig.forRepo(root.path).read(),
        throwsA(isA<VersionConfigException>()),
      );
    });

    test('rejects a version.config whose VERSION is empty', () {
      final root = _writeRepo(_repoWith({'version.config': 'VERSION=\n'}));

      expect(
        () => VersionConfig.forRepo(root.path).read(),
        throwsA(isA<VersionConfigException>()),
      );
    });
  });

  /// The bash scanner reads `dependencies:` blocks with `grep -E "^  name: \^"`,
  /// which only sees a two-space-indented inline constraint, and never reads an
  /// example project's `dev_dependencies:` at all. A YAML parse sees those
  /// constraints, so the Dart check reports faults the bash release gate lets
  /// through.
  group('constraints the bash scanner cannot see', () {
    test('flags a stale dev_dependencies constraint in an example project', () {
      final files = _repoWith({
        'packages/alpha/example/pubspec.yaml': '''
name: alpha_example
publish_to: none
version: 1.0.0

dependencies:
  alpha: ^$_version

dev_dependencies:
  beta: ^$_stale
''',
      });

      final found = _dartFindings(_writeRepo(files));

      expect(_dartPairs(found), ['beta ^$_stale']);
    });

    test('flags a stale constraint written in the long hosted form', () {
      final files = _repoWith({
        'packages/alpha/pubspec.yaml': _pubspec(
          name: 'alpha',
          body: '\ndependencies:\n  beta:\n    version: ^$_stale\n',
        ),
      });

      final found = _dartFindings(_writeRepo(files));

      expect(_dartPairs(found), ['beta ^$_stale']);
    });
  });
}
