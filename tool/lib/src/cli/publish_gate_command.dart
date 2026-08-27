import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:pub_semver/pub_semver.dart';

import '../core/exceptions.dart';
import '../core/pub_client.dart';
import '../core/publish.dart';
import '../core/version_config.dart';

/// Refuses a release the resolver would not rank above what the host serves.
final class CheckPublishedCommand extends Command<int> {
  CheckPublishedCommand(this.repoRoot);

  final String repoRoot;

  @override
  String get name => 'check-published';

  @override
  String get description =>
      'Verify version.config outranks the published peak of its release line.';

  @override
  Future<int> run() async {
    final target = VersionConfig.forRepo(repoRoot).read();
    stdout.writeln('[INFO] Target version: $target');

    final client = PubClient();
    var blocked = false;

    for (final package in publishOrder) {
      final List<Version> published;
      try {
        published = await client.publishedVersions(package);
      } on PubApiException catch (error) {
        stderr.writeln('[ERR] ${error.message}');
        blocked = true;
        continue;
      }

      final gate = publishGate(
        package: package,
        target: target,
        published: published,
      );
      switch (gate) {
        case PackageUnpublished():
          stdout.writeln('[OK ] $package has no published versions yet');
        case ReleaseLineUnopened():
          stdout.writeln('[OK ] $package opens its release line');
        case AlreadyPublished():
          stderr.writeln(
            '[ERR] $package $target is already published; bump the version '
            'before releasing again',
          );
          blocked = true;
        case RisesAbovePeak(:final peak):
          stdout.writeln('[OK ] $package $target is ranked above $peak');
        case BlockedByPeak(:final peak, :final reason):
          stderr.writeln(
            '[ERR] $package $target is not ranked above the published $peak; '
            'consumers would keep resolving $peak ($reason)',
          );
          blocked = true;
      }
    }

    if (blocked) {
      stderr.writeln(
        '[ERR] Published-version check failed. Pick a version the resolver '
        'orders above the peak of its release line.',
      );
      return 1;
    }
    return 0;
  }
}
