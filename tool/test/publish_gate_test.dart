@TestOn('vm')
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ispect_tool/src/cli/publish_command.dart';
import 'package:ispect_tool/src/cli/publish_gate_command.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/pub_client.dart';
import 'package:ispect_tool/src/core/publish.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'captured_stdout.dart';

final Version _target = Version.parse('7.1.0-dev.2');

PublishedVersionsReader _serving(Map<String, List<String>> published) =>
    (package) async {
      if (!published.containsKey(package)) {
        throw PubApiException(
          'https://pub.dev/api/packages/$package answered 503',
          package: package,
          statusCode: 503,
        );
      }
      return published[package]!.map(Version.parse).toList();
    };

void main() {
  group('gateRelease', () {
    test('judges every package in the order it is given', () async {
      final gates = await gateRelease(
        packages: const ['a', 'b', 'c', 'd', 'e'],
        target: _target,
        publishedVersions: _serving({
          'a': [],
          'b': ['7.0.0'],
          'c': ['7.1.0-dev.1'],
          'd': ['7.1.0-dev.2'],
          'e': ['7.1.0-dev.3'],
        }),
      );

      expect(gates.map((gate) => gate.package), ['a', 'b', 'c', 'd', 'e']);
      expect(gates[0], isA<PackageUnpublished>());
      expect(gates[1], isA<ReleaseLineUnopened>());
      expect(gates[2], isA<RisesAbovePeak>());
      expect(gates[3], isA<AlreadyPublished>());
      expect(gates[4], isA<BlockedByPeak>());
    });

    test('a host that leaves one package unanswered still judges the rest',
        () async {
      final gates = await gateRelease(
        packages: const ['a', 'b'],
        target: _target,
        publishedVersions: _serving({'b': []}),
      );

      expect(
        gates.first,
        isA<PublishedVersionsUnknown>()
            .having((gate) => gate.allowed, 'allowed', isFalse)
            .having((gate) => gate.error.statusCode, 'statusCode', 503),
      );
      expect(gates.last, isA<PackageUnpublished>());
    });
  });

  group('lowestPublishableFor', () {
    test('clears the highest peak and an already published target', () async {
      final gates = await gateRelease(
        packages: const ['a', 'b', 'c'],
        target: _target,
        publishedVersions: _serving({
          'a': ['7.1.0-dev.1'],
          'b': ['7.1.0-dev.2'],
          'c': ['7.1.0-dev.4'],
        }),
      );

      expect(lowestPublishableFor(gates), Version.parse('7.1.0-dev.5'));
    });

    test('an already published target is itself the peak to clear', () async {
      final gates = await gateRelease(
        packages: const ['a'],
        target: _target,
        publishedVersions: _serving({
          'a': ['7.1.0-dev.2'],
        }),
      );

      expect(lowestPublishableFor(gates), Version.parse('7.1.0-dev.3'));
    });

    test('reports nothing when no package has opened the line', () async {
      final gates = await gateRelease(
        packages: const ['a', 'b'],
        target: _target,
        publishedVersions: _serving({
          'a': [],
          'b': ['6.0.0'],
        }),
      );

      expect(lowestPublishableFor(gates), isNull);
    });
  });

  group('reportReleaseGates', () {
    Future<(int, List<String>, List<String>)> report(
      Map<String, List<String>> published,
    ) async {
      final info = <String>[];
      final error = <String>[];
      final gates = await gateRelease(
        packages: published.keys,
        target: _target,
        publishedVersions: _serving(published),
      );
      final code = reportReleaseGates(gates, info: info.add, error: error.add);
      return (code, info, error);
    }

    test('passes when every package may be released', () async {
      final (code, info, error) = await report({
        'a': [],
        'b': ['7.0.0'],
        'c': ['7.1.0-dev.1'],
      });

      expect(code, 0);
      expect(error, isEmpty);
      expect(info, [
        'a has no published versions yet',
        'b opens the 7.1 line',
        'c 7.1.0-dev.2 is ranked above the published 7.1.0-dev.1',
      ]);
    });

    test('names the reason and the lowest version that would pass', () async {
      final (code, _, error) = await report({
        'a': ['7.1.0-dev.3'],
      });

      expect(code, 1);
      expect(error, [
        'a 7.1.0-dev.2 is not ranked above the published 7.1.0-dev.3; '
            'consumers would keep resolving 7.1.0-dev.3 (Pub does not order '
            '7.1.0-dev.2 above 7.1.0-dev.3)',
        'Published-version check failed. Pick a version the resolver orders '
            'above the peak of its release line.',
        "Lowest version that would pass: 7.1.0-dev.4 - run "
            "'ispect_tool version bump 7.1.0-dev.4'",
      ]);
    });
  });

  group('check-published', () {
    late Directory repo;
    late CapturedStdout out;
    late CapturedStdout err;

    setUp(() {
      repo = Directory.systemTemp.createTempSync('ispect-check-published-');
      File(p.join(repo.path, 'version.config'))
          .writeAsStringSync('VERSION=$_target\n');
      out = CapturedStdout();
      err = CapturedStdout();
    });

    tearDown(() => repo.deleteSync(recursive: true));

    Future<int?> checkPublished(PublishedVersionsReader reader) =>
        IOOverrides.runZoned(
          () => (CommandRunner<int>('ispect_tool', 'test')
                ..addCommand(
                  CheckPublishedCommand(repo.path, publishedVersions: reader),
                ))
              .run(const ['check-published']),
          stdout: () => out,
          stderr: () => err,
        );

    test('asks the injected reader about every published package', () async {
      final asked = <String>[];

      final code = await checkPublished((package) async {
        asked.add(package);
        return const <Version>[];
      });

      expect(code, 0);
      expect(asked, publishOrder);
      expect(
          out.buffer.toString(), contains('[INFO] Target version: $_target'));
      expect(
        out.buffer.toString(),
        contains('[OK ] ispect has no published versions yet'),
      );
    });

    test('exits 1 with the reason and the suggested bump', () async {
      final code = await checkPublished(
        (package) async =>
            package == 'ispectify_ws' ? [Version.parse('7.1.0-dev.3')] : [],
      );

      expect(code, 1);
      expect(
        err.buffer.toString(),
        allOf(
          contains(
            '[ERR] ispectify_ws 7.1.0-dev.2 is not ranked above the published '
            '7.1.0-dev.3',
          ),
          contains('(Pub does not order 7.1.0-dev.2 above 7.1.0-dev.3)'),
          contains(
            "[ERR] Lowest version that would pass: 7.1.0-dev.4 - run "
            "'ispect_tool version bump 7.1.0-dev.4'",
          ),
        ),
      );
    });

    test('a host that leaves a package unanswered fails the check', () async {
      final code = await checkPublished(_serving({
        for (final package in publishOrder)
          if (package != 'ispect') package: const <String>[],
      }));

      expect(code, 1);
      expect(
        err.buffer.toString(),
        contains('[ERR] Could not read the published versions of ispect'),
      );
    });
  });

  test('publish help documents PUBLISH_FORCE', () {
    final command = PublishCommand('unused');
    CommandRunner<int>('ispect_tool', 'test').addCommand(command);

    expect(command.usage, contains('PUBLISH_FORCE'));
  });
}
