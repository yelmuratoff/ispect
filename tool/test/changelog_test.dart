@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/changelog.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const String _rootChangelog = '''
# Changelog

## 2.0.0

- Second major line.
- Another entry.

## 1.9.0

- Older line.

## 1.8.0

- Oldest line.
''';

void main() {
  late Directory workspace;
  late String repo;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-changelog-');
    repo = p.join(workspace.path, 'repo');
    _writeFixture(repo);
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  ChangelogPropagator propagator({StringSink? out}) => ChangelogPropagator(
        repoRoot: repo,
        out: out ?? StringBuffer(),
        err: StringBuffer(),
      );

  group('reading the root changelog', () {
    test('takes the newest version from the topmost heading', () {
      expect(propagator().latestVersion(), '2.0.0');
    });

    test('reads only the version token from a dated heading', () {
      _write(
        p.join(repo, 'CHANGELOG.md'),
        '# Changelog\n\n## 3.0.0 - 2026-01-01\n\n- Dated.\n',
      );

      expect(propagator().latestVersion(), '3.0.0');
    });

    test('extracts a section up to the next version heading', () {
      expect(
        propagator().extractSection('1.9.0'),
        '## 1.9.0\n\n- Older line.',
      );
    });

    test('extracts the newest section without trailing blank lines', () {
      expect(
        propagator().extractSection('2.0.0'),
        '## 2.0.0\n\n- Second major line.\n- Another entry.',
      );
    });

    test('extracts the last section in the file', () {
      expect(
        propagator().extractSection('1.8.0'),
        '## 1.8.0\n\n- Oldest line.',
      );
    });

    test('rejects a version with no heading', () {
      expect(
        () => propagator().extractSection('9.9.9'),
        throwsA(isA<ChangelogException>()),
      );
    });

    test('rejects a version whose heading carries a suffix', () {
      _write(
        p.join(repo, 'CHANGELOG.md'),
        '# Changelog\n\n## 2.0.0 - 2026-01-01\n\n- Dated.\n',
      );

      expect(
        () => propagator().extractSection('2.0.0'),
        throwsA(isA<ChangelogException>()),
      );
    });

    test('rejects a missing root changelog', () {
      File(p.join(repo, 'CHANGELOG.md')).deleteSync();

      expect(
        () => propagator().latestVersion(),
        throwsA(isA<ChangelogException>()),
      );
    });
  });

  group('appending the latest section', () {
    test('appends the newest section to a package that lacks it', () {
      final result = propagator().run();

      final contents = File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
          .readAsStringSync();
      expect(result.appended, contains('packages/ispect/CHANGELOG.md'));
      expect(contents, contains('## 2.0.0'));
      expect(contents, contains('- Second major line.'));
    });

    test('separates the appended section with one blank line', () {
      propagator().run();

      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        '# Ispect changelog\n\n## 1.9.0\n\n- Older line.\n'
        '\n## 2.0.0\n\n- Second major line.\n- Another entry.\n',
      );
    });

    test('leaves a package that already has the section untouched', () {
      final changelog =
          File(p.join(repo, 'packages', 'ispectify', 'CHANGELOG.md'));
      final before = changelog.readAsStringSync();

      final result = propagator().run();

      expect(result.skipped, contains('packages/ispectify/CHANGELOG.md'));
      expect(changelog.readAsStringSync(), before);
    });

    test('reports a package without a changelog as missing', () {
      final result = propagator().run();

      expect(result.missing, contains('packages/ispect_layout/CHANGELOG.md'));
      expect(
        File(p.join(repo, 'packages', 'ispect_layout', 'CHANGELOG.md'))
            .existsSync(),
        isFalse,
      );
    });

    test('running twice appends the section only once', () {
      propagator().run();
      final afterFirst =
          File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
              .readAsStringSync();
      propagator().run();

      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        afterFirst,
      );
    });

    test('propagates an explicitly requested older version', () {
      final result = propagator().run(version: '1.8.0');

      expect(result.version, '1.8.0');
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        contains('- Oldest line.'),
      );
    });

    test('reports the target version before propagating', () {
      final out = StringBuffer();

      propagator(out: out).run();

      expect(out.toString(), startsWith('[INFO] Root version target: 2.0.0\n'));
      expect(
        out.toString(),
        endsWith('[DONE] Changelog propagation complete\n'),
      );
    });
  });

  group('overwriting every package changelog', () {
    test('replaces each package changelog with the root one', () {
      final result = propagator().run(
        mode: ChangelogMode.fullCopy,
        confirm: (_) => true,
      );

      expect(result.overwritten, hasLength(2));
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        _rootChangelog,
      );
      expect(
        File(p.join(repo, 'packages', 'ispectify', 'CHANGELOG.md'))
            .readAsStringSync(),
        _rootChangelog,
      );
    });

    test('writes nothing when the operator declines', () {
      final before = File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
          .readAsStringSync();

      final result = propagator().run(
        mode: ChangelogMode.fullCopy,
        confirm: (_) => false,
      );

      expect(result.aborted, isTrue);
      expect(result.overwritten, isEmpty);
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        before,
      );
    });

    test('declines by default when no confirmation is supplied', () {
      final result = propagator().run(mode: ChangelogMode.fullCopy);

      expect(result.aborted, isTrue);
    });

    test('still creates nothing for a package without a changelog', () {
      propagator().run(mode: ChangelogMode.fullCopy, confirm: (_) => true);

      expect(
        File(p.join(repo, 'packages', 'ispect_layout', 'CHANGELOG.md'))
            .existsSync(),
        isFalse,
      );
    });
  });

  group('the command entrypoint', () {
    test('propagates the latest section by default', () {
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        contains('## 2.0.0'),
      );
    });

    test('overwrites without prompting when told yes', () {
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--full-copy', '--yes'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        _rootChangelog,
      );
    });

    test('a full copy without a confirmation writes nothing', () {
      final before = File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
          .readAsStringSync();

      final out = StringBuffer();
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--full-copy'],
        out: out,
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('Aborted'));
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        before,
      );
    });

    test('a requested version selects that section', () {
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--version', '1.8.0'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        contains('- Oldest line.'),
      );
    });

    test('a version flag without a value falls back to the newest section', () {
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--version'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        contains('## 2.0.0'),
      );
    });

    test('an unknown version exits 1', () {
      final err = StringBuffer();
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--version', '9.9.9'],
        out: StringBuffer(),
        err: err,
      );

      expect(exitCode, 1);
      expect(err.toString(), contains('9.9.9 not found'));
    });

    test('a missing root changelog exits 1', () {
      File(p.join(repo, 'CHANGELOG.md')).deleteSync();

      final err = StringBuffer();
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: err,
      );

      expect(exitCode, 1);
      expect(err.toString(), contains('Root CHANGELOG.md not found'));
    });

    test('an unknown argument exits 2', () {
      final err = StringBuffer();
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--nope'],
        out: StringBuffer(),
        err: err,
      );

      expect(exitCode, 2);
      expect(err.toString(), contains('Unknown arg: --nope'));
    });

    test('help exits 0 without propagating', () {
      final before = File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
          .readAsStringSync();

      final out = StringBuffer();
      final exitCode = runChangelogPropagation(
        repoRoot: repo,
        arguments: const ['--help'],
        out: out,
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('--full-copy'));
      expect(
        File(p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'))
            .readAsStringSync(),
        before,
      );
    });
  });
}

void _writeFixture(String repo) {
  _write(p.join(repo, 'CHANGELOG.md'), _rootChangelog);
  _write(
    p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'),
    '# Ispect changelog\n\n## 1.9.0\n\n- Older line.\n',
  );
  _write(
    p.join(repo, 'packages', 'ispectify', 'CHANGELOG.md'),
    '# Ispectify changelog\n\n## 2.0.0\n\n- Already present.\n',
  );
  Directory(p.join(repo, 'packages', 'ispect_layout'))
      .createSync(recursive: true);
}

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
