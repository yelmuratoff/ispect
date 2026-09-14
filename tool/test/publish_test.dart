@TestOn('vm')
library;

import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/publish.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'publish_fixture.dart';

const CommandResult _ok = CommandResult(exitCode: 0, output: '');

/// A [ProcessRunner] that spawns nothing.
///
/// Every test injects one of these, so no suite can reach `dart pub publish`,
/// `git`, or any other executable.
final class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner({
    this.statusLines = const [],
    this.statusLinesAfterFormat,
    this.statusExitCode = 0,
    this.podfileLocks = const {},
    this.formatResult = _ok,
    this.pubGetResults = const {},
    this.dryRunResults = const {},
    this.publishResults = const {},
  });

  final List<String> statusLines;
  final List<String>? statusLinesAfterFormat;
  final int statusExitCode;
  final Map<String, List<String>> podfileLocks;
  final CommandResult formatResult;
  final Map<String, CommandResult> pubGetResults;
  final Map<String, CommandResult> dryRunResults;
  final Map<String, CommandResult> publishResults;

  final List<String> commands = [];
  var statusCalls = 0;
  var formatted = false;

  /// Working-directory basenames of every `dart pub get`, in call order.
  List<String> get pubGetOrder => [
        for (final command in commands)
          if (command.startsWith('dart pub get ')) _packageOf(command),
      ];

  List<String> get publishedPackages => [
        for (final command in commands)
          if (command.startsWith('dart pub publish --force '))
            _packageOf(command),
      ];

  @override
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) {
    final package = p.basename(workingDirectory);
    commands.add('$executable ${arguments.join(" ")} [$package]');

    if (executable == 'git' && arguments.first == 'status') {
      statusCalls++;
      if (statusExitCode != 0) {
        return CommandResult(
          exitCode: statusExitCode,
          output: 'fatal: not a git repository\n',
        );
      }
      final lines =
          formatted ? (statusLinesAfterFormat ?? statusLines) : statusLines;
      return CommandResult(exitCode: 0, output: _joined(lines));
    }
    if (executable == 'git' && arguments.first == 'ls-files') {
      final owner = arguments.last.split('/')[1];
      return CommandResult(
        exitCode: 0,
        output: _joined(podfileLocks[owner] ?? const []),
      );
    }
    if (executable == 'dart' && arguments.first == 'format') {
      formatted = true;
      return formatResult;
    }
    if (executable == 'dart' && arguments.join(' ') == 'pub get --no-example') {
      return pubGetResults[package] ?? _ok;
    }
    if (executable == 'dart' && arguments.contains('--dry-run')) {
      return dryRunResults[package] ?? _ok;
    }
    if (executable == 'dart' && arguments.contains('--force')) {
      return publishResults[package] ?? _ok;
    }
    throw StateError('unexpected command: $executable ${arguments.join(" ")}');
  }

  static String _packageOf(String command) =>
      command.substring(command.indexOf('[') + 1, command.length - 1);

  static String _joined(List<String> lines) =>
      lines.map((line) => '$line\n').join();
}

final class FakeConfirmation implements PublishConfirmation {
  FakeConfirmation({this.answer = true, this.answers = const {}});

  final bool answer;
  final Map<String, bool> answers;
  final List<String> asked = [];

  @override
  bool shouldPublish(String package) {
    asked.add(package);
    return answers[package] ?? answer;
  }
}

final class _Outcome {
  const _Outcome(this.exitCode, this.out, this.err);

  final int exitCode;
  final String out;
  final String err;

  String get combined => '$out$err';

  List<String> get errorLines => [
        for (final line in err.split('\n'))
          if (line.startsWith('[ERR] ')) line,
      ];
}

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('ispect-publish-');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  String fixture({
    String version = '7.0.0-dev.1',
    String constraint = '^1.0.0',
    Map<String, String> packageVersions = const {},
  }) =>
      createPublishFixture(
        destination: p.join(workspace.path, 'repo'),
        version: version,
        constraint: constraint,
        packageVersions: packageVersions,
      );

  Future<_Outcome> invoke(
    String repo,
    List<String> arguments, {
    FakeProcessRunner? runner,
    PublishedVersionsReader? publishedVersions,
    PublishConfirmation? confirmation,
    Map<String, String> environment = const {},
  }) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runPublish(
      repoRoot: repo,
      arguments: arguments,
      out: out,
      err: err,
      runner: runner ?? FakeProcessRunner(),
      publishedVersions: publishedVersions ?? (_) async => const <Version>[],
      confirmation: confirmation ?? FakeConfirmation(answer: false),
      environment: environment,
    );
    return _Outcome(code, out.toString(), err.toString());
  }

  group('arguments', () {
    test('an unknown option is refused with the shell usage code', () async {
      final result = await invoke(fixture(), const ['--nope']);

      expect(result.exitCode, 2);
      expect(result.err, 'Unknown option: --nope\n');
    });

    test('--help prints the usage block without touching the repository',
        () async {
      final runner = FakeProcessRunner();
      final result = await invoke(fixture(), const ['--help'], runner: runner);

      expect(result.exitCode, 0);
      expect(result.out, contains('ispect_tool publish --dry-run'));
      expect(runner.commands, isEmpty);
    });

    test('--only without a package name is refused', () async {
      final result = await invoke(fixture(), const ['--only']);

      expect(result.exitCode, 2);
      expect(result.err, 'Missing package name after --only\n');
    });

    test('--only refuses a package the monorepo does not publish', () async {
      final result = await invoke(fixture(), const ['--only', 'ispect_ui']);

      expect(result.exitCode, 2);
      expect(result.err, 'Unknown package: ispect_ui\n');
    });
  });

  group('--only', () {
    test('limits the run to the named package', () async {
      final runner = FakeProcessRunner();

      final result = await invoke(
        fixture(),
        const ['--auto', '--only', 'ispectify_db', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.publishedPackages, const ['ispectify_db']);
    });

    test('keeps dependency order regardless of the order it is given',
        () async {
      final runner = FakeProcessRunner();

      final result = await invoke(
        fixture(),
        const [
          '--auto',
          '--only',
          'ispect',
          '--only',
          'ispectify',
          '--skip-pub-version-check',
        ],
        runner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.publishedPackages, const ['ispectify', 'ispect']);
    });

    test('a package left out is never asked about on the host', () async {
      final asked = <String>[];

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--only', 'ispectify_db'],
        publishedVersions: (package) async {
          asked.add(package);
          return const <Version>[];
        },
      );

      expect(result.exitCode, 0);
      expect(asked, const ['ispectify_db']);
    });
  });

  group('version preflight', () {
    test('a package whose version disagrees blocks the run', () async {
      final repo = fixture(packageVersions: const {'ispect_layout': '6.9.0'});
      final runner = FakeProcessRunner();

      final result = await invoke(
        repo,
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 1);
      expect(result.errorLines, [
        '[ERR] ispect_layout version 6.9.0 != 7.0.0-dev.1',
        '[ERR] Version mismatch. Run: ispect_tool sync',
      ]);
      expect(runner.commands, isEmpty);
    });

    test('every disagreeing package is named before the run stops', () async {
      final repo = fixture(
        packageVersions: const {'ispectify': '1.0.0', 'ispect': '2.0.0'},
      );

      final result = await invoke(
        repo,
        const ['--dry-run', '--skip-pub-version-check'],
      );

      expect(result.errorLines, [
        '[ERR] ispectify version 1.0.0 != 7.0.0-dev.1',
        '[ERR] ispect version 2.0.0 != 7.0.0-dev.1',
        '[ERR] Version mismatch. Run: ispect_tool sync',
      ]);
    });

    test('a missing pubspec stops the run at that package', () async {
      final repo = fixture();
      File(p.join(repo, 'packages', 'ispectify_dio', 'pubspec.yaml'))
          .deleteSync();

      final result = await invoke(
        repo,
        const ['--dry-run', '--skip-pub-version-check'],
      );

      expect(result.exitCode, 1);
      expect(result.errorLines, ['[ERR] Missing pubspec for ispectify_dio']);
    });

    test('a missing version.config stops the run before anything else',
        () async {
      final repo = fixture();
      File(p.join(repo, 'version.config')).deleteSync();

      final result = await invoke(repo, const ['--dry-run']);

      expect(result.exitCode, 1);
      expect(result.errorLines, ['[ERR] version.config not found']);
    });

    test('an unparsable VERSION stops the run before anything else', () async {
      final repo = fixture();
      writeFixtureFile(
        p.join(repo, 'version.config'),
        'VERSION=not-a-version\n',
      );

      final result = await invoke(repo, const ['--dry-run']);

      expect(result.exitCode, 1);
      expect(
        result.errorLines,
        ['[ERR] Invalid VERSION in version.config: not-a-version'],
      );
    });
  });

  group('published-version preflight', () {
    test('a version the resolver would not rank above the peak is refused',
        () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run'],
        publishedVersions: (package) async =>
            package == 'ispectify_ws' ? [Version.parse('7.0.0-dev.2')] : [],
      );

      expect(result.exitCode, 1);
      expect(result.errorLines, [
        '[ERR] ispectify_ws 7.0.0-dev.1 is not ranked above the published '
            '7.0.0-dev.2; consumers would keep resolving 7.0.0-dev.2',
        '[ERR] Published-version check failed. Pick a version the resolver '
            'orders above the peak of its release line.',
      ]);
    });

    test('an unpublished package, a fresh line, and a rise all pass', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run'],
        publishedVersions: (package) async => switch (package) {
          'ispectify' => const <Version>[],
          'ispect' => [Version.parse('6.9.0')],
          _ => [Version.parse('7.0.0-dev.0')],
        },
      );

      expect(result.exitCode, 0);
      expect(result.out, contains('[OK] ispectify has no published versions'));
      expect(result.out, contains('[OK] ispect opens the 7.0 line'));
      expect(
        result.out,
        contains('[OK] ispectify_ws 7.0.0-dev.1 is ranked above the published '
            '7.0.0-dev.0'),
      );
    });

    test('a host that leaves the question unanswered blocks the run', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run'],
        publishedVersions: (package) async {
          if (package == 'ispectify_db') {
            throw PubApiException(
              'https://pub.dev/api/packages/$package answered 503',
              package: package,
              statusCode: 503,
            );
          }
          return const <Version>[];
        },
      );

      expect(result.exitCode, 1);
      expect(result.errorLines, [
        '[ERR] https://pub.dev/api/packages/ispectify_db answered 503',
        '[ERR] Could not read the published versions of ispectify_db',
        '[ERR] Published-version check failed. Pick a version the resolver '
            'orders above the peak of its release line.',
      ]);
    });

    test('--skip-pub-version-check never asks the host', () async {
      var asked = 0;
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        publishedVersions: (_) async {
          asked++;
          return const <Version>[];
        },
      );

      expect(asked, 0);
      expect(
        result.out,
        contains(
          '[..] Skipping the published-version check '
          '(--skip-pub-version-check)',
        ),
      );
    });
  });

  group('working-tree preflight', () {
    test('an untracked file blocks the run and is echoed back', () async {
      final runner = FakeProcessRunner(statusLines: const ['?? scratch.txt']);

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 1);
      expect(
        result.err,
        '[ERR] Publishing requires a clean working tree (including untracked '
        'files).\n?? scratch.txt\n',
      );
      expect(runner.commands, [
        'git status --porcelain --untracked-files=all [repo]',
      ]);
    });

    test('a git that cannot answer propagates its own exit code', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: FakeProcessRunner(statusExitCode: 128),
      );

      expect(result.exitCode, 128);
      expect(result.err, contains('not a git repository'));
    });

    test('the tree is re-checked after formatting rewrites it', () async {
      final runner = FakeProcessRunner(
        statusLinesAfterFormat: const [' M packages/ispect/lib/ispect.dart'],
      );

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 1);
      expect(runner.statusCalls, 2);
      expect(
        result.err,
        contains(' M packages/ispect/lib/ispect.dart'),
      );
      expect(runner.commands, contains('dart format . [repo]'));
    });

    test('formatting runs between the two tree checks', () async {
      final runner = FakeProcessRunner();

      await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      final gitAndFormat = [
        for (final command in runner.commands)
          if (command.startsWith('git status') ||
              command.startsWith('dart format'))
            command,
      ];
      expect(gitAndFormat, [
        'git status --porcelain --untracked-files=all [repo]',
        'dart format . [repo]',
        'git status --porcelain --untracked-files=all [repo]',
      ]);
    });

    test('a failing formatter propagates its exit code', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          formatResult: const CommandResult(
            exitCode: 65,
            output: 'Could not format because the source could not be parsed\n',
          ),
        ),
      );

      expect(result.exitCode, 65);
      expect(result.err, contains('could not be parsed'));
    });
  });

  group('pubspec preflight', () {
    test('an unconstrained dependency blocks the run', () async {
      final result = await invoke(
        fixture(constraint: 'any'),
        const ['--dry-run', '--skip-pub-version-check'],
      );

      expect(result.exitCode, 1);
      expect(result.errorLines.first, contains("'ispectify' has "));
      expect(
        result.errorLines.last,
        '[ERR] Preflight validation failed. Fix issues above before '
        'publishing.',
      );
      expect(result.errorLines, hasLength(publishOrder.length + 1));
    });

    test('a caret constraint passes the same check', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
      );

      expect(result.exitCode, 0);
      expect(result.out, contains('[OK] Preflight validation passed.'));
    });

    test('a committed Podfile.lock blocks the run', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          podfileLocks: const {
            'ispect': ['packages/ispect/example/ios/Podfile.lock'],
          },
        ),
      );

      expect(result.exitCode, 1);
      expect(result.errorLines, [
        "[ERR] 'ispect' contains a committed Podfile.lock. Remove it "
            "(platform lockfiles shouldn't be published).",
        '[ERR] Preflight validation failed. Fix issues above before '
            'publishing.',
      ]);
    });

    test('the Podfile.lock pathspec covers nested example projects', () async {
      final runner = FakeProcessRunner();

      await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(
        runner.commands,
        contains(
          'git ls-files -- packages/ispectify_bloc/**/Podfile.lock [repo]',
        ),
      );
    });
  });

  group('publish order', () {
    test('packages are processed base-first and ispect last', () async {
      final runner = FakeProcessRunner();

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.pubGetOrder, const [
        'ispectify',
        'ispectify_bloc',
        'ispectify_dio',
        'ispectify_http',
        'ispectify_ws',
        'ispectify_riverpod',
        'ispectify_db',
        'ispect_layout',
        'ispect',
      ]);
    });

    test('every adapter is published after the base it depends on', () async {
      final runner = FakeProcessRunner();

      await invoke(
        fixture(),
        const ['--auto', '--skip-pub-version-check'],
        runner: runner,
      );

      final order = runner.publishedPackages;
      for (final adapter in order.where((name) => name != 'ispectify')) {
        expect(
          order.indexOf('ispectify'),
          lessThan(order.indexOf(adapter)),
          reason: '$adapter must not go out before ispectify',
        );
      }
      expect(order.last, 'ispect');
    });

    test('every package is dry-run in its own directory', () async {
      final runner = FakeProcessRunner();

      await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      for (final package in publishOrder) {
        expect(
          runner.commands,
          contains('dart pub publish --dry-run [$package]'),
        );
      }
    });
  });

  group('modes', () {
    test('--dry-run publishes nothing and asks nothing', () async {
      final runner = FakeProcessRunner();
      final confirmation = FakeConfirmation();

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
        confirmation: confirmation,
      );

      expect(result.exitCode, 0);
      expect(confirmation.asked, isEmpty);
      expect(runner.publishedPackages, isEmpty);
      expect(
          result.out,
          contains('[OK] Dry-run complete. No packages '
              'published.'));
    });

    test('--dry-run overrides --auto', () async {
      final runner = FakeProcessRunner();

      final result = await invoke(
        fixture(),
        const ['--auto', '--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.publishedPackages, isEmpty);
    });

    test('--auto publishes every package without asking', () async {
      final runner = FakeProcessRunner();
      final confirmation = FakeConfirmation();

      final result = await invoke(
        fixture(),
        const ['--auto', '--skip-pub-version-check'],
        runner: runner,
        confirmation: confirmation,
      );

      expect(result.exitCode, 0);
      expect(confirmation.asked, isEmpty);
      expect(runner.publishedPackages, publishOrder);
      expect(
        result.out,
        contains('[OK] All requested packages processed.'),
      );
    });

    test('the default mode publishes only what the operator confirms',
        () async {
      final runner = FakeProcessRunner();
      final confirmation = FakeConfirmation(
        answer: false,
        answers: const {'ispectify': true, 'ispect': true},
      );

      final result = await invoke(
        fixture(),
        const ['--skip-pub-version-check'],
        runner: runner,
        confirmation: confirmation,
      );

      expect(result.exitCode, 0);
      expect(confirmation.asked, publishOrder);
      expect(runner.publishedPackages, ['ispectify', 'ispect']);
      expect(result.out, contains('[..] Skip ispectify_dio'));
    });

    test('PUBLISH_FORCE skips the prompt in the default mode', () async {
      final runner = FakeProcessRunner();
      final confirmation = FakeConfirmation(answer: false);

      final result = await invoke(
        fixture(),
        const ['--skip-pub-version-check'],
        runner: runner,
        confirmation: confirmation,
        environment: const {'PUBLISH_FORCE': '1'},
      );

      expect(result.exitCode, 0);
      expect(confirmation.asked, isEmpty);
      expect(runner.publishedPackages, publishOrder);
    });

    test('an empty PUBLISH_FORCE still prompts', () async {
      final confirmation = FakeConfirmation(answer: false);

      await invoke(
        fixture(),
        const ['--skip-pub-version-check'],
        confirmation: confirmation,
        environment: const {'PUBLISH_FORCE': ''},
      );

      expect(confirmation.asked, publishOrder);
    });

    test('--verbose prints the dry-run output of every package', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--verbose', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          dryRunResults: {
            for (final package in publishOrder)
              package: CommandResult(
                exitCode: 0,
                output: 'Package has 1 warning for $package.\n',
              ),
          },
        ),
      );

      expect(result.exitCode, 0);
      expect(result.out, contains('Package has 1 warning for ispect.'));
    });

    test('without --verbose the successful dry-run output stays quiet',
        () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          dryRunResults: {
            for (final package in publishOrder)
              package: const CommandResult(
                exitCode: 0,
                output: 'Package has 1 warning.\n',
              ),
          },
        ),
      );

      expect(result.out, isNot(contains('Package has 1 warning.')));
    });
  });

  group('failure reporting', () {
    test('a failed dry-run is summarized with its reason and exits non-zero',
        () async {
      final repo = fixture();
      final result = await invoke(
        repo,
        const ['--dry-run', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          dryRunResults: const {
            'ispectify_http': CommandResult(
              exitCode: 1,
              output: 'Resolving dependencies...\n'
                  'Because ispectify_http depends on nope any, version '
                  'solving failed.\n',
            ),
            'ispect': CommandResult(
              exitCode: 1,
              output: 'Package validation found the following errors:\n'
                  '* Your package is missing a CHANGELOG.md file.\n',
            ),
          },
        ),
      );

      expect(result.exitCode, 1);
      expect(
          result.out,
          contains('  - ispectify_http: Because ispectify_http '
              'depends on nope any, version solving failed.'));
      expect(
        result.out,
        contains('  - ispect: Package validation found the following errors:'),
      );
      expect(result.err, contains('[ERR] Summary of failed packages:'));
      expect(
        result.out,
        contains('[..] See detailed logs in: ${p.join(repo, ".publish_logs")}'),
      );
    });

    test('a failed dry-run leaves its full output in .publish_logs', () async {
      final repo = fixture();
      await invoke(
        repo,
        const ['--dry-run', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          dryRunResults: const {
            'ispectify_ws': CommandResult(
              exitCode: 65,
              output: 'Error: something went wrong\ndetail line\n',
            ),
          },
        ),
      );

      final log =
          File(p.join(repo, '.publish_logs', 'ispectify_ws_dry_run.log'));
      expect(log.existsSync(), isTrue);
      expect(
        log.readAsStringSync(),
        'Error: something went wrong\ndetail line\n',
      );
    });

    test('a failing package does not stop the packages after it', () async {
      final runner = FakeProcessRunner(
        dryRunResults: const {
          'ispectify': CommandResult(exitCode: 1, output: 'Error: nope\n'),
        },
      );

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 1);
      expect(runner.pubGetOrder, publishOrder);
    });

    test('a package that fails the dry-run is never published', () async {
      final runner = FakeProcessRunner(
        dryRunResults: const {
          'ispectify_bloc': CommandResult(exitCode: 1, output: 'Error: nope\n'),
        },
      );

      final result = await invoke(
        fixture(),
        const ['--auto', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 1);
      expect(runner.publishedPackages, isNot(contains('ispectify_bloc')));
    });

    test('a failed real publish is named in the summary', () async {
      final result = await invoke(
        fixture(),
        const ['--auto', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          publishResults: const {
            'ispect': CommandResult(
              exitCode: 1,
              output: 'Error: the server refused the upload\n',
            ),
          },
        ),
      );

      expect(result.exitCode, 1);
      expect(result.err, contains('[ERR] (ispect) publish failed'));
      expect(
        result.out,
        contains('  - ispect: Error: the server refused the upload'),
      );
    });

    test('a failed pub get is named instead of being carried into the dry-run',
        () async {
      final runner = FakeProcessRunner(
        pubGetResults: const {
          'ispectify_riverpod': CommandResult(
            exitCode: 69,
            output: 'Because ispectify_riverpod depends on gone any.\n',
          ),
        },
      );

      final result = await invoke(
        fixture(),
        const ['--dry-run', '--skip-pub-version-check'],
        runner: runner,
      );

      expect(result.exitCode, 1);
      expect(
        runner.commands,
        isNot(contains('dart pub publish --dry-run [ispectify_riverpod]')),
      );
      expect(
        result.out,
        contains('  - ispectify_riverpod: Because ispectify_riverpod depends '
            'on gone any.'),
      );
    });

    test('--verbose prints the failing output instead of a log path', () async {
      final result = await invoke(
        fixture(),
        const ['--dry-run', '--verbose', '--skip-pub-version-check'],
        runner: FakeProcessRunner(
          dryRunResults: const {
            'ispect_layout': CommandResult(
              exitCode: 1,
              output: 'Error: nope\nsecond line\n',
            ),
          },
        ),
      );

      expect(
        result.out,
        contains('---- FULL DRY-RUN OUTPUT (ispect_layout) ----'),
      );
      expect(result.out, contains('second line'));
      expect(result.out, isNot(contains('[..] Full log:')));
    });

    test('the log directory is emptied at the start of every run', () async {
      final repo = fixture();
      final stale = File(p.join(repo, '.publish_logs', 'stale.log'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('stale\n');

      await invoke(
        repo,
        const ['--dry-run', '--skip-pub-version-check'],
      );

      expect(stale.existsSync(), isFalse);
      expect(Directory(p.join(repo, '.publish_logs')).existsSync(), isTrue);
    });
  });

  group('extractFailureReason', () {
    test('prefers the resolver explanation over earlier progress lines', () {
      expect(
        extractFailureReason(
          'Resolving dependencies...\nBecause a depends on b, it failed.\n',
        ),
        'Because a depends on b, it failed.',
      );
    });

    test('recognises an error line', () {
      expect(
        extractFailureReason('noise\nError: boom\nmore\n'),
        'Error: boom',
      );
    });

    test('recognises a validation bullet', () {
      expect(
        extractFailureReason('noise\n* Your package is missing a LICENSE.\n'),
        '* Your package is missing a LICENSE.',
      );
    });

    test('falls back to the first line when nothing is recognised', () {
      expect(extractFailureReason('unhelpful\ntrailer\n'), 'unhelpful');
    });

    test('reports nothing for empty output', () {
      expect(extractFailureReason(''), '');
      expect(extractFailureReason('\n\n'), '');
    });
  });
}
