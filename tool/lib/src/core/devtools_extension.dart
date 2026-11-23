import 'dart:io';

import 'package:path/path.dart' as p;

import 'publish.dart';

/// The package whose pub archive carries the ISpect DevTools extension.
const String devToolsExtensionHost = 'ispect_devtools';

/// The Flutter web app the DevTools extension is built from.
const String devToolsExtensionSource = 'ispect_devtools_extension';

/// Builds the DevTools extension and copies it to
/// `packages/ispect_devtools/extension/devtools/build`, where DevTools loads
/// it from.
///
/// The app is compiled with `ISPECT_ENABLED` because it renders logs through
/// an ISpect logger, which the compile gate otherwise disables. Returns the
/// failing step's result, or `null` when the build is in place.
CommandResult? buildDevToolsExtension({
  required String repoRoot,
  required ProcessRunner runner,
}) {
  final source = p.join(repoRoot, devToolsExtensionSource);
  if (!File(p.join(source, 'pubspec.yaml')).existsSync()) {
    return CommandResult(
      exitCode: 1,
      output: 'DevTools extension source not found at $source\n',
    );
  }
  const steps = [
    ['pub', 'get'],
    [
      'build',
      'web',
      '--pwa-strategy=offline-first',
      '--release',
      '--no-tree-shake-icons',
      '--dart-define=ISPECT_ENABLED=true',
    ],
  ];
  for (final arguments in steps) {
    final result = runner.run('flutter', arguments, workingDirectory: source);
    if (!result.succeeded) return result;
  }

  final built = Directory(p.join(source, 'build', 'web'));
  if (!built.existsSync()) {
    return CommandResult(
      exitCode: 1,
      output: 'flutter build web produced no build/web in $source\n',
    );
  }
  final destination = Directory(
    p.join(
      repoRoot,
      'packages',
      devToolsExtensionHost,
      'extension',
      'devtools',
      'build',
    ),
  );
  if (destination.existsSync()) destination.deleteSync(recursive: true);
  _copyDirectory(built, destination);
  return null;
}

void _copyDirectory(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync(followLinks: false)) {
    final target = p.join(to.path, p.basename(entity.path));
    switch (entity) {
      case Directory():
        _copyDirectory(entity, Directory(target));
      case File():
        entity.copySync(target);
      default:
        break;
    }
  }
}
