import 'dart:io';

import 'package:path/path.dart' as p;

import 'exceptions.dart';
import 'version_config.dart';

const String _sourceDirName = 'docs/readme';
const String _partialsDirName = '_partials';
const int _maxPartialDepth = 16;

const String _red = '\x1B[0;31m';
const String _green = '\x1B[0;32m';
const String _yellow = '\x1B[1;33m';
const String _blue = '\x1B[0;34m';
const String _reset = '\x1B[0m';

const String _posixSpace = r'[\t\n\v\f\r ]';

final RegExp _partialMarker = RegExp(
  '^$_posixSpace*<!--$_posixSpace*partial:([A-Za-z0-9_]+)$_posixSpace*-->'
  '$_posixSpace*\$',
);
final RegExp _trailingNewlines = RegExp(r'\n+$');

const String _usage = '''
Assemble every package README from docs/readme/ sources.

Sources live in docs/readme/:
  <package>.md      body for each package
  root.md           body for the repo-root README.md
  _partials/*.md    reusable fragments

Markers handled during build:
  <!-- partial:NAME -->   replaced by docs/readme/_partials/NAME.md
  {{version}}             VERSION from version.config
  {{package}}             target package name (root uses "ispect")

Options:
  --check           Verify generated files are up to date (CI)
  --dry-run         Show what would change without writing
  --package <name>  Rebuild a single target
  --help            Show this help

Exit codes:
  0  success (or --check with no drift)
  1  drift detected in --check mode
  2  usage / configuration error''';

/// What one run does with the READMEs it renders.
enum ReadmeMode {
  /// Render every target and write it to disk.
  build,

  /// Render every target and compare it against the file already on disk.
  check,

  /// Render every target and report what writing it would change.
  dryRun,
}

/// One generated README: which source builds it, where it lands, and which
/// package name `{{package}}` resolves to.
final class ReadmeTarget {
  const ReadmeTarget({
    required this.sourceName,
    required this.outputPath,
    required this.packageName,
  });

  /// Base name of the source under `docs/readme/`, without the extension.
  final String sourceName;

  /// Repository-relative path of the generated README.
  final String outputPath;

  /// Value substituted for `{{package}}`.
  final String packageName;

  /// Short name used in progress output; the repo-root README reads `<root>`.
  String get label =>
      outputPath == 'README.md' ? '<root>' : p.basename(p.dirname(outputPath));
}

/// Every README the repository generates, in the order runs report them.
const List<ReadmeTarget> readmeTargets = [
  ReadmeTarget(
    sourceName: 'root',
    outputPath: 'README.md',
    packageName: 'ispect',
  ),
  ReadmeTarget(
    sourceName: 'ispect',
    outputPath: 'packages/ispect/README.md',
    packageName: 'ispect',
  ),
  ReadmeTarget(
    sourceName: 'ispect_layout',
    outputPath: 'packages/ispect_layout/README.md',
    packageName: 'ispect_layout',
  ),
  ReadmeTarget(
    sourceName: 'ispectify',
    outputPath: 'packages/ispectify/README.md',
    packageName: 'ispectify',
  ),
  ReadmeTarget(
    sourceName: 'ispectify_bloc',
    outputPath: 'packages/ispectify_bloc/README.md',
    packageName: 'ispectify_bloc',
  ),
  ReadmeTarget(
    sourceName: 'ispectify_db',
    outputPath: 'packages/ispectify_db/README.md',
    packageName: 'ispectify_db',
  ),
  ReadmeTarget(
    sourceName: 'ispectify_dio',
    outputPath: 'packages/ispectify_dio/README.md',
    packageName: 'ispectify_dio',
  ),
  ReadmeTarget(
    sourceName: 'ispectify_http',
    outputPath: 'packages/ispectify_http/README.md',
    packageName: 'ispectify_http',
  ),
  ReadmeTarget(
    sourceName: 'ispectify_riverpod',
    outputPath: 'packages/ispectify_riverpod/README.md',
    packageName: 'ispectify_riverpod',
  ),
  ReadmeTarget(
    sourceName: 'ispectify_ws',
    outputPath: 'packages/ispectify_ws/README.md',
    packageName: 'ispectify_ws',
  ),
];

/// What one README run reported.
final class ReadmeBuildResult {
  const ReadmeBuildResult({
    required this.mode,
    required this.matched,
    required this.drifted,
    required this.written,
  });

  /// The mode the run executed.
  final ReadmeMode mode;

  /// Targets the run considered after applying any `--package` filter.
  final int matched;

  /// Labels of targets whose file on disk disagrees with the render. Always
  /// empty outside [ReadmeMode.check].
  final List<String> drifted;

  /// Repository-relative paths the run wrote. Always empty outside
  /// [ReadmeMode.build].
  final List<String> written;
}

/// Renders the generated READMEs from `docs/readme/` templates.
///
/// A run resolves every target before it writes any of them, so a template
/// that cannot be expanded leaves the working tree untouched.
final class ReadmeBuilder {
  const ReadmeBuilder({
    required this.repoRoot,
    required this.out,
    required this.err,
  });

  final String repoRoot;
  final StringSink out;
  final StringSink err;

  /// The version `version.config` declares.
  ///
  /// `pub_semver` renders a parsed version back to the text it was written as,
  /// so substituting this into a template stays byte-identical to the file.
  ///
  /// Throws [VersionConfigException] when the file is missing, declares no
  /// `VERSION=`, or declares one that is not a semantic version.
  String readVersion() => VersionConfig.forRepo(repoRoot).read().toString();

  /// The full text of [target]'s README, banner included.
  ///
  /// Throws [DocsSourceException] when the source template is missing and
  /// [PartialResolutionException] when a marker cannot be expanded.
  String render(ReadmeTarget target, String version) {
    final source = File(
      p.join(repoRoot, _sourceDirName, '${target.sourceName}.md'),
    );
    if (!source.existsSync()) {
      throw DocsSourceException('source missing: ${source.path}');
    }

    final body = _expand(source, 0)
        .replaceAll('{{version}}', version)
        .replaceAll('{{package}}', target.packageName);

    final rendered = StringBuffer()
      ..writeln('<!--')
      ..writeln('  GENERATED FILE — do not edit by hand.')
      ..writeln('  Source:     $_sourceDirName/${target.sourceName}.md')
      ..writeln('  Regenerate: ./bash/build_readme.sh')
      ..writeln('-->')
      ..writeln()
      ..write(body);

    return '${rendered.toString().replaceAll(_trailingNewlines, '')}\n';
  }

  /// Renders every target [packageFilter] selects and applies [mode] to it.
  ///
  /// Throws [DocsSourceException] when `docs/readme/` or a template is
  /// missing, [PartialResolutionException] when a marker cannot be expanded,
  /// and [VersionConfigException] when the version cannot be read.
  ReadmeBuildResult run({
    required ReadmeMode mode,
    String? packageFilter,
  }) {
    final version = readVersion();

    final sourceDir = Directory(p.join(repoRoot, _sourceDirName));
    if (!sourceDir.existsSync()) {
      throw DocsSourceException('source directory missing: ${sourceDir.path}');
    }

    final targets = [
      for (final target in readmeTargets)
        if (packageFilter == null ||
            target.packageName == packageFilter ||
            target.sourceName == packageFilter)
          target,
    ];
    if (packageFilter != null && targets.isEmpty) {
      throw DocsSourceException('no target matches --package $packageFilter');
    }

    switch (mode) {
      case ReadmeMode.check:
        out.writeln(
          '${_yellow}Checking generated READMEs against sources…$_reset',
        );
      case ReadmeMode.dryRun:
        out.writeln('${_yellow}Dry run — no files will be written.$_reset');
      case ReadmeMode.build:
        out.writeln('${_yellow}Building READMEs (version $version)…$_reset');
    }
    out.writeln();

    final rendered = {
      for (final target in targets) target.outputPath: render(target, version),
    };

    final drifted = <String>[];
    final written = <String>[];
    for (final target in targets) {
      final absolute = p.join(repoRoot, target.outputPath);
      final contents = rendered[target.outputPath]!;

      switch (mode) {
        case ReadmeMode.check:
          final existing = File(absolute);
          if (!existing.existsSync()) {
            out.writeln('$_red✗$_reset ${target.label} — missing '
                '(expected generated README at $absolute)');
            drifted.add(target.label);
            continue;
          }
          final actual = stripReadmeBanner(existing.readAsStringSync());
          final expected = stripReadmeBanner(contents);
          if (actual == expected) {
            out.writeln('$_green✓$_reset ${target.label}');
            continue;
          }
          out.writeln('$_red✗$_reset ${target.label} — drift detected');
          _writeDiff(expected: expected, actual: actual);
          drifted.add(target.label);
        case ReadmeMode.dryRun:
          final lines = contents.replaceAll(_trailingNewlines, '').split('\n');
          out.writeln(
            '${_blue}would write$_reset $absolute (${lines.length} lines)',
          );
        case ReadmeMode.build:
          File(absolute).writeAsStringSync(contents);
          out.writeln('$_green✓$_reset ${target.label} → $absolute');
          written.add(target.outputPath);
      }
    }

    out.writeln();
    switch (mode) {
      case ReadmeMode.check:
        if (drifted.isNotEmpty) {
          out.writeln('${_red}README drift detected in ${drifted.length} '
              'target(s). Run ./bash/build_readme.sh to sync.$_reset');
        } else {
          out.writeln('${_green}All generated READMEs are up to date.$_reset');
        }
      case ReadmeMode.dryRun:
        out.writeln('${_blue}Dry run complete.$_reset');
      case ReadmeMode.build:
        out.writeln('${_green}Built ${targets.length} README(s).$_reset');
    }

    return ReadmeBuildResult(
      mode: mode,
      matched: targets.length,
      drifted: List.unmodifiable(drifted),
      written: List.unmodifiable(written),
    );
  }

  String _expand(File source, int depth) {
    if (depth > _maxPartialDepth) {
      throw PartialResolutionException(
        'partial recursion too deep (>$_maxPartialDepth) while processing '
        '${source.path}',
        partialName: p.basenameWithoutExtension(source.path),
      );
    }

    final buffer = StringBuffer();
    var pendingSeparator = false;

    for (final line in _splitLines(source.readAsStringSync())) {
      final marker = _partialMarker.firstMatch(line);
      if (marker != null) {
        final name = marker.group(1)!;
        final partial = File(
          p.join(repoRoot, _sourceDirName, _partialsDirName, '$name.md'),
        );
        if (!partial.existsSync()) {
          throw PartialResolutionException(
            "unknown partial '$name' referenced in ${source.path}",
            partialName: name,
          );
        }
        final expanded = _expand(partial, depth + 1);
        buffer.write(expanded);
        pendingSeparator = !expanded.endsWith('\n\n');
        continue;
      }

      if (pendingSeparator) {
        if (line.isNotEmpty) {
          buffer.writeln();
        }
        pendingSeparator = false;
      }
      buffer.writeln(line);
    }

    if (pendingSeparator) {
      buffer.writeln();
    }
    return buffer.toString();
  }

  void _writeDiff({required String expected, required String actual}) {
    final expectedLines = _splitLines(expected);
    final actualLines = _splitLines(actual);
    final length = expectedLines.length > actualLines.length
        ? expectedLines.length
        : actualLines.length;

    var reported = 0;
    for (var index = 0; index < length && reported < 20; index++) {
      final onDisk = index < actualLines.length ? actualLines[index] : null;
      final fromSource =
          index < expectedLines.length ? expectedLines[index] : null;
      if (onDisk == fromSource) {
        continue;
      }
      if (onDisk != null) {
        out.writeln('-$onDisk');
      }
      if (fromSource != null) {
        out.writeln('+$fromSource');
      }
      reported++;
    }
  }
}

/// [contents] without its generated-file banner and the blank line after it.
///
/// Returns [contents] unchanged when it carries no banner. Unlike the bash
/// implementation this keys off the banner's closing `-->` rather than a fixed
/// line offset, so the first line of real content stays part of the
/// comparison.
String stripReadmeBanner(String contents) {
  final lines = _splitLines(contents);
  if (lines.isEmpty || lines.first != '<!--') {
    return contents;
  }
  final close = lines.indexOf('-->');
  if (close == -1) {
    return contents;
  }
  var start = close + 1;
  if (start < lines.length && lines[start].isEmpty) {
    start++;
  }
  return lines.skip(start).map((line) => '$line\n').join();
}

/// Parses [arguments], renders the READMEs, and returns the process exit code.
///
/// Accepts `--check`, `--dry-run`, `--package <name>`, and `--help`. Returns 1
/// when `--check` finds drift and 2 for a usage or configuration failure.
int runReadmeBuild({
  required String repoRoot,
  required List<String> arguments,
  StringSink? out,
  StringSink? err,
}) {
  final output = out ?? stdout;
  final errors = err ?? stderr;

  var mode = ReadmeMode.build;
  String? packageFilter;

  for (var index = 0; index < arguments.length; index++) {
    switch (arguments[index]) {
      case '--check':
        mode = ReadmeMode.check;
      case '--dry-run':
        mode = ReadmeMode.dryRun;
      case '--package':
        index++;
        if (index >= arguments.length) {
          errors.writeln('${_red}error: --package requires a name$_reset');
          return 2;
        }
        packageFilter = arguments[index];
      case '--help' || '-h':
        output.writeln(_usage);
        return 2;
      default:
        errors.writeln('${_red}Unknown option: ${arguments[index]}$_reset');
        output.writeln(_usage);
        return 2;
    }
  }

  final builder = ReadmeBuilder(repoRoot: repoRoot, out: output, err: errors);
  try {
    final result = builder.run(mode: mode, packageFilter: packageFilter);
    return result.drifted.isEmpty ? 0 : 1;
  } on ToolException catch (e) {
    errors.writeln('${_red}error: ${e.message}$_reset');
    return 2;
  }
}

List<String> _splitLines(String contents) {
  final lines = contents.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}
