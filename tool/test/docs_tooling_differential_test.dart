@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/changelog.dart';
import 'package:ispect_tool/src/core/llms_builder.dart';
import 'package:ispect_tool/src/core/readme_builder.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs each documentation script and its Dart replacement over identical
/// copies of one fixture repository and requires the resulting trees to be
/// byte-identical.
///
/// Delete this file together with `bash/build_readme.sh`,
/// `bash/build_llms.sh`, and `bash/update_changelog.sh`.
void main() {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null) {
    throw StateError('differential test must run inside the repository');
  }

  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-docs-diff-');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  /// Copies the fixture twice, runs bash in one copy and [dart] in the other,
  /// and returns the two exit codes after asserting the trees agree.
  ({int bash, int dart}) compare({
    required String scenario,
    required String script,
    required List<String> arguments,
    required void Function(String repo) build,
    required int Function(String repo) dart,
    bool comparesTrees = true,
  }) {
    final source = p.join(workspace.path, scenario, 'source');
    build(source);
    _write(
      p.join(source, 'bash', script),
      File(p.join(repoRoot, 'bash', script)).readAsStringSync(),
    );

    final bashRepo = p.join(workspace.path, scenario, 'bash');
    final dartRepo = p.join(workspace.path, scenario, 'dart');
    _copyTree(source, bashRepo);
    _copyTree(source, dartRepo);

    final bashRun = Process.runSync(
      'bash',
      [p.join(bashRepo, 'bash', script), ...arguments],
      workingDirectory: bashRepo,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    final dartExitCode = dart(dartRepo);

    if (comparesTrees) {
      _expectIdenticalTrees(bashRepo, dartRepo);
    }
    return (bash: bashRun.exitCode, dart: dartExitCode);
  }

  group('build_readme.sh', () {
    int runDart(String repo, List<String> arguments) => runReadmeBuild(
          repoRoot: repo,
          arguments: arguments,
          out: StringBuffer(),
          err: StringBuffer(),
        );

    test('a full build lands byte-identically', () {
      final codes = compare(
        scenario: 'readme-build',
        script: 'build_readme.sh',
        arguments: const [],
        build: _readmeFixture,
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a check of an up-to-date tree agrees', () {
      final codes = compare(
        scenario: 'readme-check-clean',
        script: 'build_readme.sh',
        arguments: const ['--check'],
        build: (repo) {
          _readmeFixture(repo);
          _prebuildReadmes(repo);
        },
        dart: (repo) => runDart(repo, const ['--check']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a check of a stale tree agrees on drift and writes nothing', () {
      final codes = compare(
        scenario: 'readme-check-stale',
        script: 'build_readme.sh',
        arguments: const ['--check'],
        build: (repo) {
          _readmeFixture(repo);
          _prebuildReadmes(repo);
          _write(p.join(repo, 'README.md'), 'stale\n');
        },
        dart: (repo) => runDart(repo, const ['--check']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 1);
    });

    test('a dry run writes nothing on either side', () {
      final codes = compare(
        scenario: 'readme-dry-run',
        script: 'build_readme.sh',
        arguments: const ['--dry-run'],
        build: _readmeFixture,
        dart: (repo) => runDart(repo, const ['--dry-run']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a single-package build lands byte-identically', () {
      final codes = compare(
        scenario: 'readme-package',
        script: 'build_readme.sh',
        arguments: const ['--package', 'ispectify'],
        build: _readmeFixture,
        dart: (repo) => runDart(repo, const ['--package', 'ispectify']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('an unknown option is rejected the same way', () {
      final codes = compare(
        scenario: 'readme-unknown-option',
        script: 'build_readme.sh',
        arguments: const ['--nope'],
        build: _readmeFixture,
        dart: (repo) => runDart(repo, const ['--nope']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 2);
    });

    test('a missing version.config is rejected the same way', () {
      final codes = compare(
        scenario: 'readme-no-version',
        script: 'build_readme.sh',
        arguments: const [],
        build: (repo) {
          _readmeFixture(repo);
          File(p.join(repo, 'version.config')).deleteSync();
        },
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 2);
    });

    test(
        'an unknown partial aborts the port while bash exits 0 and truncates '
        'the README', () {
      final codes = compare(
        scenario: 'readme-unknown-partial',
        script: 'build_readme.sh',
        arguments: const [],
        build: (repo) {
          _readmeFixture(repo);
          _prebuildReadmes(repo);
          _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
<!-- partial:does_not_exist -->
body that must survive
''');
        },
        dart: (repo) => runDart(repo, const []),
        comparesTrees: false,
      );

      expect(codes.bash, 0, reason: 'the bash defect being replaced');
      expect(codes.dart, isNot(0), reason: 'the port must refuse to write');
    });

    test('an unknown partial leaves the port README untouched', () {
      final repo = p.join(workspace.path, 'readme-no-write', 'repo');
      _readmeFixture(repo);
      _prebuildReadmes(repo);
      final before = File(p.join(repo, 'README.md')).readAsBytesSync();
      _write(
        p.join(repo, 'docs', 'readme', 'root.md'),
        '<!-- partial:does_not_exist -->\nbody\n',
      );

      final exitCode = runDart(repo, const []);

      expect(exitCode, isNot(0));
      expect(File(p.join(repo, 'README.md')).readAsBytesSync(), before);
    });
  });

  group('build_llms.sh', () {
    int runDart(String repo, List<String> arguments) => runLlmsBuild(
          repoRoot: repo,
          arguments: arguments,
          out: StringBuffer(),
          err: StringBuffer(),
        );

    test('a generated index lands byte-identically', () {
      final codes = compare(
        scenario: 'llms-write',
        script: 'build_llms.sh',
        arguments: const [],
        build: _llmsFixture,
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a check of an up-to-date index agrees', () {
      final codes = compare(
        scenario: 'llms-check-clean',
        script: 'build_llms.sh',
        arguments: const ['--check'],
        build: (repo) {
          _llmsFixture(repo);
          _write(
            p.join(repo, 'llms.txt'),
            LlmsBuilder(
              repoRoot: repo,
              out: StringBuffer(),
              err: StringBuffer(),
            ).render(),
          );
        },
        dart: (repo) => runDart(repo, const ['--check']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a check of a stale index agrees on drift and writes nothing', () {
      final codes = compare(
        scenario: 'llms-check-stale',
        script: 'build_llms.sh',
        arguments: const ['--check'],
        build: (repo) {
          _llmsFixture(repo);
          _write(p.join(repo, 'llms.txt'), 'stale\n');
        },
        dart: (repo) => runDart(repo, const ['--check']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 1);
    });

    test('an unknown option is rejected the same way', () {
      final codes = compare(
        scenario: 'llms-unknown-option',
        script: 'build_llms.sh',
        arguments: const ['--nope'],
        build: _llmsFixture,
        dart: (repo) => runDart(repo, const ['--nope']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 2);
    });

    test('a missing version.config is rejected the same way', () {
      final codes = compare(
        scenario: 'llms-no-version',
        script: 'build_llms.sh',
        arguments: const [],
        build: (repo) {
          _llmsFixture(repo);
          File(p.join(repo, 'version.config')).deleteSync();
        },
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 2);
    });
  });

  group('update_changelog.sh', () {
    int runDart(String repo, List<String> arguments) => runChangelogPropagation(
          repoRoot: repo,
          arguments: arguments,
          out: StringBuffer(),
          err: StringBuffer(),
        );

    test('appending the newest section lands byte-identically', () {
      final codes = compare(
        scenario: 'changelog-append',
        script: 'update_changelog.sh',
        arguments: const [],
        build: _changelogFixture,
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('appending an explicit version lands byte-identically', () {
      final codes = compare(
        scenario: 'changelog-version',
        script: 'update_changelog.sh',
        arguments: const ['--version', '1.8.0'],
        build: _changelogFixture,
        dart: (repo) => runDart(repo, const ['--version', '1.8.0']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a full copy lands byte-identically', () {
      final codes = compare(
        scenario: 'changelog-full-copy',
        script: 'update_changelog.sh',
        arguments: const ['--full-copy', '--yes'],
        build: _changelogFixture,
        dart: (repo) => runDart(repo, const ['--full-copy', '--yes']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('a second run appends nothing on either side', () {
      final codes = compare(
        scenario: 'changelog-idempotent',
        script: 'update_changelog.sh',
        arguments: const [],
        build: (repo) {
          _changelogFixture(repo);
          runChangelogPropagation(
            repoRoot: repo,
            arguments: const [],
            out: StringBuffer(),
            err: StringBuffer(),
          );
        },
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 0);
    });

    test('an unknown version is rejected the same way', () {
      final codes = compare(
        scenario: 'changelog-unknown-version',
        script: 'update_changelog.sh',
        arguments: const ['--version', '9.9.9'],
        build: _changelogFixture,
        dart: (repo) => runDart(repo, const ['--version', '9.9.9']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 1);
    });

    test('an unknown argument is rejected the same way', () {
      final codes = compare(
        scenario: 'changelog-unknown-arg',
        script: 'update_changelog.sh',
        arguments: const ['--nope'],
        build: _changelogFixture,
        dart: (repo) => runDart(repo, const ['--nope']),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 2);
    });

    test('a missing root changelog is rejected the same way', () {
      final codes = compare(
        scenario: 'changelog-missing-root',
        script: 'update_changelog.sh',
        arguments: const [],
        build: (repo) {
          _changelogFixture(repo);
          File(p.join(repo, 'CHANGELOG.md')).deleteSync();
        },
        dart: (repo) => runDart(repo, const []),
      );

      expect(codes.dart, codes.bash);
      expect(codes.bash, 1);
    });
  });
}

void _readmeFixture(String repo) {
  _write(p.join(repo, 'version.config'), 'VERSION=1.2.3\n');
  _write(p.join(repo, 'docs', 'readme', 'root.md'), '''
intro line
<!-- partial:shared -->
outro for {{package}} at {{version}}
''');
  _write(p.join(repo, 'docs', 'readme', '_partials', 'shared.md'), '''
shared fragment body
<!-- partial:nested -->
shared tail
''');
  _write(p.join(repo, 'docs', 'readme', '_partials', 'nested.md'), '''
nested fragment
''');

  for (final target in readmeTargets) {
    if (target.sourceName == 'root') {
      continue;
    }
    _write(p.join(repo, 'docs', 'readme', '${target.sourceName}.md'), '''
<!-- partial:shared -->

${target.sourceName} body for {{package}} at {{version}}
''');
    Directory(p.join(repo, p.dirname(target.outputPath)))
        .createSync(recursive: true);
  }
}

void _prebuildReadmes(String repo) {
  runReadmeBuild(
    repoRoot: repo,
    arguments: const [],
    out: StringBuffer(),
    err: StringBuffer(),
  );
}

void _llmsFixture(String repo) {
  _write(p.join(repo, 'version.config'), 'VERSION=1.2.3\nCHANNEL=dev\n');
  _write(p.join(repo, 'packages', 'ispect', 'pubspec.yaml'), '''
name: ispect
description: Flutter diagnostics shell.
repository: https://github.com/yelmuratoff/ispect
''');
  _write(
    p.join(repo, 'packages', 'ispect', 'example', 'lib', 'main.dart'),
    'void main() {}\n',
  );
  _write(p.join(repo, 'packages', 'ispectify', 'pubspec.yaml'), '''
name: ispectify
description: Logging core.
''');
  _write(
    p.join(repo, 'packages', 'ispectify', 'example', 'lib', 'demo.dart'),
    'void main() {}\n',
  );
  _write(
    p.join(
      repo,
      'packages',
      'ispectify_db',
      'example',
      'lib',
      'interceptors',
      'hive_interceptor.dart',
    ),
    'class HiveInterceptor {}\n',
  );
  _write(p.join(repo, 'packages', 'ispectify_db', 'pubspec.yaml'), '''
name: ispectify_db
description: Database tracing.
''');
  _write(p.join(repo, 'docs', 'SECURITY.md'), '# Security Policy\n\nBody.\n');
  _write(p.join(repo, 'docs', 'USAGE.md'), '# Usage\n\nBody.\n');
  _write(p.join(repo, 'docs', 'prompt.md'), '# Prompt\n\nBody.\n');
}

void _changelogFixture(String repo) {
  _write(p.join(repo, 'CHANGELOG.md'), '''
# Changelog

## 2.0.0

- Second major line.
- Another entry.

## 1.9.0

- Older line.

## 1.8.0

- Oldest line.
''');
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

void _copyTree(String from, String to) {
  Directory(to).createSync(recursive: true);
  for (final entity in Directory(from).listSync(recursive: true)) {
    final target = p.join(to, p.relative(entity.path, from: from));
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      Directory(p.dirname(target)).createSync(recursive: true);
      entity.copySync(target);
    }
  }
}

Map<String, List<int>> _snapshot(String root) => {
      for (final file
          in Directory(root).listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: root): file.readAsBytesSync(),
    };

void _expectIdenticalTrees(String expected, String actual) {
  final expectedFiles = _snapshot(expected);
  final actualFiles = _snapshot(actual);

  expect(
    actualFiles.keys.toSet(),
    expectedFiles.keys.toSet(),
    reason: 'the two trees hold different files',
  );

  final differing = [
    for (final entry in expectedFiles.entries)
      if (!_sameBytes(entry.value, actualFiles[entry.key]))
        '--- ${entry.key} ---\n'
            'bash:\n${utf8.decode(entry.value)}\n'
            'dart:\n${utf8.decode(actualFiles[entry.key] ?? const [])}',
  ];
  expect(differing, isEmpty, reason: differing.join('\n'));
}

bool _sameBytes(List<int> left, List<int>? right) {
  if (right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
