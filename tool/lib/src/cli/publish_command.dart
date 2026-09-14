import 'package:args/command_runner.dart';

import 'argv.dart';

import '../core/publish.dart';

/// Publishes every package in dependency order, after refusing to start on a
/// repository that is not in a releasable state.
final class PublishCommand extends Command<int> {
  PublishCommand(this.repoRoot) {
    argParser
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Stop after the dry-run of every package.',
      )
      ..addFlag(
        'auto',
        negatable: false,
        help: 'Publish without asking; overridden by --dry-run.',
      )
      ..addMultiOption(
        'only',
        valueHelp: 'package',
        allowed: publishOrder,
        splitCommas: false,
        help: 'Limit the run to the named package; repeatable.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Print the full dry-run output of every package.',
      )
      ..addFlag(
        'skip-pub-version-check',
        negatable: false,
        help: 'Do not ask the host which versions it already serves.',
      );
  }

  final String repoRoot;

  @override
  String get name => 'publish';

  @override
  String get description =>
      'Publish every package in dependency order, preflights first.';

  @override
  String get invocation => 'ispect_tool publish [--dry-run|--auto] [options]';

  @override
  Future<int> run() => runPublish(
      repoRoot: repoRoot,
      arguments: normalizeOptionValues(argResults!.arguments));
}
