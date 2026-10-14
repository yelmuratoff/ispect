import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/pub_client.dart';
import '../core/publish.dart';
import '../core/version_config.dart';

/// Refuses a release the resolver would not rank above what the host serves.
final class CheckPublishedCommand extends Command<int> {
  CheckPublishedCommand(
    this.repoRoot, {
    PublishedVersionsReader? publishedVersions,
  }) : publishedVersions = publishedVersions ??
            ((package) => PubClient().publishedVersions(package));

  final String repoRoot;
  final PublishedVersionsReader publishedVersions;

  @override
  String get name => 'check-published';

  @override
  String get description =>
      'Verify version.config outranks the published peak of its release line.';

  @override
  Future<int> run() async {
    final target = VersionConfig.forRepo(repoRoot).read();
    stdout.writeln('[INFO] Target version: $target');

    final gates = await gateRelease(
      packages: publishOrder,
      target: target,
      publishedVersions: publishedVersions,
    );
    return reportReleaseGates(
      gates,
      info: (message) => stdout.writeln('[OK ] $message'),
      error: (message) => stderr.writeln('[ERR] $message'),
    );
  }
}
