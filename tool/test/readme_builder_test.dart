@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/readme_builder.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null) {
    throw StateError('readme tests must run inside the repository');
  }

  group('rendering the repository', () {
    final builder = ReadmeBuilder(
      repoRoot: repoRoot,
      out: StringBuffer(),
      err: StringBuffer(),
    );

    for (final target in readmeTargets) {
      test('reproduces the committed ${target.outputPath} byte for byte', () {
        final committed = File(p.join(repoRoot, target.outputPath));
        expect(
          committed.existsSync(),
          isTrue,
          reason: '${target.outputPath} is the oracle; it must exist',
        );

        final rendered = builder.render(target, builder.readVersion());

        expect(
          utf8.encode(rendered),
          utf8.encode(committed.readAsStringSync()),
          reason: 'the render of docs/readme/${target.sourceName}.md drifted '
              'from the committed ${target.outputPath}',
        );
      });
    }

    test('reports every committed README as up to date', () {
      final out = StringBuffer();
      final exitCode = runReadmeBuild(
        repoRoot: repoRoot,
        arguments: const ['--check'],
        out: out,
        err: StringBuffer(),
      );

      expect(exitCode, 0, reason: out.toString());
      expect(out.toString(), contains('All generated READMEs are up to date.'));
    });
  });

  group('on a fixture repository', () {
    late Directory workspace;
    late String repo;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('ispect-readme-');
      repo = p.join(workspace.path, 'repo');
      _writeFixture(repo);
    });

    tearDown(() {
      if (workspace.existsSync()) {
        workspace.deleteSync(recursive: true);
      }
    });

    ReadmeBuilder builderFor(StringBuffer out) => ReadmeBuilder(
          repoRoot: repo,
          out: out,
          err: StringBuffer(),
        );

    test('expands a partial in place of its marker', () {
      final rendered = builderFor(StringBuffer())
          .render(_fixtureTarget, builderFor(StringBuffer()).readVersion());

      expect(rendered, contains('shared fragment body'));
      expect(rendered, isNot(contains('<!-- partial:shared -->')));
    });

    test('expands a partial nested inside another partial', () {
      _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
top
<!-- partial:outer -->
bottom
''');
      _write(p.join(repo, 'docs', 'readme', '_partials', 'outer.md'), '''
outer opens
<!-- partial:shared -->
outer closes
''');

      final rendered =
          builderFor(StringBuffer()).render(_fixtureTarget, '9.9.9');

      expect(
        rendered,
        stringContainsInOrder([
          'top',
          'outer opens',
          'shared fragment body',
          'outer closes',
          'bottom',
        ]),
      );
    });

    test('separates a partial from following text with one blank line', () {
      _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
<!-- partial:shared -->
after
''');

      final rendered =
          builderFor(StringBuffer()).render(_fixtureTarget, '9.9.9');

      expect(rendered, contains('shared fragment body\n\nafter\n'));
    });

    test('does not add a blank line the source already provides', () {
      _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
<!-- partial:shared -->

after
''');

      final rendered =
          builderFor(StringBuffer()).render(_fixtureTarget, '9.9.9');

      expect(rendered, contains('shared fragment body\n\nafter\n'));
      expect(rendered, isNot(contains('shared fragment body\n\n\nafter')));
    });

    test('substitutes the version and package placeholders', () {
      _write(
        p.join(repo, 'docs', 'readme', 'root.md'),
        'install {{package}} at {{version}}\n',
      );

      final rendered =
          builderFor(StringBuffer()).render(_fixtureTarget, '4.5.6');

      expect(rendered, contains('install ispect at 4.5.6'));
    });

    test('opens every README with the generated-file banner', () {
      final rendered =
          builderFor(StringBuffer()).render(_fixtureTarget, '1.0.0');

      expect(rendered, startsWith('<!--\n  GENERATED FILE'));
      expect(rendered, contains('  Source:     docs/readme/root.md\n'));
      expect(rendered, endsWith('\n'));
    });

    test('ends the file with exactly one newline', () {
      _write(p.join(repo, 'docs', 'readme', 'root.md'), 'body\n\n\n\n');

      final rendered =
          builderFor(StringBuffer()).render(_fixtureTarget, '1.0.0');

      expect(rendered, endsWith('body\n'));
      expect(rendered, isNot(endsWith('body\n\n')));
    });

    test('reads the version from the first VERSION line', () {
      _write(
        p.join(repo, 'version.config'),
        '# comment\nVERSION=2.0.0-rc.3\nVERSION=ignored\n',
      );

      expect(builderFor(StringBuffer()).readVersion(), '2.0.0-rc.3');
    });

    test('writing produces a file a later check accepts', () {
      final built = runReadmeBuild(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: StringBuffer(),
      );
      final checked = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--check'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(built, 0);
      expect(checked, 0);
    });

    test('check reports drift and writes nothing when the file is stale', () {
      runReadmeBuild(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: StringBuffer(),
      );
      final readme = File(p.join(repo, 'README.md'));
      readme.writeAsStringSync(
        readme.readAsStringSync().replaceAll('shared fragment body', 'edited'),
      );
      final stale = readme.readAsStringSync();

      final out = StringBuffer();
      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--check'],
        out: out,
        err: StringBuffer(),
      );

      expect(exitCode, 1);
      expect(out.toString(), contains('drift detected'));
      expect(out.toString(), contains('README drift detected in 1 target(s)'));
      expect(readme.readAsStringSync(), stale);
    });

    test('check reports a README that was never generated as missing', () {
      final out = StringBuffer();
      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--check'],
        out: out,
        err: StringBuffer(),
      );

      expect(exitCode, 1);
      expect(out.toString(), contains('— missing'));
    });

    test('a drifting first content line is caught despite the banner strip',
        () {
      runReadmeBuild(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: StringBuffer(),
      );
      final readme = File(p.join(repo, 'README.md'));
      final lines = readme.readAsStringSync().split('\n');
      lines[6] = 'tampered first content line';
      readme.writeAsStringSync(lines.join('\n'));

      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--check'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 1);
    });

    test('dry run writes no file', () {
      final out = StringBuffer();
      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--dry-run'],
        out: out,
        err: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(out.toString(), contains('would write'));
      expect(File(p.join(repo, 'README.md')).existsSync(), isFalse);
    });

    test('a package filter restricts the run to one target', () {
      _write(p.join(repo, 'docs', 'readme', 'ispectify.md'), 'ispectify\n');

      final result = builderFor(StringBuffer()).run(
        mode: ReadmeMode.build,
        packageFilter: 'ispectify',
      );

      expect(result.matched, 1);
      expect(result.written, ['packages/ispectify/README.md']);
      expect(File(p.join(repo, 'README.md')).existsSync(), isFalse);
    });

    test('a filter matching no target is rejected', () {
      expect(
        () => builderFor(StringBuffer())
            .run(mode: ReadmeMode.build, packageFilter: 'nope'),
        throwsA(isA<DocsSourceException>()),
      );
    });

    test('an unknown partial is rejected instead of silently truncating', () {
      _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
<!-- partial:missing_fragment -->
body that must not be lost
''');

      expect(
        () => builderFor(StringBuffer()).render(_fixtureTarget, '1.0.0'),
        throwsA(
          isA<PartialResolutionException>().having(
            (e) => e.partialName,
            'partialName',
            'missing_fragment',
          ),
        ),
      );
    });

    test('an unknown partial leaves the previous README untouched', () {
      runReadmeBuild(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: StringBuffer(),
      );
      final readme = File(p.join(repo, 'README.md'));
      final before = readme.readAsBytesSync();

      _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
<!-- partial:missing_fragment -->
body that must not be lost
''');

      final err = StringBuffer();
      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: err,
      );

      expect(exitCode, isNot(0));
      expect(err.toString(), contains('unknown partial'));
      expect(readme.readAsBytesSync(), before);
    });

    test('a partial cycle is rejected rather than recursing forever', () {
      _write(
        p.join(repo, 'docs', 'readme', 'root.md'),
        '<!-- partial:loop -->\n',
      );
      _write(
        p.join(repo, 'docs', 'readme', '_partials', 'loop.md'),
        '<!-- partial:loop -->\n',
      );

      expect(
        () => builderFor(StringBuffer()).render(_fixtureTarget, '1.0.0'),
        throwsA(isA<PartialResolutionException>()),
      );
    });

    test('a missing source template is rejected', () {
      File(p.join(repo, 'docs', 'readme', 'root.md')).deleteSync();

      expect(
        () => builderFor(StringBuffer()).render(_fixtureTarget, '1.0.0'),
        throwsA(isA<DocsSourceException>()),
      );
    });

    test('a missing source directory is rejected', () {
      Directory(p.join(repo, 'docs', 'readme')).deleteSync(recursive: true);

      expect(
        () => builderFor(StringBuffer()).run(mode: ReadmeMode.build),
        throwsA(isA<DocsSourceException>()),
      );
    });

    test('a missing version.config is rejected', () {
      File(p.join(repo, 'version.config')).deleteSync();

      expect(
        () => builderFor(StringBuffer()).readVersion(),
        throwsA(isA<VersionConfigException>()),
      );
    });

    test('a version.config without a VERSION value is rejected', () {
      _write(p.join(repo, 'version.config'), 'VERSION=\n');

      expect(
        () => builderFor(StringBuffer()).readVersion(),
        throwsA(isA<VersionConfigException>()),
      );
    });

    test('a configuration failure exits 2', () {
      File(p.join(repo, 'version.config')).deleteSync();

      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const [],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 2);
    });

    test('an unknown option exits 2', () {
      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--nope'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 2);
    });

    test('a package flag without a name exits 2', () {
      final exitCode = runReadmeBuild(
        repoRoot: repo,
        arguments: const ['--package'],
        out: StringBuffer(),
        err: StringBuffer(),
      );

      expect(exitCode, 2);
    });
  });

  group('banner stripping', () {
    test('drops the banner and the blank line after it', () {
      const contents = '<!--\n'
          '  GENERATED FILE — do not edit by hand.\n'
          '  Source:     docs/readme/root.md\n'
          '  Regenerate: ./bash/build_readme.sh\n'
          '-->\n'
          '\n'
          'first content line\n';

      expect(stripReadmeBanner(contents), 'first content line\n');
    });

    test('leaves a file without a banner untouched', () {
      const contents = 'no banner here\n';

      expect(stripReadmeBanner(contents), contents);
    });
  });
}

const ReadmeTarget _fixtureTarget = ReadmeTarget(
  sourceName: 'root',
  outputPath: 'README.md',
  packageName: 'ispect',
);

void _writeFixture(String repo) {
  _write(p.join(repo, 'version.config'), 'VERSION=1.2.3\n');
  _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
intro line
<!-- partial:shared -->
outro line
''');
  _write(p.join(repo, 'docs', 'readme', '_partials', 'shared.md'), '''
shared fragment body
''');

  for (final target in readmeTargets) {
    if (target.sourceName == 'root') {
      continue;
    }
    _write(
      p.join(repo, 'docs', 'readme', '${target.sourceName}.md'),
      '${target.sourceName} body for {{package}} at {{version}}\n',
    );
    Directory(p.join(repo, p.dirname(target.outputPath)))
        .createSync(recursive: true);
  }
}

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
