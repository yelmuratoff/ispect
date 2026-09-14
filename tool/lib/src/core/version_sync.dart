import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'exceptions.dart';
import 'next_version.dart';
import 'version_config.dart';

const String _versionConfigPath = 'version.config';
const String _webManifestPath = 'web_logs_viewer/pubspec.yaml';
const String _webLockfilePath = 'web_logs_viewer/pubspec.lock';
const String _tempAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

final RegExp _mappingKey = RegExp(r'^  [^ ]');
final RegExp _topLevelKey = RegExp('^[a-z]');
final RegExp _nestedPathValue = RegExp(r'^    path:\s*\S');
final RegExp _nestedSourceKey = RegExp('^    source:');
final RegExp _nestedVersionKey = RegExp('^    version:');
final RegExp _fieldSeparator = RegExp(r'\s+');

const String _usage = '''
Sync the repository version across every package manifest.

Options:
  --dry-run           Show changes without modifying files
  --bump <kind>       Compute the next semantic version and persist it (patch|minor|major)
  --help              Show this help''';

/// The manifests one sync run reported, in the order it reported them.
final class VersionSyncResult {
  const VersionSyncResult({required this.version, required this.changedFiles});

  /// The version every manifest now carries.
  final Version version;

  /// Repository-relative paths, one entry per reported change. A manifest
  /// whose `version:` line and internal constraints both moved appears twice.
  final List<String> changedFiles;
}

/// Propagates `version.config` to every package manifest, example manifest,
/// and the web demo, including the path-package versions its lockfile pins.
final class VersionSync {
  const VersionSync({
    required this.repoRoot,
    required this.out,
    required this.err,
  });

  final String repoRoot;
  final StringSink out;
  final StringSink err;

  /// The version `version.config` declares, warning when its prerelease
  /// counter is glued to its label.
  ///
  /// Throws [VersionConfigException] when the file is missing or the version
  /// is absent, empty, or not a semantic version.
  Version readVersion() {
    final config = VersionConfig(_file(_versionConfigPath));
    if (!config.file.existsSync()) {
      throw const VersionConfigException('$_versionConfigPath not found');
    }

    final Version version;
    try {
      version = config.read();
    } on VersionConfigException catch (e) {
      throw VersionConfigException(
        e.message.replaceFirst(config.file.path, _versionConfigPath),
      );
    }

    if (hasGluedCounter(version)) {
      err
        ..writeln('[WARN] $version glues its counter to the prerelease label, '
            'so Pub compares that counter as text (dev11 sorts below dev8).')
        ..writeln('[WARN] Further bumps stay monotonic by appending a numeric '
            'identifier; to sort above an already published sibling the series '
            'has to leave this label (rc.1) or the prerelease.');
    }
    return version;
  }

  /// The version a [kind] bump of [current] produces.
  ///
  /// Throws [VersionRegressionException] when Pub would not order the result
  /// above [current].
  Version bump(Version current, BumpKind kind) {
    try {
      return nextVersion(current, kind);
    } on VersionRegressionException catch (e) {
      throw VersionRegressionException(
        next: e.next,
        current: e.current,
        message: '${kind.name} bump of ${e.current} would produce ${e.next}, '
            'which Pub does not order above it',
      );
    }
  }

  /// Rewrites every manifest to [target], persisting [target] to
  /// `version.config` when it differs from [current].
  ///
  /// With [dryRun] the run reports what it would change and writes nothing.
  /// The web lockfile is validated before any file is touched, so a malformed
  /// path stanza aborts the whole run.
  ///
  /// Throws [ManifestException] when a package manifest carries no name, when
  /// `packages/` holds none, or when the web lockfile is missing or malformed.
  VersionSyncResult run({
    required Version current,
    required Version target,
    bool dryRun = false,
  }) {
    out.writeln('[INFO] Target version: $target (dry-run=${dryRun ? 1 : 0})');

    final packageDirectories = _packageDirectories();
    final packageNames = _packageNames(packageDirectories);
    out.writeln('[INFO] Packages: ${packageNames.join(' ')}');

    final changedFiles = <String>[];
    final pendingLockfile =
        _prepareWebLockfile(packageNames, target, changedFiles);

    if (current.toString() != target.toString()) {
      changedFiles.add(_versionConfigPath);
      if (!dryRun) {
        VersionConfig(_file(_versionConfigPath)).write(target);
      }
    }

    for (final directory in packageDirectories) {
      final pubspec = File(p.join(directory, 'pubspec.yaml'));
      if (!pubspec.existsSync()) {
        continue;
      }
      _replaceVersionLine(pubspec, target, dryRun, changedFiles);
      _updateInternalRefs(pubspec, packageNames, target, dryRun, changedFiles);

      final example = File(p.join(directory, 'example', 'pubspec.yaml'));
      if (example.existsSync()) {
        _updateInternalRefs(
            example, packageNames, target, dryRun, changedFiles);
      }
    }

    final webManifest = _file(_webManifestPath);
    if (webManifest.existsSync()) {
      _updateInternalRefs(
        webManifest,
        packageNames,
        target,
        dryRun,
        changedFiles,
      );
    }

    if (pendingLockfile != null && !dryRun) {
      _writeAtomically(_file(_webLockfilePath), pendingLockfile);
    }

    out.writeln('[INFO] Summary:');
    if (changedFiles.isEmpty) {
      out.writeln('  (no file changes)');
    } else {
      for (final file in changedFiles) {
        out.writeln('  - $file');
      }
    }
    out.writeln(
      dryRun ? '[DONE] Dry-run completed' : '[DONE] Version update completed',
    );

    return VersionSyncResult(
      version: target,
      changedFiles: List.unmodifiable(changedFiles),
    );
  }

  List<String> _packageDirectories() {
    final packages = Directory(p.join(repoRoot, 'packages'));
    if (!packages.existsSync()) {
      return const [];
    }
    return packages
        .listSync()
        .whereType<Directory>()
        .map((directory) => directory.path)
        .toList()
      ..sort();
  }

  List<String> _packageNames(List<String> directories) {
    final names = <String>[];
    for (final directory in directories) {
      final pubspec = File(p.join(directory, 'pubspec.yaml'));
      if (!pubspec.existsSync()) {
        continue;
      }
      final name = _firstFieldValue(pubspec.readAsLinesSync(), 'name:');
      if (name.isEmpty) {
        final relative = _relative(pubspec);
        throw ManifestException('Package name not found in $relative');
      }
      names.add(name);
    }
    if (names.isEmpty) {
      throw const ManifestException('No package pubspecs found');
    }
    return names;
  }

  String? _prepareWebLockfile(
    List<String> packageNames,
    Version target,
    List<String> changedFiles,
  ) {
    final manifest = _file(_webManifestPath);
    if (!manifest.existsSync()) {
      return null;
    }

    final manifestLines = manifest.readAsLinesSync();
    final pathPackages = packageNames
        .where((name) => _hasLocalPathRef(manifestLines, name))
        .toList();
    if (pathPackages.isEmpty) {
      return null;
    }

    final lockfile = _file(_webLockfilePath);
    if (!lockfile.existsSync()) {
      throw const ManifestException(
        '$_webLockfilePath is required for local web path dependencies',
      );
    }

    final original = lockfile.readAsStringSync();
    var contents = original;
    for (final name in pathPackages) {
      if (!_hasSinglePathStanza(contents, name)) {
        throw ManifestException(
          'Invalid path package stanza in $_webLockfilePath: $name',
        );
      }
      contents = _rewriteLockfileVersion(contents, name, target);
    }

    if (contents == original) {
      out.writeln(
        '[OK ] $_webLockfilePath path package versions already $target',
      );
      return null;
    }
    out.writeln('[CHG] $_webLockfilePath path package versions -> $target');
    changedFiles.add(_webLockfilePath);
    return contents;
  }

  bool _hasLocalPathRef(List<String> lines, String packageName) {
    final header = '  $packageName:';
    var inPackage = false;
    var found = false;
    for (final line in lines) {
      if (line == header) {
        inPackage = true;
        continue;
      }
      if (inPackage && _mappingKey.hasMatch(line)) {
        inPackage = false;
      }
      if (inPackage && _nestedPathValue.hasMatch(line)) {
        found = true;
      }
    }
    return found;
  }

  bool _hasSinglePathStanza(String contents, String packageName) {
    final header = '  $packageName:';
    var inStanza = false;
    var stanzas = 0;
    var sources = 0;
    var pathSources = 0;
    var versions = 0;

    for (final line in _splitLines(contents)) {
      if (line == header) {
        stanzas++;
        inStanza = true;
        continue;
      }
      if (inStanza && _mappingKey.hasMatch(line)) {
        inStanza = false;
      }
      if (inStanza && _nestedSourceKey.hasMatch(line)) {
        sources++;
        final fields = _fields(line);
        final source = (fields.length > 1 ? fields[1] : '').replaceAll('"', '');
        if (source == 'path') {
          pathSources++;
        }
      }
      if (inStanza && _nestedVersionKey.hasMatch(line)) {
        versions++;
      }
    }

    return stanzas == 1 && sources == 1 && pathSources == 1 && versions == 1;
  }

  String _rewriteLockfileVersion(
    String contents,
    String packageName,
    Version target,
  ) {
    final header = '  $packageName:';
    var inStanza = false;
    final rewritten = <String>[];

    for (final line in _splitLines(contents)) {
      if (line == header) {
        inStanza = true;
        rewritten.add(line);
        continue;
      }
      if (inStanza && _mappingKey.hasMatch(line)) {
        inStanza = false;
      }
      if (inStanza && _nestedVersionKey.hasMatch(line)) {
        rewritten.add('    version: "$target"');
        continue;
      }
      rewritten.add(line);
    }
    return _joinAlwaysTerminated(rewritten);
  }

  void _replaceVersionLine(
    File file,
    Version target,
    bool dryRun,
    List<String> changedFiles,
  ) {
    final relative = _relative(file);
    final contents = file.readAsStringSync();
    final lines = _splitLines(contents);
    final current = _firstFieldValue(lines, 'version:');

    if (current == target.toString()) {
      out.writeln('[OK ] $relative already $target');
      return;
    }

    out.writeln('[CHG] $relative version $current -> $target');
    if (!dryRun) {
      final rewritten = [
        for (final line in lines)
          if (line.startsWith('version:')) 'version: $target' else line,
      ];
      _writeAtomically(file, _joinPreservingTermination(rewritten, contents));
    }
    changedFiles.add(relative);
  }

  void _updateInternalRefs(
    File file,
    List<String> packageNames,
    Version target,
    bool dryRun,
    List<String> changedFiles,
  ) {
    final relative = _relative(file);
    var contents = file.readAsStringSync();
    var updated = false;

    for (final packageName in packageNames) {
      final prefix = '  $packageName: ^';
      final expected = '$prefix$target';
      final lines = _splitLines(contents);

      if (!lines.any((line) => line.startsWith(prefix))) {
        continue;
      }
      if (lines.any((line) => line == expected)) {
        continue;
      }

      out.writeln('[CHG] $relative -> $packageName ^$target');
      updated = true;
      if (dryRun) {
        continue;
      }

      var inDependencies = false;
      final rewritten = <String>[];
      for (final line in lines) {
        if (_topLevelKey.hasMatch(line)) {
          inDependencies = false;
        }
        if (line.startsWith('dependencies:') ||
            line.startsWith('dev_dependencies:')) {
          inDependencies = true;
        }
        rewritten.add(
          inDependencies && line.startsWith(prefix) ? expected : line,
        );
      }

      contents = _joinAlwaysTerminated(rewritten);
      _writeAtomically(file, contents);
    }

    if (updated) {
      changedFiles.add(relative);
    }
  }

  void _writeAtomically(File file, String contents) {
    final temp = _createTemp(file);
    try {
      file.copySync(temp.path);
      temp.writeAsStringSync(contents);
      temp.renameSync(file.path);
    } on Object {
      if (temp.existsSync()) {
        temp.deleteSync();
      }
      rethrow;
    }
  }

  File _createTemp(File file) {
    final random = Random();
    while (true) {
      final suffix = String.fromCharCodes([
        for (var index = 0; index < 6; index++)
          _tempAlphabet.codeUnitAt(random.nextInt(_tempAlphabet.length)),
      ]);
      final candidate = File('${file.path}.tmp.$suffix');
      if (!candidate.existsSync()) {
        return candidate;
      }
    }
  }

  File _file(String relativePath) => File(p.join(repoRoot, relativePath));

  String _relative(File file) => p.relative(file.path, from: repoRoot);
}

/// Parses [arguments] and runs the sync, returning the process exit code.
///
/// Accepts `--dry-run`, `--bump <patch|minor|major>`, and `--help`. Returns 2
/// for an argument the sync does not accept and 1 for a failure it reports.
int runVersionSync({
  required String repoRoot,
  required List<String> arguments,
  StringSink? out,
  StringSink? err,
}) {
  final output = out ?? stdout;
  final errors = err ?? stderr;
  final sync = VersionSync(repoRoot: repoRoot, out: output, err: errors);

  try {
    final current = sync.readVersion();

    var dryRun = false;
    String? bumpKind;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      switch (argument) {
        case '--dry-run':
          dryRun = true;
        case '--bump':
          index++;
          if (index >= arguments.length || arguments[index].isEmpty) {
            errors.writeln('[ERR] --bump requires patch, minor, or major');
            return 2;
          }
          bumpKind = arguments[index];
        case '--help' || '-h':
          output.writeln('$_usage\nCurrent VERSION: $current');
          return 0;
        default:
          errors.writeln('[ERR] Unknown argument: $argument');
          output.writeln('$_usage\nCurrent VERSION: $current');
          return 2;
      }
    }

    var target = current;
    if (bumpKind != null) {
      final kind = BumpKind.tryParse(bumpKind);
      if (kind == null) {
        errors.writeln('[ERR] Unknown bump kind: $bumpKind');
        return 1;
      }
      target = sync.bump(current, kind);
      output.writeln('[INFO] Bump ${kind.name}: $current -> $target');
    }

    sync.run(current: current, target: target, dryRun: dryRun);
    return 0;
  } on ToolException catch (e) {
    errors.writeln('[ERR] ${e.message}');
    return 1;
  }
}

List<String> _splitLines(String contents) {
  final lines = contents.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

String _joinAlwaysTerminated(List<String> lines) =>
    lines.map((line) => '$line\n').join();

String _joinPreservingTermination(List<String> lines, String original) =>
    lines.join('\n') + (original.endsWith('\n') ? '\n' : '');

List<String> _fields(String line) {
  final trimmed = line.trim();
  return trimmed.isEmpty ? const [] : trimmed.split(_fieldSeparator);
}

String _firstFieldValue(List<String> lines, String key) {
  for (final line in lines) {
    final fields = _fields(line);
    if (fields.isEmpty || fields.first != key) {
      continue;
    }
    return fields.length > 1 ? fields[1] : '';
  }
  return '';
}
