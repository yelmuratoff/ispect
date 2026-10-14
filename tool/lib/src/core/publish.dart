import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'exceptions.dart';
import 'next_version.dart';
import 'pub_client.dart';
import 'version_config.dart';

const String _versionFile = 'version.config';
const String _logDirectory = '.publish_logs';

const String _usage = '''
ispect_tool publish - publish every package in dependency order

Usage:
  ispect_tool publish                       Dry-run each package, then confirm
  ispect_tool publish --dry-run             Never publish
  ispect_tool publish --auto                No prompts, real publish

Options:
  --dry-run                 Stop after the dry-run of every package
  --auto                    Publish without asking; overridden by --dry-run
  --only <package>          Limit the run to one package; repeatable
  --verbose, -v             Print the full dry-run output of every package
  --skip-pub-version-check  Do not ask the host what it already serves

$publishEnvironmentHelp''';

/// The environment variables a publish run reads, as printed in its help.
const String publishEnvironmentHelp = '''
Environment:
  PUBLISH_FORCE             Any non-empty value publishes without the per-package
                            prompt in the default mode; --dry-run still wins''';

/// The packages this monorepo publishes, in dependency order.
///
/// `ispectify` carries the primitives every adapter imports and `ispect`
/// depends on the adapters, so publishing out of this order leaves consumers
/// resolving against versions the host does not serve yet.
const List<String> publishOrder = [
  'ispectify',
  'ispectify_bloc',
  'ispectify_dio',
  'ispectify_http',
  'ispectify_ws',
  'ispectify_riverpod',
  'ispectify_db',
  'ispect_layout',
  'ispect',
];

final RegExp _anyConstraint = RegExp(
  r'^[ \t]+[a-zA-Z0-9_]+: any$',
  multiLine: true,
);
final RegExp _reasonLine =
    RegExp(r'^(Because|Error:|ERR |Package validation)|^\* ');
final RegExp _trailingNewlines = RegExp(r'\n+$');

/// What one external command reported.
final class CommandResult {
  const CommandResult({required this.exitCode, required this.output});

  final int exitCode;

  /// Standard output and standard error merged, in the order they were written.
  final String output;

  bool get succeeded => exitCode == 0;
}

/// Runs the external commands a publish run drives.
///
/// A publish run shells out to `git`, `dart format`, `dart pub get`, and
/// `dart pub publish`. The last of those is irreversible, so every caller that
/// must not reach pub.dev - every test above all - substitutes its own runner
/// here rather than relying on a flag to hold the real one back.
abstract interface class ProcessRunner {
  /// Runs [executable] with [arguments] and waits for it to exit.
  ///
  /// Returns exit code 127 and a diagnostic in [CommandResult.output] when the
  /// executable cannot be started, matching a shell that cannot find it.
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  });
}

/// [ProcessRunner] over real child processes.
final class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) {
    final ProcessResult result;
    try {
      result = Process.runSync(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    } on ProcessException catch (error) {
      return CommandResult(exitCode: 127, output: '${error.message}\n');
    }
    return CommandResult(
      exitCode: result.exitCode,
      output: '${result.stdout}${result.stderr}',
    );
  }
}

/// Asks the operator whether one package may go out.
///
/// A publish run only consults this in its default mode; `--auto` and
/// `--dry-run` never reach it. Tests substitute their own implementation so no
/// suite can block on standard input.
abstract interface class PublishConfirmation {
  /// Whether [package] may be published now.
  bool shouldPublish(String package);
}

/// [PublishConfirmation] over an interactive terminal.
final class StdinConfirmation implements PublishConfirmation {
  const StdinConfirmation({this.out, this.input});

  final StringSink? out;
  final Stdin? input;

  @override
  bool shouldPublish(String package) {
    (out ?? stdout).write('Publish $package? [y/N] ');
    final answer = ((input ?? stdin).readLineSync() ?? '').trim();
    return answer == 'y' || answer == 'Y';
  }
}

/// Reads every version a package host already serves for one package.
///
/// Throws [PubApiException] when the host leaves the question unanswered; an
/// unpublished package answers with an empty list.
typedef PublishedVersionsReader = Future<List<Version>> Function(
    String package);

/// Judges releasing [target] for every package in [packages], in order.
///
/// A package the host leaves unanswered yields [PublishedVersionsUnknown]
/// instead of stopping the walk, so one report names every blocked package.
Future<List<PublishGate>> gateRelease({
  required Iterable<String> packages,
  required Version target,
  required PublishedVersionsReader publishedVersions,
}) async {
  final gates = <PublishGate>[];
  for (final package in packages) {
    try {
      gates.add(
        publishGate(
          package: package,
          target: target,
          published: await publishedVersions(package),
        ),
      );
    } on PubApiException catch (error) {
      gates.add(
        PublishedVersionsUnknown(
          package: package,
          target: target,
          error: error,
        ),
      );
    }
  }
  return gates;
}

/// The lowest version every package in [gates] would let through, or null
/// when no package has opened the release line yet.
Version? lowestPublishableFor(Iterable<PublishGate> gates) =>
    lowestPublishableAbove([
      for (final gate in gates)
        if (_peakOf(gate) case final Version peak) peak,
    ]);

Version? _peakOf(PublishGate gate) => switch (gate) {
      AlreadyPublished(:final target) => target,
      RisesAbovePeak(:final peak) || BlockedByPeak(:final peak) => peak,
      PackageUnpublished() ||
      ReleaseLineUnopened() ||
      PublishedVersionsUnknown() =>
        null,
    };

/// Writes one line per gate in [gates] and, when any is blocked, the lowest
/// version that would pass; returns 1 when the release is blocked, else 0.
int reportReleaseGates(
  List<PublishGate> gates, {
  required void Function(String message) info,
  required void Function(String message) error,
}) {
  for (final gate in gates) {
    final package = gate.package;
    final target = gate.target;
    switch (gate) {
      case PackageUnpublished():
        info('$package has no published versions yet');
      case ReleaseLineUnopened():
        info('$package opens the ${releaseLine(target)} line');
      case AlreadyPublished():
        error(
          '$package $target is already published; bump the version before '
          'releasing again',
        );
      case RisesAbovePeak(:final peak):
        info('$package $target is ranked above the published $peak');
      case BlockedByPeak(:final peak, :final reason):
        error(
          '$package $target is not ranked above the published $peak; '
          'consumers would keep resolving $peak ($reason)',
        );
      case PublishedVersionsUnknown(error: final failure):
        error(failure.message);
        error('Could not read the published versions of $package');
    }
  }

  if (gates.every((gate) => gate.allowed)) {
    return 0;
  }
  error(
    'Published-version check failed. Pick a version the resolver orders '
    'above the peak of its release line.',
  );
  final suggestion = lowestPublishableFor(gates);
  if (suggestion != null) {
    error(
      "Lowest version that would pass: $suggestion - run "
      "'ispect_tool version bump $suggestion'",
    );
  }
  return 1;
}

/// How one publish run treats the dry-run, the prompts, and the host.
final class PublishOptions {
  const PublishOptions({
    this.dryRun = false,
    this.auto = false,
    this.verbose = false,
    this.skipPubVersionCheck = false,
  });

  /// Stop after the dry-run of every package. Overrides [auto].
  final bool dryRun;

  /// Publish without prompting.
  final bool auto;

  /// Print the full dry-run output of every package.
  final bool verbose;

  /// Do not ask the host which versions it already serves.
  final bool skipPubVersionCheck;
}

/// One package the run could not carry through, and why.
final class PublishFailure {
  const PublishFailure({required this.package, required this.reason});

  final String package;

  /// The single line extracted from the failing command's output.
  final String reason;
}

/// Publishes every package in [publishOrder], refusing to start unless the
/// repository is in a releasable state.
final class PublishRun {
  PublishRun({
    required this.repoRoot,
    required this.out,
    required this.err,
    ProcessRunner? runner,
    PublishedVersionsReader? publishedVersions,
    PublishConfirmation? confirmation,
    Map<String, String>? environment,
    List<String>? packages,
  })  : runner = runner ?? const SystemProcessRunner(),
        publishedVersions = publishedVersions ??
            ((package) => PubClient().publishedVersions(package)),
        confirmation = confirmation ?? const StdinConfirmation(),
        environment = environment ?? Platform.environment,
        packages = packages ?? publishOrder;

  final String repoRoot;
  final StringSink out;
  final StringSink err;
  final ProcessRunner runner;
  final PublishedVersionsReader publishedVersions;
  final PublishConfirmation confirmation;
  final Map<String, String> environment;
  final List<String> packages;

  final List<PublishFailure> _failures = [];

  /// Every package the last [run] could not carry through.
  List<PublishFailure> get failures => List.unmodifiable(_failures);

  String get _logDirectoryPath => p.join(repoRoot, _logDirectory);

  /// Runs the publish and returns the process exit code.
  ///
  /// Reports every failure on [out] and [err] rather than throwing. A non-zero
  /// result means at least one preflight refused the repository or at least one
  /// package failed; it never means a package was half-published.
  Future<int> run(PublishOptions options) async {
    final Version version;
    try {
      version = VersionConfig(File(p.join(repoRoot, _versionFile))).read();
    } on VersionConfigException catch (e) {
      _error(_relative(e.message));
      return 1;
    }
    _warn('Project version: $version');

    _resetLogDirectory();
    _failures.clear();

    final preflight = await _preflight(version, options);
    if (preflight != 0) {
      return preflight;
    }

    final failed = <String>[];
    for (final package in packages) {
      if (!await _publishPackage(package, options)) {
        failed.add(package);
      }
    }

    if (failed.isNotEmpty) {
      out.writeln('');
      _error('Summary of failed packages:');
      for (final failure in _failures) {
        out.writeln('  - ${failure.package}: ${failure.reason}');
      }
      _warn('See detailed logs in: $_logDirectoryPath');
      return 1;
    }

    _info(
      options.dryRun
          ? 'Dry-run complete. No packages published.'
          : 'All requested packages processed.',
    );
    return 0;
  }

  Future<int> _preflight(Version version, PublishOptions options) async {
    final versions = _checkVersions(version);
    if (versions != 0) {
      return versions;
    }

    final published = await _checkPublishedVersionLine(version, options);
    if (published != 0) {
      return published;
    }

    final tree = _ensureCleanGit();
    if (tree != 0) {
      return tree;
    }

    final pubspecs = _validatePubspecs();
    if (pubspecs != 0) {
      return pubspecs;
    }

    final format = _runFormat();
    if (format != 0) {
      return format;
    }

    return _ensureCleanGit();
  }

  int _checkVersions(Version expected) {
    final declared = PackageVersions(repoRoot).read();

    var mismatched = false;
    for (final package in packages) {
      if (!File(p.join(repoRoot, 'packages', package, 'pubspec.yaml'))
          .existsSync()) {
        _error('Missing pubspec for $package');
        return 1;
      }
      final version = declared[package] ?? '';
      if (version != expected.toString()) {
        _error('$package version $version != $expected');
        mismatched = true;
      }
    }

    if (mismatched) {
      _error('Version mismatch. Run: ispect_tool sync');
      return 1;
    }
    _info('All package versions match $expected');
    return 0;
  }

  Future<int> _checkPublishedVersionLine(
    Version target,
    PublishOptions options,
  ) async {
    if (options.skipPubVersionCheck) {
      _warn('Skipping the published-version check (--skip-pub-version-check)');
      return 0;
    }

    final gates = await gateRelease(
      packages: packages,
      target: target,
      publishedVersions: publishedVersions,
    );
    return reportReleaseGates(gates, info: _info, error: _error);
  }

  int _ensureCleanGit() {
    final status = runner.run(
      'git',
      const ['status', '--porcelain', '--untracked-files=all'],
      workingDirectory: repoRoot,
    );
    if (!status.succeeded) {
      err.write(status.output);
      return status.exitCode;
    }

    final tree = _stripTrailingNewlines(status.output);
    if (tree.isNotEmpty) {
      _error('Publishing requires a clean working tree (including untracked '
          'files).');
      err.writeln(tree);
      return 1;
    }
    _info('Working tree is clean.');
    return 0;
  }

  int _validatePubspecs() {
    var bad = false;
    for (final package in packages) {
      final pubspec =
          File(p.join(repoRoot, 'packages', package, 'pubspec.yaml'));
      if (_anyConstraint.hasMatch(pubspec.readAsStringSync())) {
        _error("'$package' has unconstrained dependencies (uses 'any'). "
            'Replace them with ^version ranges.');
        bad = true;
      }
      final podfileLockProblem = _podfileLockProblem(package);
      if (podfileLockProblem != null) {
        _error(podfileLockProblem);
        bad = true;
      }
    }

    if (bad) {
      _error('Preflight validation failed. Fix issues above before '
          'publishing.');
      return 1;
    }
    _info('Preflight validation passed.');
    return 0;
  }

  String? _podfileLockProblem(String package) {
    final listed = runner.run(
      'git',
      ['ls-files', '--', 'packages/$package/**/Podfile.lock'],
      workingDirectory: repoRoot,
    );
    if (!listed.succeeded) {
      return "Could not check '$package' for a committed Podfile.lock: "
          '${_stripTrailingNewlines(listed.output)}';
    }
    final committed = const LineSplitter()
        .convert(listed.output)
        .any((line) => line.isNotEmpty);
    if (!committed) {
      return null;
    }
    return "'$package' contains a committed Podfile.lock. Remove it "
        "(platform lockfiles shouldn't be published).";
  }

  int _runFormat() {
    _warn('Formatting...');
    final format = runner.run(
      'dart',
      const ['format', '.'],
      workingDirectory: repoRoot,
    );
    if (format.succeeded) {
      return 0;
    }
    err.write(format.output);
    return format.exitCode;
  }

  Future<bool> _publishPackage(String package, PublishOptions options) async {
    final directory = p.join(repoRoot, 'packages', package);

    _warn('($package) pub get');
    // package:realm pins analyzer ^7 against the SDK's flutter_test.
    final get = runner.run(
      'dart',
      const ['pub', 'get', '--no-example'],
      workingDirectory: directory,
    );
    if (!get.succeeded) {
      _recordFailure(package, 'pub_get', get.output, options);
      return false;
    }

    _warn('($package) dart pub publish --dry-run');
    final dry = runner.run(
      'dart',
      const ['pub', 'publish', '--dry-run'],
      workingDirectory: directory,
    );
    if (!dry.succeeded) {
      _recordFailure(package, 'dry_run', dry.output, options);
      return false;
    }
    if (options.verbose) {
      out.writeln(_stripTrailingNewlines(dry.output));
    }
    _info('($package) dry-run OK');

    if (options.dryRun) {
      return true;
    }

    final forced = (environment['PUBLISH_FORCE'] ?? '').isNotEmpty;
    if (!options.auto && !forced && !confirmation.shouldPublish(package)) {
      _warn('Skip $package');
      return true;
    }

    _warn('($package) publishing...');
    final published = runner.run(
      'dart',
      const ['pub', 'publish', '--force'],
      workingDirectory: directory,
    );
    if (published.output.isNotEmpty) {
      out.writeln(_stripTrailingNewlines(published.output));
    }
    if (published.succeeded) {
      _info('($package) published');
      return true;
    }
    _recordFailure(package, 'publish', published.output, options,
        headline: '($package) publish failed');
    return false;
  }

  void _recordFailure(
    String package,
    String stage,
    String output,
    PublishOptions options, {
    String? headline,
  }) {
    final log = File(p.join(_logDirectoryPath, '${package}_$stage.log'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('${_stripTrailingNewlines(output)}\n');

    final reason = extractFailureReason(output);
    _failures.add(PublishFailure(package: package, reason: reason));
    _error(headline ?? '${_stageLabel(stage)} failed for $package: $reason');

    if (options.verbose) {
      out
        ..writeln('---- FULL ${_stageLabel(stage).toUpperCase()} OUTPUT '
            '($package) ----')
        ..writeln(_stripTrailingNewlines(output))
        ..writeln('------------------------------------');
    } else {
      _warn('Full log: ${log.path}');
    }
  }

  static String _stageLabel(String stage) => switch (stage) {
        'pub_get' => 'Pub get',
        'publish' => 'Publish',
        _ => 'Dry-run',
      };

  void _resetLogDirectory() {
    final directory = Directory(_logDirectoryPath);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    } else if (File(_logDirectoryPath).existsSync()) {
      File(_logDirectoryPath).deleteSync();
    }
    directory.createSync(recursive: true);
  }

  String _relative(String message) =>
      message.replaceAll(p.join(repoRoot, _versionFile), _versionFile);

  void _info(String message) => out.writeln('[OK] $message');

  void _warn(String message) => out.writeln('[..] $message');

  void _error(String message) => err.writeln('[ERR] $message');
}

/// The single line that explains why a publish command failed.
///
/// Prefers the first line pub uses to introduce a resolution or validation
/// failure and falls back to the first line of [output].
String extractFailureReason(String output) {
  final lines = const LineSplitter().convert(_stripTrailingNewlines(output));
  for (final line in lines) {
    if (_reasonLine.hasMatch(line)) {
      return line;
    }
  }
  return lines.isEmpty ? '' : lines.first;
}

String _stripTrailingNewlines(String value) =>
    value.replaceAll(_trailingNewlines, '');

/// Parses [arguments], publishes, and returns the process exit code.
///
/// Returns 2 for an argument the run does not accept and 1 for any failure it
/// reports; `--help` prints the usage block and returns 0.
///
/// [runner] and [confirmation] are the seams that keep a caller away from
/// pub.dev and away from standard input; leaving them null reaches both.
Future<int> runPublish({
  required String repoRoot,
  required List<String> arguments,
  StringSink? out,
  StringSink? err,
  ProcessRunner? runner,
  PublishedVersionsReader? publishedVersions,
  PublishConfirmation? confirmation,
  Map<String, String>? environment,
  List<String>? packages,
}) async {
  final output = out ?? stdout;
  final errors = err ?? stderr;

  var dryRun = false;
  var auto = false;
  var verbose = false;
  var skipPubVersionCheck = false;
  final only = <String>{};

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    switch (argument) {
      case '--dry-run':
        dryRun = true;
      case '--auto':
        auto = true;
      case '--only':
        index++;
        if (index >= arguments.length) {
          errors.writeln('Missing package name after --only');
          return 2;
        }
        final selected = arguments[index];
        if (!publishOrder.contains(selected)) {
          errors.writeln('Unknown package: $selected');
          return 2;
        }
        only.add(selected);
      case '--verbose' || '-v':
        verbose = true;
      case '--skip-pub-version-check':
        skipPubVersionCheck = true;
      case '--help' || '-h':
        output.writeln(_usage);
        return 0;
      default:
        errors.writeln('Unknown option: $argument');
        return 2;
    }
  }

  final selection = packages ?? publishOrder;

  return PublishRun(
    repoRoot: repoRoot,
    out: output,
    err: errors,
    runner: runner,
    publishedVersions: publishedVersions,
    confirmation: confirmation,
    environment: environment,
    packages: only.isEmpty
        ? packages
        : [
            for (final package in selection)
              if (only.contains(package)) package,
          ],
  ).run(
    PublishOptions(
      dryRun: dryRun,
      auto: auto,
      verbose: verbose,
      skipPubVersionCheck: skipPubVersionCheck,
    ),
  );
}
