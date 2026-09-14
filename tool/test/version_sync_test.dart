@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/next_version.dart';
import 'package:ispect_tool/src/core/version_sync.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory repo;
  late StringBuffer out;
  late StringBuffer err;
  late VersionSync sync;

  setUp(() {
    repo = Directory.systemTemp.createTempSync('ispect-version-sync-unit-');
    out = StringBuffer();
    err = StringBuffer();
    sync = VersionSync(repoRoot: repo.path, out: out, err: err);
    _writeFixture(repo.path);
  });

  tearDown(() {
    if (repo.existsSync()) {
      repo.deleteSync(recursive: true);
    }
  });

  String read(String relative) =>
      File(p.join(repo.path, relative)).readAsStringSync();

  void write(String relative, String contents) {
    final file = File(p.join(repo.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  VersionSyncResult syncTo(String target, {bool dryRun = false}) => sync.run(
        current: Version.parse('1.2.3-dev.1'),
        target: Version.parse(target),
        dryRun: dryRun,
      );

  group('reading version.config', () {
    test('returns the declared version', () {
      expect(sync.readVersion(), Version.parse('1.2.3-dev.1'));
      expect(err.toString(), isEmpty);
    });

    test('warns when the prerelease counter is glued to its label', () {
      write('version.config', 'VERSION=1.2.3-dev11\n');

      expect(sync.readVersion(), Version.parse('1.2.3-dev11'));
      expect(err.toString(), contains('[WARN] 1.2.3-dev11 glues its counter'));
    });

    test('names the file relative to the repository when it is missing', () {
      File(p.join(repo.path, 'version.config')).deleteSync();

      expect(
        sync.readVersion,
        throwsA(
          isA<VersionConfigException>().having(
            (e) => e.message,
            'message',
            'version.config not found',
          ),
        ),
      );
    });

    test('names the file relative to the repository when it is invalid', () {
      write('version.config', 'VERSION=not-a-version\n');

      expect(
        sync.readVersion,
        throwsA(
          isA<VersionConfigException>().having(
            (e) => e.message,
            'message',
            'Invalid VERSION in version.config: not-a-version',
          ),
        ),
      );
    });
  });

  group('rewriting manifests', () {
    test('persists the target to version.config when it moved', () {
      syncTo('1.2.3-dev.2');

      expect(read('version.config'), 'VERSION=1.2.3-dev.2\n');
    });

    test('leaves version.config alone when the target did not move', () {
      sync.run(
        current: Version.parse('1.2.3-dev.1'),
        target: Version.parse('1.2.3-dev.1'),
      );

      expect(read('version.config'), 'VERSION=1.2.3-dev.1\n');
      expect(out.toString(), isNot(contains('- version.config')));
    });

    test('rewrites every package version line', () {
      syncTo('1.2.3-dev.2');

      expect(
        read('packages/ispect/pubspec.yaml'),
        contains('version: 1.2.3-dev.2'),
      );
      expect(
        read('packages/ispectify/pubspec.yaml'),
        contains('version: 1.2.3-dev.2'),
      );
    });

    test('rewrites constraints in dependencies and dev_dependencies', () {
      syncTo('1.2.3-dev.2');

      expect(
        read('packages/ispect/pubspec.yaml'),
        contains('  ispectify: ^1.2.3-dev.2'),
      );
      expect(
        read('packages/ispect/example/pubspec.yaml'),
        allOf(
          contains('  ispect: ^1.2.3-dev.2'),
          contains('  ispectify: ^1.2.3-dev.2'),
        ),
      );
    });

    test('leaves dependency_overrides constraints untouched', () {
      write('packages/ispect/pubspec.yaml', '''
name: ispect
version: 0.0.1
dependencies:
  ispectify: ^0.0.1
dependency_overrides:
  ispectify: ^0.0.1
''');

      syncTo('1.2.3-dev.2');

      expect(read('packages/ispect/pubspec.yaml'), '''
name: ispect
version: 1.2.3-dev.2
dependencies:
  ispectify: ^1.2.3-dev.2
dependency_overrides:
  ispectify: ^0.0.1
''');
    });

    test(
        'reports a constraint that only dependency_overrides carries without '
        'rewriting it', () {
      write('packages/ispect/pubspec.yaml', '''
name: ispect
version: 1.2.3-dev.2
dependency_overrides:
  ispectify: ^0.0.1
''');

      final result = syncTo('1.2.3-dev.2');

      expect(read('packages/ispect/pubspec.yaml'), contains('^0.0.1'));
      expect(result.changedFiles, contains('packages/ispect/pubspec.yaml'));
    });

    test('drops a trailing comment from a rewritten constraint', () {
      write('packages/ispect/pubspec.yaml', '''
name: ispect
version: 0.0.1
dependencies:
  ispectify: ^0.0.1 # pinned by the monorepo
''');

      syncTo('1.2.3-dev.2');

      expect(
        read('packages/ispect/pubspec.yaml'),
        contains('  ispectify: ^1.2.3-dev.2\n'),
      );
      expect(read('packages/ispect/pubspec.yaml'), isNot(contains('pinned')));
    });

    test('leaves unrelated files byte-for-byte unchanged', () {
      final before = read('README.md');

      syncTo('1.2.3-dev.2');

      expect(read('README.md'), before);
    });

    test('reports a manifest once per kind of change', () {
      final result = syncTo('1.2.3-dev.2');

      expect(result.changedFiles, [
        'web_logs_viewer/pubspec.lock',
        'version.config',
        'packages/ispect/pubspec.yaml',
        'packages/ispect/pubspec.yaml',
        'packages/ispect/example/pubspec.yaml',
        'packages/ispectify/pubspec.yaml',
        'web_logs_viewer/pubspec.yaml',
      ]);
    });

    test('reports a manifest that already carries the target as unchanged', () {
      final result = sync.run(
        current: Version.parse('0.0.1'),
        target: Version.parse('0.0.1'),
      );

      expect(result.changedFiles, isEmpty);
      expect(
        out.toString(),
        contains('[OK ] packages/ispect/pubspec.yaml already 0.0.1'),
      );
      expect(out.toString(), contains('  (no file changes)'));
    });
  });

  group('writing', () {
    test('leaves no temporary file behind', () {
      syncTo('1.2.3-dev.2');

      final leftovers = Directory(repo.path)
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => p.relative(file.path, from: repo.path))
          .where((path) => path.contains('.tmp.'));

      expect(leftovers, isEmpty);
    });

    test('does not clobber a pre-existing .tmp file', () {
      syncTo('1.2.3-dev.2');

      expect(read('version.config.tmp'), 'pre-existing version temp\n');
      expect(
        read('packages/ispect/pubspec.yaml.tmp'),
        'pre-existing pubspec temp\n',
      );
    });

    test('a dry run reports the same changes and writes nothing', () {
      final before = _snapshot(repo.path);

      final result = syncTo('1.2.3-dev.2', dryRun: true);

      expect(_snapshot(repo.path), before);
      expect(result.changedFiles, isNotEmpty);
      expect(out.toString(), contains('(dry-run=1)'));
      expect(out.toString(), contains('[DONE] Dry-run completed'));
    });
  });

  group('the web lockfile', () {
    test('rewrites the version of every locally pathed package', () {
      syncTo('1.2.3-dev.2');

      expect(read('web_logs_viewer/pubspec.lock'), '''
packages:
  collection:
    dependency: "direct main"
    description:
      name: collection
      sha256: preserved-hosted-checksum
    source: hosted
    version: "1.19.1"
  ispect:
    dependency: "direct main"
    description:
      path: "../packages/ispect"
    source: path
    version: "1.2.3-dev.2"
  ispectify:
    dependency: "direct main"
    description:
      path: "../packages/ispectify"
    source: path
    version: "1.2.3-dev.2"
''');
    });

    test('is left alone when the manifest references no local path', () {
      write('web_logs_viewer/pubspec.yaml', '''
name: web_logs_viewer
dependencies:
  ispect: ^0.0.1
''');
      write('web_logs_viewer/pubspec.lock', 'fixture-lock: preserved\n');

      syncTo('1.2.3-dev.2');

      expect(read('web_logs_viewer/pubspec.lock'), 'fixture-lock: preserved\n');
    });

    test('is required once the manifest references a local path', () {
      File(p.join(repo.path, 'web_logs_viewer', 'pubspec.lock')).deleteSync();

      expect(
        () => syncTo('1.2.3-dev.2'),
        throwsA(
          isA<ManifestException>().having(
            (e) => e.message,
            'message',
            'web_logs_viewer/pubspec.lock is required for local web path '
                'dependencies',
          ),
        ),
      );
    });

    test('aborts the whole run before writing when a stanza is malformed', () {
      write('web_logs_viewer/pubspec.lock', '''
packages:
  ispect:
    dependency: "direct main"
    description:
      path: "../packages/ispect"
    source: path
''');
      final before = _snapshot(repo.path);

      expect(
        () => syncTo('1.2.3-dev.2'),
        throwsA(
          isA<ManifestException>().having(
            (e) => e.message,
            'message',
            'Invalid path package stanza in web_logs_viewer/pubspec.lock: '
                'ispect',
          ),
        ),
      );
      expect(_snapshot(repo.path), before);
    });

    test('rejects a package that holds two stanzas', () {
      write('web_logs_viewer/pubspec.lock', '''
packages:
  ispect:
    source: path
    version: "0.0.1"
  ispect:
    source: path
    version: "0.0.1"
  ispectify:
    source: path
    version: "0.0.1"
''');

      expect(() => syncTo('1.2.3-dev.2'), throwsA(isA<ManifestException>()));
    });

    test('reports the lockfile as unchanged when it already pins the target',
        () {
      final result = sync.run(
        current: Version.parse('0.0.1'),
        target: Version.parse('0.0.1'),
      );

      expect(result.changedFiles, isEmpty);
      expect(
        out.toString(),
        contains(
          '[OK ] web_logs_viewer/pubspec.lock path package versions already '
          '0.0.1',
        ),
      );
    });
  });

  group('discovering packages', () {
    test('fails when packages/ holds no manifest', () {
      Directory(p.join(repo.path, 'packages')).deleteSync(recursive: true);

      expect(
        () => syncTo('1.2.3-dev.2'),
        throwsA(
          isA<ManifestException>().having(
            (e) => e.message,
            'message',
            'No package pubspecs found',
          ),
        ),
      );
    });

    test('fails when a manifest declares no name', () {
      write('packages/broken/pubspec.yaml', 'version: 0.0.1\n');

      expect(
        () => syncTo('1.2.3-dev.2'),
        throwsA(
          isA<ManifestException>().having(
            (e) => e.message,
            'message',
            'Package name not found in packages/broken/pubspec.yaml',
          ),
        ),
      );
    });

    test('lists packages in directory order', () {
      write('packages/ispect_layout/pubspec.yaml', 'name: ispect_layout\n');

      syncTo('1.2.3-dev.2');

      expect(
        out.toString(),
        contains('[INFO] Packages: ispect ispect_layout ispectify'),
      );
    });
  });

  group('bumping', () {
    test('advances the prerelease counter of a dot-form prerelease', () {
      expect(
        sync.bump(Version.parse('1.2.3-dev.1'), BumpKind.patch),
        Version.parse('1.2.3-dev.2'),
      );
    });

    test('leaves the prerelease behind on a minor bump', () {
      expect(
        sync.bump(Version.parse('1.2.3-dev.1'), BumpKind.minor),
        Version.parse('1.3.0'),
      );
    });
  });

  group('the argument surface', () {
    int run(List<String> arguments) => runVersionSync(
          repoRoot: repo.path,
          arguments: arguments,
          out: out,
          err: err,
        );

    test('a bump writes the computed version everywhere', () {
      expect(run(['--bump', 'patch']), 0);
      expect(read('version.config'), 'VERSION=1.2.3-dev.2\n');
      expect(
        out.toString(),
        contains('[INFO] Bump patch: 1.2.3-dev.1 -> 1.2.3-dev.2'),
      );
    });

    test('a run without arguments syncs to the declared version', () {
      expect(run(const []), 0);
      expect(read('version.config'), 'VERSION=1.2.3-dev.1\n');
      expect(
        read('packages/ispect/pubspec.yaml'),
        contains('version: 1.2.3-dev.1'),
      );
    });

    test('an unknown argument exits 2 without writing', () {
      final before = _snapshot(repo.path);

      expect(run(['--nope']), 2);
      expect(err.toString(), contains('[ERR] Unknown argument: --nope'));
      expect(_snapshot(repo.path), before);
    });

    test('a bump without a kind exits 2 without writing', () {
      final before = _snapshot(repo.path);

      expect(run(['--bump']), 2);
      expect(
        err.toString(),
        contains('[ERR] --bump requires patch, minor, or major'),
      );
      expect(_snapshot(repo.path), before);
    });

    test('an unknown bump kind exits 1 without writing', () {
      final before = _snapshot(repo.path);

      expect(run(['--bump', 'huge']), 1);
      expect(err.toString(), contains('[ERR] Unknown bump kind: huge'));
      expect(_snapshot(repo.path), before);
    });

    test('help exits 0 without writing', () {
      final before = _snapshot(repo.path);

      expect(run(['--help']), 0);
      expect(out.toString(), contains('Current VERSION: 1.2.3-dev.1'));
      expect(_snapshot(repo.path), before);
    });

    test('a missing version.config exits 1', () {
      File(p.join(repo.path, 'version.config')).deleteSync();

      expect(run(const []), 1);
      expect(err.toString(), contains('[ERR] version.config not found'));
    });

    test('a malformed lockfile exits 1', () {
      write('web_logs_viewer/pubspec.lock', '''
packages:
  ispect:
    source: path
''');

      expect(run(['--bump', 'patch']), 1);
      expect(
        err.toString(),
        contains(
          '[ERR] Invalid path package stanza in web_logs_viewer/pubspec.lock: '
          'ispect',
        ),
      );
    });
  });
}

void _writeFixture(String repo) {
  void write(String relative, String contents) {
    final file = File(p.join(repo, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  write('version.config', 'VERSION=1.2.3-dev.1\n');
  write('version.config.tmp', 'pre-existing version temp\n');
  write('README.md', 'unchanged: ispect: ^0.0.1\n');

  write('packages/ispect/pubspec.yaml', '''
name: ispect
version: 0.0.1
dependencies:
  ispectify: ^0.0.1
dependency_overrides:
  ispectify:
    path: ../ispectify
''');
  write('packages/ispect/pubspec.yaml.tmp', 'pre-existing pubspec temp\n');
  write('packages/ispect/example/pubspec.yaml', '''
name: ispect_example
dependencies:
  ispect: ^0.0.1
dev_dependencies:
  ispectify: ^0.0.1
dependency_overrides:
  ispect:
    path: ..
''');
  write('packages/ispectify/pubspec.yaml', '''
name: ispectify
version: 0.0.1
environment:
  sdk: ^3.6.0
''');

  write('web_logs_viewer/pubspec.yaml', '''
name: web_logs_viewer
dependency_overrides:
  ispect:
    path: ../packages/ispect
  ispectify:
    path: ../packages/ispectify
dependencies:
  ispect: ^0.0.1
  ispectify: ^0.0.1
''');
  write('web_logs_viewer/pubspec.lock', '''
packages:
  collection:
    dependency: "direct main"
    description:
      name: collection
      sha256: preserved-hosted-checksum
    source: hosted
    version: "1.19.1"
  ispect:
    dependency: "direct main"
    description:
      path: "../packages/ispect"
    source: path
    version: "0.0.1"
  ispectify:
    dependency: "direct main"
    description:
      path: "../packages/ispectify"
    source: path
    version: "0.0.1"
''');
}

Map<String, String> _snapshot(String root) => {
      for (final file
          in Directory(root).listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: root): file.readAsStringSync(),
    };
