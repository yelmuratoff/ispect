import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/version_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory repo;

  setUp(() {
    repo = Directory.systemTemp.createTempSync('version-config-test.');
  });

  tearDown(() {
    if (repo.existsSync()) {
      repo.deleteSync(recursive: true);
    }
  });

  void writeConfig(String contents) {
    File(p.join(repo.path, 'version.config')).writeAsStringSync(contents);
  }

  group('read', () {
    test('returns the declared version', () {
      writeConfig('VERSION=7.0.0-rc.1\n');
      expect(
        VersionConfig.forRepo(repo.path).read().toString(),
        '7.0.0-rc.1',
      );
    });

    test('finds the version below a comment rather than taking line one', () {
      writeConfig('# pinned for the 7.0 line\nVERSION=7.0.0-rc.1\n');
      expect(
        VersionConfig.forRepo(repo.path).read().toString(),
        '7.0.0-rc.1',
      );
    });

    test('trims surrounding whitespace so generated files carry none', () {
      writeConfig('VERSION=  7.0.0-rc.1   \n');
      expect(
        VersionConfig.forRepo(repo.path).read().toString(),
        '7.0.0-rc.1',
      );
    });

    test('renders a parsed version back to the text it was written as', () {
      for (final raw in [
        '7.0.0-rc.1',
        '7.0.0-dev11',
        '1.0.0+5',
        '1.0.0-01',
        '1.0.0-alpha+build.1',
      ]) {
        writeConfig('VERSION=$raw\n');
        expect(
          VersionConfig.forRepo(repo.path).read().toString(),
          raw,
          reason: '$raw must round-trip so generated files stay identical',
        );
      }
    });

    test('rejects a value that is not a semantic version', () {
      writeConfig('VERSION=not-a-version\n');
      expect(
        () => VersionConfig.forRepo(repo.path).read(),
        throwsA(isA<VersionConfigException>()),
      );
    });

    test('rejects an empty value', () {
      writeConfig('VERSION=\n');
      expect(
        () => VersionConfig.forRepo(repo.path).read(),
        throwsA(isA<VersionConfigException>()),
      );
    });

    test('rejects a file that declares no version at all', () {
      writeConfig('CHANNEL=dev\n');
      expect(
        () => VersionConfig.forRepo(repo.path).read(),
        throwsA(isA<VersionConfigException>()),
      );
    });

    test('rejects a missing file', () {
      expect(
        () => VersionConfig.forRepo(repo.path).read(),
        throwsA(isA<VersionConfigException>()),
      );
    });
  });

  group('write', () {
    test('rewrites only the VERSION line', () {
      writeConfig('# keep me\nVERSION=7.0.0-rc.1\nCHANNEL=dev\n');
      VersionConfig.forRepo(repo.path).write(Version.parse('7.0.0-rc.2'));
      expect(
        File(p.join(repo.path, 'version.config')).readAsStringSync(),
        '# keep me\nVERSION=7.0.0-rc.2\nCHANNEL=dev\n',
      );
    });

    test('preserves a file that ends without a newline', () {
      writeConfig('VERSION=7.0.0-rc.1');
      VersionConfig.forRepo(repo.path).write(Version.parse('7.0.0-rc.2'));
      expect(
        File(p.join(repo.path, 'version.config')).readAsStringSync(),
        'VERSION=7.0.0-rc.2',
      );
    });
  });
}
