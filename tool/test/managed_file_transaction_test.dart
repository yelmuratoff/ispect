@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/managed_file_transaction.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory workspace;
  late Directory tempRoot;
  late String repo;
  late StringBuffer err;

  const managed = [
    'version.config',
    'CHANGELOG.md',
    'README.md',
    'llms.txt',
    'packages/ispect/pubspec.yaml',
    'packages/ispect/CHANGELOG.md',
  ];

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-txn-');
    tempRoot = Directory(p.join(workspace.path, 'tmp'))..createSync();
    repo = p.join(workspace.path, 'repo');
    err = StringBuffer();

    _write(p.join(repo, 'version.config'), 'VERSION=7.0.0-dev.1\n');
    _write(p.join(repo, 'CHANGELOG.md'), '# Changelog\n\n## 7.0.0-dev.1\n');
    _write(p.join(repo, 'README.md'), 'root readme\n');
    _write(p.join(repo, 'llms.txt'), 'index\n');
    _write(
      p.join(repo, 'packages', 'ispect', 'pubspec.yaml'),
      'name: ispect\nversion: 7.0.0-dev.1\n',
    );
    _write(
      p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'),
      '# Changelog\n\n## 7.0.0-dev.1\n',
    );
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  ManagedFileTransaction transaction({List<String> paths = managed}) =>
      ManagedFileTransaction(
        repoRoot: repo,
        targets: paths,
        err: err,
        tempRoot: tempRoot,
      );

  group('path validation', () {
    test('rejects an absolute managed path', () {
      expect(
        () => transaction(paths: ['/etc/passwd']).validate(),
        throwsA(
          isA<ManagedPathException>().having(
            (e) => e.message,
            'message',
            'Managed path escapes the repository: /etc/passwd',
          ),
        ),
      );
    });

    test('rejects a path that climbs out of the repository', () {
      for (final escape in ['../outside.md', 'packages/../../outside.md']) {
        expect(
          () => transaction(paths: [escape]).validate(),
          throwsA(
            isA<ManagedPathException>().having(
              (e) => e.message,
              'message',
              'Managed path escapes the repository: $escape',
            ),
          ),
          reason: escape,
        );
      }
    });

    test('rejects a path whose final segment is a parent reference', () {
      expect(
        () => transaction(paths: ['packages/..']).validate(),
        throwsA(isA<ManagedPathException>()),
      );
    });

    test('rejects a managed target that is itself a symlink', () {
      final outside = p.join(workspace.path, 'outside.md');
      _write(outside, 'outside sentinel\n');
      File(p.join(repo, 'README.md')).deleteSync();
      Link(p.join(repo, 'README.md')).createSync(outside);

      expect(
        () => transaction().validate(),
        throwsA(
          isA<ManagedPathException>().having(
            (e) => e.message,
            'message',
            'Managed paths cannot contain symlinks: README.md',
          ),
        ),
      );
    });

    test('rejects a managed target reached through a symlinked directory', () {
      final outside = Directory(p.join(workspace.path, 'elsewhere'))
        ..createSync();
      _write(p.join(outside.path, 'pubspec.yaml'), 'name: ispect\n');
      Directory(p.join(repo, 'packages', 'ispect')).deleteSync(recursive: true);
      Link(p.join(repo, 'packages', 'ispect')).createSync(outside.path);

      expect(
        () => transaction().validate(),
        throwsA(
          isA<ManagedPathException>().having(
            (e) => e.message,
            'message',
            'Managed paths cannot contain symlinks: packages/ispect/'
                'pubspec.yaml',
          ),
        ),
      );
    });

    test('rejects a managed target that is a directory', () {
      File(p.join(repo, 'llms.txt')).deleteSync();
      Directory(p.join(repo, 'llms.txt')).createSync();

      expect(
        () => transaction().validate(),
        throwsA(
          isA<ManagedPathException>().having(
            (e) => e.message,
            'message',
            'Managed target must be a regular file: llms.txt',
          ),
        ),
      );
    });

    test('rejects a managed target whose parent is a regular file', () {
      Directory(p.join(repo, 'packages', 'ispect')).deleteSync(recursive: true);
      _write(p.join(repo, 'packages', 'ispect'), 'not a directory\n');

      expect(
        () => transaction().validate(),
        throwsA(
          isA<ManagedPathException>().having(
            (e) => e.message,
            'message',
            'Managed path parent must be a directory: packages/ispect',
          ),
        ),
      );
    });

    test('accepts a repository reached through a symlinked ancestor', () {
      final link = p.join(workspace.path, 'linked-repo');
      Link(link).createSync(repo);

      final viaLink = ManagedFileTransaction(
        repoRoot: link,
        targets: managed,
        err: err,
        tempRoot: tempRoot,
      );

      expect(viaLink.validate, returnsNormally);
    });

    test('writes nothing to the temp root when validation rejects a path', () {
      File(p.join(repo, 'llms.txt')).deleteSync();
      Directory(p.join(repo, 'llms.txt')).createSync();
      final subject = transaction();

      expect(subject.begin, throwsA(isA<ManagedPathException>()));
      expect(tempRoot.listSync(), isEmpty);
      expect(subject.snapshotPath, isNull);
    });
  });

  group('rollback', () {
    test('restores the tree byte-for-byte when nothing was written yet', () {
      final before = _snapshot(repo);
      final subject = transaction()..begin();

      expect(subject.rollback(), isTrue);
      expect(_snapshot(repo), before);
      expect(err.toString(), isEmpty);
    });

    test('restores files a run had already rewritten', () {
      final before = _snapshot(repo);
      final subject = transaction()..begin();

      _write(p.join(repo, 'version.config'), 'VERSION=7.0.0-dev.2\n');
      _write(p.join(repo, 'README.md'), 'half-generated readme\n');
      _write(
        p.join(repo, 'packages', 'ispect', 'pubspec.yaml'),
        'name: ispect\nversion: 7.0.0-dev.2\n',
      );

      expect(subject.rollback(), isTrue);
      expect(_snapshot(repo), before);
    });

    test('removes a managed file the run created', () {
      File(p.join(repo, 'llms.txt')).deleteSync();
      final before = _snapshot(repo);
      final subject = transaction()..begin();

      _write(p.join(repo, 'llms.txt'), 'generated index\n');

      expect(subject.rollback(), isTrue);
      expect(File(p.join(repo, 'llms.txt')).existsSync(), isFalse);
      expect(_snapshot(repo), before);
    });

    test('restores a managed file the run deleted', () {
      final before = _snapshot(repo);
      final subject = transaction()..begin();

      File(p.join(repo, 'CHANGELOG.md')).deleteSync();

      expect(subject.rollback(), isTrue);
      expect(_snapshot(repo), before);
    });

    test('recreates a parent directory the run removed', () {
      final before = _snapshot(repo);
      final subject = transaction()..begin();

      Directory(p.join(repo, 'packages', 'ispect')).deleteSync(recursive: true);

      expect(subject.rollback(), isTrue);
      expect(_snapshot(repo), before);
    });

    test('preserves the permission bits of a restored file', () {
      final target = File(p.join(repo, 'llms.txt'));
      Process.runSync('chmod', ['0640', target.path]);
      final before = target.statSync().mode & 0xFFF;

      final subject = transaction()..begin();
      target.writeAsStringSync('rewritten\n');
      Process.runSync('chmod', ['0666', target.path]);

      expect(subject.rollback(), isTrue);
      expect(target.statSync().mode & 0xFFF, before);
    });

    test('reports an unreadable manifest instead of restoring blindly', () {
      final subject = transaction()..begin();
      File(p.join(subject.snapshotPath!, 'existing')).deleteSync();

      _write(p.join(repo, 'README.md'), 'half-generated readme\n');

      expect(subject.rollback(), isFalse);
      expect(
        err.toString(),
        contains('Recovery snapshot manifest is not readable'),
      );
      expect(
        File(p.join(repo, 'version.config')).existsSync(),
        isTrue,
        reason: 'a failed manifest read must not delete pre-existing targets',
      );
    });

    test('refuses to restore through a symlink introduced mid-run', () {
      final subject = transaction()..begin();

      final outside = Directory(p.join(workspace.path, 'elsewhere'))
        ..createSync();
      _write(p.join(outside.path, 'pubspec.yaml'), 'attacker owned\n');
      Directory(p.join(repo, 'packages', 'ispect')).deleteSync(recursive: true);
      Link(p.join(repo, 'packages', 'ispect')).createSync(outside.path);

      expect(subject.rollback(), isFalse);
      expect(
        err.toString(),
        contains('Cannot safely restore through a symlink: packages/ispect/'
            'pubspec.yaml'),
      );
      expect(
        File(p.join(outside.path, 'pubspec.yaml')).readAsStringSync(),
        'attacker owned\n',
      );
    });

    test('restores the other targets after one of them fails', () {
      final before = _snapshot(repo);
      final subject = transaction()..begin();

      _write(p.join(repo, 'version.config'), 'VERSION=7.0.0-dev.2\n');
      _write(p.join(repo, 'llms.txt'), 'regenerated\n');
      File(p.join(repo, 'packages', 'ispect', 'pubspec.yaml')).deleteSync();
      Directory(p.join(repo, 'packages', 'ispect', 'pubspec.yaml'))
          .createSync();

      expect(subject.rollback(), isFalse);
      expect(
        err.toString(),
        contains('Cannot replace directory while restoring '
            'packages/ispect/pubspec.yaml'),
      );

      final after = _snapshot(repo);
      for (final path in ['version.config', 'llms.txt', 'CHANGELOG.md']) {
        expect(after[path], before[path], reason: path);
      }
    });
  });

  group('snapshot lifecycle', () {
    test('places the snapshot under the temp root it was given', () {
      final subject = transaction()..begin();

      expect(
        p.basename(subject.snapshotPath!),
        startsWith('ispect-release-prep.'),
      );
      expect(
        Directory(p.dirname(subject.snapshotPath!)).resolveSymbolicLinksSync(),
        tempRoot.resolveSymbolicLinksSync(),
      );
    });

    test('reports work still owed until it is committed', () {
      final subject = transaction();
      expect(subject.isPending, isFalse);

      subject.begin();
      expect(subject.isPending, isTrue);

      subject.commit();
      expect(subject.isPending, isFalse);
    });

    test('removes its own snapshot directory', () {
      final subject = transaction()..begin();
      final path = subject.snapshotPath!;

      expect(subject.dispose(), isTrue);
      expect(Directory(path).existsSync(), isFalse);
      expect(subject.snapshotPath, isNull);
    });

    test('removes a snapshot created under a symlinked temp root', () {
      final linked = p.join(workspace.path, 'linked-tmp');
      Link(linked).createSync(tempRoot.path);

      final subject = ManagedFileTransaction(
        repoRoot: repo,
        targets: managed,
        err: err,
        tempRoot: Directory(linked),
      )..begin();
      final path = subject.snapshotPath!;

      expect(subject.dispose(), isTrue);
      expect(Directory(path).existsSync(), isFalse);
      expect(err.toString(), isEmpty);
    });

    test('tolerates a snapshot directory that vanished before cleanup', () {
      final subject = transaction()..begin();
      Directory(subject.snapshotPath!).deleteSync(recursive: true);

      expect(subject.dispose(), isTrue);
      expect(err.toString(), isEmpty);
    });
  });
}

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

Map<String, String> _snapshot(String root) => {
      for (final file
          in Directory(root).listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: root): file.readAsStringSync(),
    };
