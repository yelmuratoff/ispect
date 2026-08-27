import 'dart:io';

import 'package:path/path.dart' as p;

import 'exceptions.dart';

const String _rootChangelogPath = 'CHANGELOG.md';
const String _headingPrefix = '## ';

const String _usage = '''
update_changelog - propagate changelog entries to packages

Options:
    --full-copy        Overwrite each package CHANGELOG with the root one
    --yes              Don't ask for confirmation when using --full-copy
    --version <ver>    Only propagate (or append) a specific version section
    --help             Show this help

Default (no flags): propagate ONLY the most recent version section (safe).''';

/// How a run propagates the root changelog into the package changelogs.
enum ChangelogMode {
  /// Append the target version's section to packages that lack it.
  appendSection,

  /// Replace each package changelog with the root changelog.
  fullCopy,
}

/// Answers a destructive-write prompt, returning true to proceed.
typedef ChangelogConfirm = bool Function(String prompt);

/// What one propagation run reported.
final class ChangelogResult {
  const ChangelogResult({
    required this.version,
    required this.appended,
    required this.overwritten,
    required this.skipped,
    required this.missing,
    required this.aborted,
  });

  /// The version section the run propagated.
  final String version;

  /// Repository-relative changelogs that gained the section.
  final List<String> appended;

  /// Repository-relative changelogs replaced wholesale.
  final List<String> overwritten;

  /// Repository-relative changelogs that already carried the section.
  final List<String> skipped;

  /// Repository-relative changelogs expected but absent.
  final List<String> missing;

  /// Whether the operator declined a `--full-copy` prompt.
  final bool aborted;
}

/// Propagates a version section from the root `CHANGELOG.md` to every package
/// changelog.
final class ChangelogPropagator {
  const ChangelogPropagator({
    required this.repoRoot,
    required this.out,
    required this.err,
  });

  final String repoRoot;
  final StringSink out;
  final StringSink err;

  /// The version of the topmost `## ` heading in the root changelog.
  ///
  /// Reads the first whitespace-delimited token after the heading marker, so
  /// `## 1.2.3 - 2026-01-01` yields `1.2.3`.
  ///
  /// Throws [ChangelogException] when the root changelog is missing or holds
  /// no version heading.
  String latestVersion() {
    for (final line in _splitLines(_rootChangelog().readAsStringSync())) {
      if (!line.startsWith(_headingPrefix)) {
        continue;
      }
      final rest = line.substring(_headingPrefix.length).trimLeft();
      final token = rest.split(' ').first;
      if (token.isNotEmpty) {
        return token;
      }
    }
    throw const ChangelogException(
      'No version heading found in root $_rootChangelogPath',
    );
  }

  /// The root changelog's section for [version], heading line included.
  ///
  /// The section runs to the next `## ` heading, with trailing blank lines
  /// removed. Matching requires the heading line to read exactly
  /// `## <version>`.
  ///
  /// Throws [ChangelogException] when no heading starts with `## <version>`,
  /// or when one does but no heading matches it exactly.
  String extractSection(String version) {
    final lines = _splitLines(_rootChangelog().readAsStringSync());
    final heading = '$_headingPrefix$version';

    if (!lines.any((line) => line.startsWith(heading))) {
      throw ChangelogException(
        'Version $version not found in root CHANGELOG',
      );
    }

    final section = <String>[];
    var inSection = false;
    for (final line in lines) {
      if (line.startsWith(_headingPrefix)) {
        if (inSection) {
          break;
        }
        if (line == heading) {
          inSection = true;
        }
      }
      if (inSection) {
        section.add(line);
      }
    }

    while (section.isNotEmpty && section.last.isEmpty) {
      section.removeLast();
    }
    if (section.isEmpty) {
      throw ChangelogException('Could not extract section for $version');
    }
    return section.join('\n');
  }

  /// Propagates [version] (or the newest section) into every package
  /// changelog.
  ///
  /// In [ChangelogMode.fullCopy] the run asks [confirm] before replacing any
  /// file and reports an aborted result when it declines.
  ///
  /// Throws [ChangelogException] when the root changelog is missing, or when
  /// the requested version has no extractable section.
  ChangelogResult run({
    ChangelogMode mode = ChangelogMode.appendSection,
    String? version,
    ChangelogConfirm? confirm,
  }) {
    final root = _rootChangelog();
    final target = version ?? latestVersion();
    final block = extractSection(target);

    out.writeln('[INFO] Root version target: $target');

    if (mode == ChangelogMode.fullCopy) {
      final proceed = confirm?.call(
            'This will overwrite all package CHANGELOG.md files',
          ) ??
          false;
      if (!proceed) {
        out.writeln('Aborted');
        return ChangelogResult(
          version: target,
          appended: const [],
          overwritten: const [],
          skipped: const [],
          missing: const [],
          aborted: true,
        );
      }
    }

    final appended = <String>[];
    final overwritten = <String>[];
    final skipped = <String>[];
    final missing = <String>[];

    for (final directory in _packageDirectories()) {
      final changelog = File(p.join(directory, _rootChangelogPath));
      final relative = _relative(changelog.path);

      if (!changelog.existsSync()) {
        out.writeln('[MISS] $relative (skipping)');
        missing.add(relative);
        continue;
      }

      if (mode == ChangelogMode.fullCopy) {
        changelog.writeAsStringSync(root.readAsStringSync());
        out.writeln('[OK] Overwrote $relative');
        overwritten.add(relative);
        continue;
      }

      final heading = '$_headingPrefix$target';
      final hasSection = _splitLines(changelog.readAsStringSync())
          .any((line) => line.startsWith(heading));
      if (hasSection) {
        out.writeln('[SKIP] $relative already has $target');
        skipped.add(relative);
        continue;
      }

      changelog.writeAsStringSync('\n$block\n', mode: FileMode.append);
      out.writeln('[OK] Appended $target to $relative');
      appended.add(relative);
    }

    out.writeln('[DONE] Changelog propagation complete');

    return ChangelogResult(
      version: target,
      appended: List.unmodifiable(appended),
      overwritten: List.unmodifiable(overwritten),
      skipped: List.unmodifiable(skipped),
      missing: List.unmodifiable(missing),
      aborted: false,
    );
  }

  File _rootChangelog() {
    final file = File(p.join(repoRoot, _rootChangelogPath));
    if (!file.existsSync()) {
      throw const ChangelogException('Root $_rootChangelogPath not found');
    }
    return file;
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

  String _relative(String path) => p.relative(path, from: repoRoot);
}

/// Parses [arguments], propagates the changelog, and returns the exit code.
///
/// Accepts `--full-copy`, `--yes`, `--version <ver>`, and `--help`. Returns 1
/// for a failure it reports and 2 for an argument it does not accept. Without
/// [confirm] a `--full-copy` run requires `--yes`.
int runChangelogPropagation({
  required String repoRoot,
  required List<String> arguments,
  StringSink? out,
  StringSink? err,
  ChangelogConfirm? confirm,
}) {
  final output = out ?? stdout;
  final errors = err ?? stderr;

  var mode = ChangelogMode.appendSection;
  var forceYes = false;
  String? version;

  for (var index = 0; index < arguments.length; index++) {
    switch (arguments[index]) {
      case '--full-copy':
        mode = ChangelogMode.fullCopy;
      case '--yes':
        forceYes = true;
      case '--version':
        index++;
        if (index < arguments.length && arguments[index].isNotEmpty) {
          version = arguments[index];
        }
      case '--help' || '-h':
        output.writeln(_usage);
        return 0;
      default:
        errors.writeln('Unknown arg: ${arguments[index]}');
        output.writeln(_usage);
        return 2;
    }
  }

  final propagator = ChangelogPropagator(
    repoRoot: repoRoot,
    out: output,
    err: errors,
  );

  try {
    propagator.run(
      mode: mode,
      version: version,
      confirm: forceYes ? _alwaysConfirm : confirm,
    );
    return 0;
  } on ToolException catch (e) {
    errors.writeln('[ERR] ${e.message}');
    return 1;
  }
}

bool _alwaysConfirm(String prompt) => true;

List<String> _splitLines(String contents) {
  final lines = contents.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}
