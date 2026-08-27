@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/publish.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'publish_fixture.dart';

/// Runs `bash/publish.sh` and [runPublish] over identical copies of one fixture
/// repository and requires them to agree on the exit code and on every line
/// they report.
///
/// Only the preflight phase is compared. Everything past `dart format` reaches
/// `dart pub publish`, which is irreversible, so both sides run with a `dart`
/// on PATH that refuses to do anything and every scenario is chosen to stop
/// before the formatter. The test asserts afterwards that neither side reached
/// it.
///
/// Delete this file together with `bash/publish.sh`.
void main() {
  final sourceRepo = findRepoRoot(Directory.current.path);
  if (sourceRepo == null) {
    throw StateError('differential test must run inside the repository');
  }
  final script = File(p.join(sourceRepo, 'bash', 'publish.sh'));

  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-publish-diff-');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  /// Builds the fixture twice, runs both implementations, and asserts they
  /// agree. [customize] runs against each copy before it is committed;
  /// [dirty] runs after, so a scenario can leave the tree unclean.
  Future<void> expectAgreement(
    String scenario,
    List<String> arguments, {
    String version = '7.0.0-dev.1',
    String constraint = '^1.0.0',
    Map<String, String> packageVersions = const {},
    Map<String, List<String>> hostVersions = const {},
    void Function(String repo)? customize,
    void Function(String repo)? dirty,
  }) async {
    if (!script.existsSync()) {
      markTestSkipped('bash/publish.sh is gone; parity no longer applies');
      return;
    }

    final root = p.join(workspace.path, scenario);
    final repos = <String, String>{
      'bash': p.join(root, 'bash-side'),
      'dart': p.join(root, 'dart-side'),
    };
    for (final repo in repos.values) {
      createPublishFixture(
        destination: repo,
        version: version,
        constraint: constraint,
        packageVersions: packageVersions,
      );
      copyPublishScripts(sourceRepo: sourceRepo, destination: repo);
      customize?.call(repo);
      commitFixture(repo);
      dirty?.call(repo);
    }

    final host = _writeHostDocuments(p.join(root, 'host'), hostVersions);
    final marker = p.join(root, 'dart-was-invoked');
    final stubs =
        _writeStubs(p.join(root, 'stubs'), host: host, marker: marker);
    final temp = Directory(p.join(root, 'tmp'))..createSync(recursive: true);

    final bashRun = Process.runSync(
      'bash',
      [
        '-c',
        'exec "\$@" 2>&1',
        'bash',
        p.join(repos['bash']!, 'bash', 'publish.sh'),
        ...arguments
      ],
      workingDirectory: repos['bash'],
      environment: {
        'PATH': '$stubs:${Platform.environment['PATH']}',
        'TMPDIR': temp.path,
        ..._gitEnvironment,
      },
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    final dartLog = StringBuffer();
    final dartExitCode = await runPublish(
      repoRoot: repos['dart']!,
      arguments: arguments,
      out: dartLog,
      err: dartLog,
      runner: const _GitOnlyRunner(),
      publishedVersions: (package) async => _readHostVersions(host, package),
      confirmation: const _NeverAsked(),
      environment: const {},
    );

    final bashLines = _normalize(bashRun.stdout as String, repos['bash']!);
    final dartLines = _normalize(dartLog.toString(), repos['dart']!);

    expect(
      dartLines,
      bashLines,
      reason: 'reported findings differ\n'
          'bash:\n${bashLines.join("\n")}\n\ndart:\n${dartLines.join("\n")}',
    );
    expect(
      dartExitCode,
      bashRun.exitCode,
      reason: 'exit codes differ\nbash:\n${bashRun.stdout}\ndart:\n$dartLog',
    );
    expect(
      File(marker).existsSync(),
      isFalse,
      reason: 'the bash side reached dart; no differential scenario may',
    );
  }

  test('a package version that disagrees is refused identically', () async {
    await expectAgreement(
      'version-mismatch',
      const ['--dry-run', '--skip-pub-version-check'],
      packageVersions: const {
        'ispect_layout': '6.9.0',
        'ispectify': '1.2.3',
        'ispectify_bloc': '0.1.0',
        'ispect': '2.0.0',
      },
    );
  });

  test('an unparsable VERSION is refused identically', () async {
    await expectAgreement(
      'invalid-version',
      const ['--dry-run', '--skip-pub-version-check'],
      customize: (repo) => writeFixtureFile(
        p.join(repo, 'version.config'),
        'VERSION=not-a-version\n',
      ),
    );
  });

  test('an untracked file is refused identically', () async {
    await expectAgreement(
      'dirty-tree',
      const ['--dry-run', '--skip-pub-version-check'],
      dirty: (repo) =>
          writeFixtureFile(p.join(repo, 'scratch.txt'), 'uncommitted\n'),
    );
  });

  test('an untracked directory is reported file by file identically', () async {
    await expectAgreement(
      'untracked-directory',
      const ['--dry-run', '--skip-pub-version-check'],
      dirty: (repo) => writeFixtureFile(
        p.join(repo, 'notes', 'draft.md'),
        'uncommitted\n',
      ),
    );
  });

  test('a modified tracked file is refused identically', () async {
    await expectAgreement(
      'modified-tree',
      const ['--dry-run', '--skip-pub-version-check'],
      dirty: (repo) => writeFixtureFile(
        p.join(repo, 'packages', 'ispect', 'CHANGELOG.md'),
        '# Changelog\n\nedited after the commit\n',
      ),
    );
  });

  test('an unconstrained dependency is refused identically', () async {
    await expectAgreement(
      'any-constraint',
      const ['--dry-run', '--skip-pub-version-check'],
      constraint: 'any',
    );
  });

  test('a version below the published peak is refused identically', () async {
    await expectAgreement(
      'blocked-gate',
      const ['--dry-run'],
      hostVersions: const {
        'ispectify': ['7.0.0-dev.0', '6.9.0'],
        'ispectify_ws': ['7.0.0-dev.2'],
        'ispect': ['6.9.0'],
      },
    );
  });

  test('an unknown option is refused identically', () async {
    await expectAgreement('unknown-option', const ['--nope']);
  });
}

const Map<String, String> _gitEnvironment = {
  'GIT_CONFIG_GLOBAL': '/dev/null',
  'GIT_CONFIG_SYSTEM': '/dev/null',
};

/// A runner that reaches `git` and refuses everything else.
///
/// `dart pub publish` is irreversible, so the differential test can never be
/// allowed to reach it even by accident.
final class _GitOnlyRunner implements ProcessRunner {
  const _GitOnlyRunner();

  @override
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) {
    if (executable != 'git') {
      throw StateError(
        'the differential test must never run $executable ${arguments.join(" ")}',
      );
    }
    final result = Process.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: _gitEnvironment,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return CommandResult(
      exitCode: result.exitCode,
      output: '${result.stdout}${result.stderr}',
    );
  }
}

final class _NeverAsked implements PublishConfirmation {
  const _NeverAsked();

  @override
  bool shouldPublish(String package) =>
      throw StateError('no differential scenario may reach the prompt');
}

/// Writes one `/api/packages/<name>` document per entry, the single source both
/// sides read their published history from.
String _writeHostDocuments(String directory, Map<String, List<String>> hosted) {
  Directory(directory).createSync(recursive: true);
  for (final entry in hosted.entries) {
    writeFixtureFile(
      p.join(directory, '${entry.key}.json'),
      jsonEncode({
        'name': entry.key,
        'versions': [
          for (final version in entry.value) {'version': version},
        ],
      }),
    );
  }
  return directory;
}

List<Version> _readHostVersions(String directory, String package) {
  final file = File(p.join(directory, '$package.json'));
  if (!file.existsSync()) {
    return const [];
  }
  final document = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return [
    for (final entry in document['versions']! as List<Object?>)
      Version.parse((entry! as Map<String, Object?>)['version']! as String),
  ];
}

/// Writes a `curl` that serves [host] and a `dart` that records being called
/// and refuses, then returns the directory to prepend to PATH.
String _writeStubs(String directory,
    {required String host, required String marker}) {
  writeFixtureFile(p.join(directory, 'curl'), '''
#!/usr/bin/env bash

set -euo pipefail

output=""
url=""
previous=""
for argument in "\$@"; do
  [[ \$previous == --output ]] && output="\$argument"
  [[ \$argument == http* ]] && url="\$argument"
  previous="\$argument"
done

document="$host/\${url##*/}.json"
if [[ -f \$document ]]; then
  cat "\$document" > "\$output"
  printf '200'
else
  printf '404'
fi
''');
  writeFixtureFile(p.join(directory, 'dart'), '''
#!/usr/bin/env bash

printf '%s\\n' "\$*" >> "$marker"
echo "the differential test must never run dart \$*" >&2
exit 99
''');
  makeExecutable(p.join(directory, 'curl'));
  makeExecutable(p.join(directory, 'dart'));
  return directory;
}

final RegExp _ansi = RegExp(r'\x1B\[[0-9;]*m');

List<String> _normalize(String output, String repo) => [
      for (final line in const LineSplitter()
          .convert(output.replaceAll(_ansi, '').replaceAll(repo, '<repo>')))
        line,
    ];
