import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'changelog.dart';
import 'dependency_check.dart';
import 'exceptions.dart';
import 'llms_builder.dart';
import 'managed_file_transaction.dart';
import 'next_version.dart';
import 'readme_builder.dart';
import 'version_config.dart';
import 'version_sync.dart';

const String _versionFile = 'version.config';
const String _changelogFile = 'CHANGELOG.md';
const String _changelogBackupPrefix = 'ispect-changelog-edit.';
const String _tempAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

const String _usage = '''
ispect_tool release-prep - synchronize every release-managed artifact

Usage:
  ispect_tool release-prep [patch|minor|major] [options]
  ispect_tool release-prep --bump patch|minor|major [options]
  ispect_tool release-prep --skip-bump [options]
  ispect_tool release-prep --carry-changelog

Modes:
  patch|minor|major     Bump kind (default: patch)
  --bump <kind>        Explicit bump kind (patch, minor, or major)
  --skip-bump          Keep VERSION and synchronize every derived artifact
  --no-bump            Alias for --skip-bump

Options:
  --carry-changelog    Move the previous prerelease notes to the next prerelease
  --recover-changelog  Resume an interrupted prerelease sync without a bump
  --edit               Open CHANGELOG.md before generating derived artifacts
  --help               Show this help

The command updates version metadata, internal constraints, the web viewer
lockfile, root and package changelogs, generated READMEs, and llms.txt. It then
validates the complete result. If any step fails, all managed files are restored
to their exact pre-run state.''';

/// The generators and validators a release run drives, in the order it drives
/// them.
///
/// Every member returns a process exit code. A non-zero code aborts the run,
/// which then restores every managed file to its pre-run state, so an
/// implementation may leave a partial result behind.
abstract interface class ReleaseSteps {
  /// Propagates `version.config` to every manifest, first advancing it by
  /// [bump] unless [bump] is null.
  int syncVersions(BumpKind? bump);

  /// Copies the root changelog over every package changelog.
  int propagateChangelog();

  /// Renders the generated READMEs.
  int buildReadmes();

  /// Renders the generated `llms.txt` index.
  int buildLlms();

  /// Verifies every package version matches `version.config`.
  int checkVersionSync();

  /// Verifies every internal `^` constraint matches `version.config`.
  int checkDependencies();

  /// Verifies the generated READMEs match their sources.
  int checkReadmes();

  /// Verifies the generated `llms.txt` matches repository metadata.
  int checkLlms();
}

/// [ReleaseSteps] over the ported Dart modules.
final class DartReleaseSteps implements ReleaseSteps {
  const DartReleaseSteps({
    required this.repoRoot,
    required this.out,
    required this.err,
  });

  final String repoRoot;
  final StringSink out;
  final StringSink err;

  @override
  int syncVersions(BumpKind? bump) => runVersionSync(
        repoRoot: repoRoot,
        arguments: bump == null ? const [] : ['--bump', bump.name],
        out: out,
        err: err,
      );

  @override
  int propagateChangelog() => runChangelogPropagation(
        repoRoot: repoRoot,
        arguments: const ['--full-copy', '--yes'],
        out: out,
        err: err,
      );

  @override
  int buildReadmes() => runReadmeBuild(
        repoRoot: repoRoot,
        arguments: const [],
        out: out,
        err: err,
      );

  @override
  int buildLlms() => runLlmsBuild(
        repoRoot: repoRoot,
        arguments: const [],
        out: out,
        err: err,
      );

  @override
  int checkReadmes() => runReadmeBuild(
        repoRoot: repoRoot,
        arguments: const ['--check'],
        out: out,
        err: err,
      );

  @override
  int checkLlms() => runLlmsBuild(
        repoRoot: repoRoot,
        arguments: const ['--check'],
        out: out,
        err: err,
      );

  @override
  int checkVersionSync() {
    final expected = VersionConfig.forRepo(repoRoot).read();
    out.writeln('[INFO] Version from version.config: $expected');

    final declared = PackageVersions(repoRoot).read();
    final outOfSync = <String>[];
    for (final entry in declared.entries) {
      final matches = entry.value == expected.toString();
      out.writeln(
        '${matches ? "[OK ]" : "[ERR]"} ${entry.key}: ${entry.value}',
      );
      if (!matches) {
        outOfSync.add(entry.key);
      }
    }

    if (outOfSync.isEmpty) {
      out.writeln('[OK ] All ${declared.length} packages match $expected');
      return 0;
    }
    err.writeln(
      '[ERR] ${outOfSync.length} package(s) do not match $expected: '
      '${outOfSync.join(", ")}',
    );
    return 1;
  }

  @override
  int checkDependencies() {
    final expected = VersionConfig.forRepo(repoRoot).read();
    final found = DependencyCheck(repoRoot).findInconsistencies(expected);
    for (final inconsistency in found) {
      err.writeln('[ERR] ${inconsistency.describe(expected)}');
    }
    if (found.isEmpty) {
      out.writeln('[OK ] Every internal constraint matches $expected');
      return 0;
    }
    err.writeln(
      '[ERR] ${found.length} internal constraint(s) do not match $expected',
    );
    return 1;
  }
}

/// The checks that decide whether the repository is in a releasable state.
///
/// A release run stops at the first failure because it holds a transaction
/// open; a standalone check runs them all so one command reports everything
/// that is wrong. Both read the set from here.
List<int Function()> repositoryChecks(ReleaseSteps steps) => [
      steps.checkVersionSync,
      steps.checkDependencies,
      steps.checkReadmes,
      steps.checkLlms,
    ];

/// How one release run should treat the version and the changelog.
final class ReleasePrepOptions {
  const ReleasePrepOptions({
    this.bump = BumpKind.patch,
    this.bumpWasExplicit = false,
    this.skipBump = false,
    this.carryChangelog = false,
    this.recoverChangelog = false,
    this.openEditor = false,
  });

  final BumpKind bump;

  /// Whether [bump] came from an argument rather than the default, which is
  /// what makes combining it with [skipBump] a conflict.
  final bool bumpWasExplicit;

  final bool skipBump;

  /// Move the previous prerelease's notes onto the new version instead of
  /// opening an empty section.
  final bool carryChangelog;

  /// Rename the previous prerelease's section to the current version, resuming
  /// a sync that was interrupted after the bump.
  final bool recoverChangelog;

  final bool openEditor;
}

/// Synchronizes every release-managed artifact, restoring all of them when any
/// step fails.
final class ReleasePrep {
  ReleasePrep({
    required this.repoRoot,
    required this.out,
    required this.err,
    ReleaseSteps? steps,
    Directory? tempRoot,
    Map<String, String>? environment,
  })  : steps =
            steps ?? DartReleaseSteps(repoRoot: repoRoot, out: out, err: err),
        _tempRoot = tempRoot ?? Directory.systemTemp,
        _environment = environment ?? Platform.environment;

  final String repoRoot;
  final StringSink out;
  final StringSink err;
  final ReleaseSteps steps;
  final Directory _tempRoot;
  final Map<String, String> _environment;

  File? _editedChangelogBackup;

  /// Runs the release preparation and returns the process exit code.
  ///
  /// Reports every failure on [err] rather than throwing; a non-zero result
  /// always leaves the managed files as they were before the run, unless the
  /// rollback itself is reported as failed.
  Future<int> run(ReleasePrepOptions options) async {
    final List<String> targets;
    final String previousVersion;
    try {
      _assertOptionsAgree(options);
      _assertChangelogShape();
      previousVersion = _readVersion();
      targets = _collectReleaseTargets();
    } on ToolException catch (e) {
      err.writeln('[ERR] ${e.message}');
      return 1;
    }

    final transaction = ManagedFileTransaction(
      repoRoot: repoRoot,
      targets: targets,
      err: err,
      tempRoot: _tempRoot,
    );
    try {
      transaction.begin();
    } on ManagedPathException catch (e) {
      err.writeln('[ERR] ${e.message}');
      return 1;
    }

    var status = 0;
    try {
      status = await _synchronize(options, previousVersion);
    } on ToolException catch (e) {
      err.writeln('[ERR] ${e.message}');
      status = 1;
    }
    if (status == 0) {
      transaction.commit();
    }
    return _finish(transaction, status);
  }

  Future<int> _synchronize(
    ReleasePrepOptions options,
    String previousVersion,
  ) async {
    if (options.skipBump) {
      out.writeln('==> Synchronizing current version: $previousVersion');
    } else {
      out.writeln(
        '==> Bumping version (${options.bump.name}): $previousVersion',
      );
    }
    var status = steps.syncVersions(options.skipBump ? null : options.bump);
    if (status != 0) {
      return status;
    }

    final targetVersion = _readVersion();
    out.writeln('==> Target version: $targetVersion');
    _syncChangelogHeading(options, previousVersion, targetVersion);

    if (options.openEditor) {
      await _openChangelogEditor();
    }

    out.writeln('==> Synchronizing package changelogs');
    status = steps.propagateChangelog();
    if (status != 0) {
      return status;
    }

    out.writeln('==> Generating READMEs');
    status = steps.buildReadmes();
    if (status != 0) {
      return status;
    }

    out.writeln('==> Generating llms.txt');
    status = steps.buildLlms();
    if (status != 0) {
      return status;
    }

    status = _validateRelease(targetVersion);
    if (status != 0) {
      return status;
    }

    out.writeln(
      '==> Release artifacts are synchronized (version: $targetVersion)',
    );
    return 0;
  }

  void _assertOptionsAgree(ReleasePrepOptions options) {
    if (options.skipBump && options.bumpWasExplicit) {
      throw const ReleasePrepException(
        'A bump kind cannot be combined with --skip-bump',
      );
    }
    if (options.skipBump && options.carryChangelog) {
      throw const ReleasePrepException(
        '--carry-changelog cannot be combined with --skip-bump',
      );
    }
    if (options.recoverChangelog && !options.skipBump) {
      throw const ReleasePrepException(
        '--recover-changelog requires --skip-bump',
      );
    }
  }

  void _assertChangelogShape() {
    final changelog = _file(_changelogFile);
    if (!changelog.existsSync()) {
      throw const ReleasePrepException('$_changelogFile not found');
    }
    final lines = _lines(changelog.readAsStringSync());
    if (lines.isEmpty || lines.first != '# Changelog') {
      throw const ReleasePrepException(
        "$_changelogFile must start with '# Changelog'",
      );
    }
  }

  /// The raw `VERSION=` value, kept as text so every heading the run writes is
  /// byte-identical to the file it came from.
  String _readVersion() {
    final file = _file(_versionFile);
    if (!file.existsSync()) {
      throw const ReleasePrepException('$_versionFile not found');
    }

    var value = '';
    for (final line in file.readAsLinesSync()) {
      final separator = line.indexOf('=');
      if (separator < 0 || line.substring(0, separator) != 'VERSION') {
        continue;
      }
      value = line.substring(separator + 1);
      break;
    }

    try {
      Version.parse(value);
    } on FormatException {
      throw ReleasePrepException(
        'Invalid VERSION in $_versionFile: ${value.isEmpty ? '<empty>' : value}',
      );
    }
    return value;
  }

  List<String> _collectReleaseTargets() {
    final targets = <String>[
      _versionFile,
      _changelogFile,
      'README.md',
      'llms.txt',
      'web_logs_viewer/pubspec.yaml',
      'web_logs_viewer/pubspec.lock',
    ];

    for (final directory in _packageDirectories()) {
      for (final relative in const [
        'pubspec.yaml',
        'CHANGELOG.md',
        'README.md',
        'example/pubspec.yaml',
      ]) {
        targets.add('packages/$directory/$relative');
      }
    }
    return targets;
  }

  List<String> _packageDirectories() {
    final packages = Directory(p.join(repoRoot, 'packages'));
    if (!packages.existsSync()) {
      return const [];
    }
    return packages
        .listSync()
        .whereType<Directory>()
        .map((directory) => p.basename(directory.path))
        .toList()
      ..sort();
  }

  void _syncChangelogHeading(
    ReleasePrepOptions options,
    String previousVersion,
    String targetVersion,
  ) {
    final targetCount = _sectionCount(targetVersion);
    if (targetCount > 1) {
      throw ReleasePrepException(
        '$_changelogFile contains duplicate sections for $targetVersion',
      );
    }

    if (options.recoverChangelog) {
      if (targetCount != 0) {
        throw const ReleasePrepException(
          '--recover-changelog requires the target section to be missing',
        );
      }
      final latest = _latestSectionVersion();
      if (_sectionCount(latest) != 1) {
        throw ReleasePrepException(
          'Expected exactly one $latest section to recover',
        );
      }
      if (!_isNextPrerelease(latest, targetVersion)) {
        throw const ReleasePrepException(
          '--recover-changelog requires the immediately previous prerelease',
        );
      }
      out.writeln(
        '==> Recovering interrupted changelog sync: $latest -> $targetVersion',
      );
      _renameChangelogSection(latest, targetVersion);
    } else if (targetCount == 1) {
      if (options.carryChangelog) {
        throw ReleasePrepException(
          'Cannot carry notes: $_changelogFile already contains $targetVersion',
        );
      }
    } else if (options.carryChangelog) {
      if (!_isNextPrerelease(previousVersion, targetVersion)) {
        throw const ReleasePrepException(
          '--carry-changelog only supports the next prerelease of the same '
          'channel',
        );
      }
      if (_sectionCount(previousVersion) != 1) {
        throw ReleasePrepException(
          'Expected exactly one $previousVersion section to carry',
        );
      }
      out.writeln(
        '==> Moving changelog notes: $previousVersion -> $targetVersion',
      );
      _renameChangelogSection(previousVersion, targetVersion);
    } else {
      out.writeln('==> Adding changelog section for $targetVersion');
      _insertChangelogStub(targetVersion);
    }

    final latest = _latestSectionVersion();
    if (latest != targetVersion) {
      throw ReleasePrepException(
        'The first changelog section must be $targetVersion, found '
        '${latest.isEmpty ? 'none' : latest}',
      );
    }
  }

  int _validateRelease(String targetVersion) {
    out.writeln('==> Validating release artifacts');
    for (final check in repositoryChecks(steps)) {
      final status = check();
      if (status != 0) {
        return status;
      }
    }

    if (_sectionCount(targetVersion) != 1) {
      throw ReleasePrepException(
        '$_changelogFile must contain exactly one $targetVersion section',
      );
    }
    if (_latestSectionVersion() != targetVersion) {
      throw ReleasePrepException(
        '$targetVersion must be the first changelog section',
      );
    }
    _assertPackageChangelogsMatch();
    return 0;
  }

  void _assertPackageChangelogsMatch() {
    final root = _file(_changelogFile).readAsStringSync();
    for (final directory in _packageDirectories()) {
      final relative = 'packages/$directory/$_changelogFile';
      final changelog = _file(relative);
      if (!changelog.existsSync()) {
        continue;
      }
      if (changelog.readAsStringSync() != root) {
        throw ReleasePrepException('$relative differs from $_changelogFile');
      }
    }
  }

  Future<void> _openChangelogEditor() async {
    final command = _resolveEditorCommand();
    out.writeln('==> Opening $_changelogFile; save and close to continue');

    final backup = _createBackupFile();
    var editorStatus = 0;
    try {
      final process = await Process.start(
        command.first,
        [...command.skip(1), _changelogFile],
        workingDirectory: repoRoot,
        mode: ProcessStartMode.inheritStdio,
      );
      editorStatus = await process.exitCode;
    } on ProcessException {
      editorStatus = 127;
    }

    backup.writeAsBytesSync(_file(_changelogFile).readAsBytesSync());
    _editedChangelogBackup = backup;

    if (editorStatus != 0) {
      throw const ReleasePrepException('Editor exited with a non-zero status');
    }
  }

  List<String> _resolveEditorCommand() {
    final configured = _environment['EDITOR'] ?? '';
    if (configured.isNotEmpty) {
      final parts =
          configured.split(RegExp('[ \t]+')).where((s) => s.isNotEmpty);
      if (parts.isNotEmpty) {
        return parts.toList();
      }
    }
    if (_onPath('code')) {
      return const ['code', '--wait'];
    }
    if (_onPath('vim')) {
      return const ['vim'];
    }
    if (_onPath('nano')) {
      return const ['nano'];
    }
    throw const ReleasePrepException(
      'No editor found; set EDITOR or omit --edit',
    );
  }

  bool _onPath(String executable) {
    for (final directory in (_environment['PATH'] ?? '').split(':')) {
      if (directory.isEmpty) {
        continue;
      }
      final candidate = File(p.join(directory, executable));
      if (candidate.existsSync() && candidate.statSync().mode & 0x49 != 0) {
        return true;
      }
    }
    return false;
  }

  File _createBackupFile() {
    final random = Random();
    while (true) {
      final suffix = String.fromCharCodes([
        for (var index = 0; index < 6; index++)
          _tempAlphabet.codeUnitAt(random.nextInt(_tempAlphabet.length)),
      ]);
      final candidate =
          File(p.join(_tempRoot.path, '$_changelogBackupPrefix$suffix'));
      if (candidate.existsSync()) {
        continue;
      }
      candidate.createSync(recursive: true);
      return candidate;
    }
  }

  int _finish(ManagedFileTransaction transaction, int status) {
    var result = status;
    var keepSnapshot = false;

    if (transaction.isPending) {
      err.writeln(
        '[WARN] Release preparation failed; restoring the pre-run state',
      );
      if (!transaction.rollback()) {
        err
          ..writeln('[ERR] Automatic rollback failed')
          ..writeln('[INFO] Recovery snapshot retained at '
              '${transaction.snapshotPath}');
        result = 1;
        keepSnapshot = true;
      }
      final backup = _editedChangelogBackup;
      if (backup != null && backup.existsSync()) {
        err.writeln('[INFO] Edited changelog preserved at ${backup.path}');
        _editedChangelogBackup = null;
      }
    }

    if (!keepSnapshot && !transaction.dispose()) {
      result = 1;
    }
    final backup = _editedChangelogBackup;
    if (backup != null && backup.existsSync()) {
      backup.deleteSync();
      _editedChangelogBackup = null;
    }
    return result;
  }

  int _sectionCount(String version) {
    final heading = '## $version';
    return _changelogLines().where((line) => line == heading).length;
  }

  /// Everything after the `## ` of the first section heading, or an empty
  /// string when the changelog has none.
  String _latestSectionVersion() {
    for (final line in _changelogLines()) {
      if (line.startsWith('## ')) {
        return line.substring(3);
      }
    }
    return '';
  }

  bool _isNextPrerelease(String previous, String current) {
    try {
      return nextPrerelease(Version.parse(previous)).toString() == current;
    } on FormatException {
      return false;
    } on VersionRegressionException {
      return false;
    }
  }

  void _renameChangelogSection(String previous, String current) {
    final lines = _changelogLines();
    final heading = '## $previous';
    if (lines.where((line) => line == heading).length != 1) {
      throw ReleasePrepException(
        'Expected exactly one $previous section to rename',
      );
    }
    _writeChangelog([
      for (final line in lines)
        if (line == heading) '## $current' else line,
    ]);
  }

  void _insertChangelogStub(String version) {
    final lines = _changelogLines();
    _writeChangelog([
      lines.first,
      '',
      '## $version',
      '',
      '### Added',
      '',
      '-',
      '',
      '### Improvements',
      '',
      '-',
      '',
      '### Bug Fixes',
      '',
      '-',
      ...lines.skip(1),
    ]);
  }

  List<String> _changelogLines() =>
      _lines(_file(_changelogFile).readAsStringSync());

  void _writeChangelog(List<String> lines) => _file(_changelogFile)
      .writeAsStringSync(lines.map((line) => '$line\n').join());

  File _file(String relativePath) => File(p.join(repoRoot, relativePath));
}

List<String> _lines(String contents) {
  final lines = contents.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

/// Parses [arguments], prepares the release, and returns the process exit code.
///
/// Returns 2 for an argument the run does not accept and 1 for any failure it
/// reports; `--help` prints the usage block and returns 0.
Future<int> runReleasePrep({
  required String repoRoot,
  required List<String> arguments,
  StringSink? out,
  StringSink? err,
  ReleaseSteps? steps,
  Directory? tempRoot,
  Map<String, String>? environment,
}) async {
  final output = out ?? stdout;
  final errors = err ?? stderr;

  var bump = BumpKind.patch;
  var bumpWasExplicit = false;
  var skipBump = false;
  var carryChangelog = false;
  var recoverChangelog = false;
  var openEditor = false;

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    switch (argument) {
      case 'patch' || 'minor' || 'major':
        if (bumpWasExplicit) {
          errors.writeln('[ERR] Specify the bump kind only once');
          return 1;
        }
        bump = BumpKind.tryParse(argument)!;
        bumpWasExplicit = true;
      case '--bump':
        if (bumpWasExplicit) {
          errors.writeln('[ERR] Specify the bump kind only once');
          return 1;
        }
        index++;
        final kind = index < arguments.length
            ? BumpKind.tryParse(arguments[index])
            : null;
        if (kind == null) {
          errors.writeln('[ERR] --bump requires patch, minor, or major');
          return 1;
        }
        bump = kind;
        bumpWasExplicit = true;
      case '--skip-bump' || '--no-bump':
        skipBump = true;
      case '--carry-changelog' || '--rename-current-changelog':
        carryChangelog = true;
      case '--recover-changelog':
        recoverChangelog = true;
      case '--edit':
        openEditor = true;
      case '--help' || '-h':
        output.writeln(_usage);
        return 0;
      default:
        errors
          ..writeln('[ERR] Unknown argument: $argument')
          ..writeln(_usage);
        return 2;
    }
  }

  return ReleasePrep(
    repoRoot: repoRoot,
    out: output,
    err: errors,
    steps: steps,
    tempRoot: tempRoot,
    environment: environment,
  ).run(
    ReleasePrepOptions(
      bump: bump,
      bumpWasExplicit: bumpWasExplicit,
      skipBump: skipBump,
      carryChangelog: carryChangelog,
      recoverChangelog: recoverChangelog,
      openEditor: openEditor,
    ),
  );
}
