import 'dart:io';

import 'package:ispect_tool/src/core/dependency_check.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/next_version.dart';
import 'package:ispect_tool/src/core/pubspec.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:ispect_tool/src/core/version_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory repo;

  setUp(() {
    repo = Directory.systemTemp.createTempSync('package-layout-test.');
  });

  tearDown(() {
    if (repo.existsSync()) {
      repo.deleteSync(recursive: true);
    }
  });

  File write(String relative, String contents) {
    final file = File(p.join(repo.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
    return file;
  }

  group('packageDirectories', () {
    test('lists only directories under packages/, sorted', () {
      write('packages/zeta/pubspec.yaml', 'name: zeta\n');
      write('packages/alpha/pubspec.yaml', 'name: alpha\n');
      write('packages/notes.txt', 'not a package');

      expect(
        packageDirectories(repo.path).map(p.basename),
        ['alpha', 'zeta'],
      );
    });

    test('returns nothing when packages/ is absent', () {
      expect(packageDirectories(repo.path), isEmpty);
    });
  });

  group('Pubspec.read', () {
    test('returns the declared name', () {
      final file = write('packages/alpha/pubspec.yaml', 'name: alpha\n');

      expect(Pubspec.read(file, repoRoot: repo.path).name, 'alpha');
    });

    test('names the repository-relative file when the name is missing', () {
      final file = write('packages/broken/pubspec.yaml', 'version: 0.0.1\n');

      expect(
        () => Pubspec.read(file, repoRoot: repo.path),
        throwsA(
          isA<ManifestException>().having(
            (e) => e.message,
            'message',
            'Package name not found in packages/broken/pubspec.yaml',
          ),
        ),
      );
    });

    test('rejects a file that is not a YAML mapping', () {
      final file = write('packages/list/pubspec.yaml', '- alpha\n');

      expect(
        () => Pubspec.read(file, repoRoot: repo.path),
        throwsA(isA<PubspecException>()),
      );
    });
  });

  group('a nameless package pubspec', () {
    setUp(() => write('packages/broken/pubspec.yaml', 'version: 0.0.1\n'));

    test('fails the version listing instead of using the directory', () {
      expect(
        () => PackageVersions(repo.path).read(),
        throwsA(isA<ManifestException>()),
      );
    });

    test('fails the dependency check instead of using the path', () {
      expect(
        () => DependencyCheck(repo.path).packageNames(),
        throwsA(isA<ManifestException>()),
      );
    });
  });

  group('writeGluedCounterWarning', () {
    test('warns about a counter glued to its label', () {
      final sink = StringBuffer();

      writeGluedCounterWarning(sink, Version.parse('7.0.0-dev11'));

      expect(
        sink.toString(),
        startsWith('[WARN] 7.0.0-dev11 glues its counter to the prerelease '
            'label, so Pub compares that counter as text'),
      );
      expect('\n'.allMatches(sink.toString()), hasLength(2));
    });

    test('stays silent for a dotted counter', () {
      final sink = StringBuffer();

      writeGluedCounterWarning(sink, Version.parse('7.1.0-dev.4'));

      expect(sink.toString(), isEmpty);
    });
  });
}
