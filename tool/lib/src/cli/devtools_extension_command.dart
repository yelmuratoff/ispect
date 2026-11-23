import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ispect_tool/src/core/devtools_extension.dart';
import 'package:ispect_tool/src/core/flutter_sdk.dart';
import 'package:ispect_tool/src/core/publish.dart';

/// Builds the DevTools extension into
/// `packages/ispect_devtools/extension/devtools`.
final class DevToolsExtensionCommand extends Command<int> {
  DevToolsExtensionCommand(this.repoRoot, {ProcessRunner? runner})
      : _runner = runner ?? PinnedFlutterRunner.forRepo(repoRoot);

  final String repoRoot;
  final ProcessRunner _runner;

  @override
  String get name => 'devtools-extension';

  @override
  String get description =>
      'Build the ISpect DevTools extension into packages/ispect_devtools/'
      'extension/devtools/build. Publishing ispect_devtools runs this first.';

  @override
  Future<int> run() async {
    final failure = buildDevToolsExtension(repoRoot: repoRoot, runner: _runner);
    if (failure != null) {
      stderr
        ..writeln('[ERR] DevTools extension build failed')
        ..write(failure.output);
      return 1;
    }
    stdout.writeln('[DONE] DevTools extension built');
    return 0;
  }
}
