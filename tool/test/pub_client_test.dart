@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/pub_client.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

const _ispectDocument = '''
{"name":"ispect","latest":{"version":"6.1.7","pubspec":{"name":"ispect","version":"6.1.7",
"environment":{"sdk":">=3.6.0 <4.0.0"},"dependencies":{"ispectify":"^6.1.7","dio":"^5.9.2"}}},
"versions":[
{"version":"6.1.7","pubspec":{"name":"ispect","version":"6.1.7"},"archive_url":"https://x/6.1.7"},
{"version":"7.0.0-dev8","pubspec":{"name":"ispect","version":"7.0.0-dev8"},"archive_url":"https://x/d8"},
{"version":"7.0.0-dev9","pubspec":{"name":"ispect","version":"7.0.0-dev9"},"archive_url":"https://x/d9"},
{"version":"7.0.0-dev10","pubspec":{"name":"ispect","version":"7.0.0-dev10"},"archive_url":"https://x/d10"},
{"version":"7.0.0-dev11","pubspec":{"name":"ispect","version":"7.0.0-dev11"},"archive_url":"https://x/d11"}
]}
''';

const _noisyDocument = '''
{"name":"x","versions":[
{"version":"1.0.0","pubspec":{"version":"1.0.0","description":"the \\"version\\" of record"}},
{"version" : "not-a-version"},
{"version":"1.0.1"}
]}
''';

const _ispectVersions = <String>[
  '6.1.7',
  '7.0.0-dev8',
  '7.0.0-dev9',
  '7.0.0-dev10',
  '7.0.0-dev11',
];

typedef Answer = void Function(HttpRequest request);

/// Answers every request with [status] and [body], recording what was asked.
final class RecordingHost {
  RecordingHost._(this._server, this.requests);

  final HttpServer _server;
  final List<HttpRequest> requests;

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<RecordingHost> start(Answer answer) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <HttpRequest>[];
    server.listen((request) {
      requests.add(request);
      answer(request);
    });
    return RecordingHost._(server, requests);
  }

  Future<void> stop() => _server.close(force: true);
}

Answer _answers(int status, String body) => (request) {
      request.response.statusCode = status;
      request.response.write(body);
      request.response.close();
    };

Future<RecordingHost> _hostServing(int status, String body) async {
  final host = await RecordingHost.start(_answers(status, body));
  addTearDown(host.stop);
  return host;
}

List<String> _asStrings(Iterable<Version> versions) =>
    versions.map((version) => version.toString()).toList()..sort();

/// Runs `pub_api_published_versions` from the bash library being replaced,
/// pointed at [host] through `PUB_HOSTED_URL`.
Future<({int exitCode, List<String> versions})> _bashListing(
  String repoRoot,
  Uri host,
  String package,
) async {
  final result = await Process.run(
    'bash',
    [
      '-c',
      'source "\$1/bash/lib/semver.sh"; source "\$1/bash/lib/pub_api.sh"; '
          'pub_api_published_versions "\$2"',
      'bash',
      repoRoot,
      package,
    ],
    environment: {'PUB_HOSTED_URL': host.toString()},
  );
  final stdout = (result.stdout as String)
      .split('\n')
      .where((line) => line.isNotEmpty)
      .toList()
    ..sort();
  return (exitCode: result.exitCode, versions: stdout);
}

void main() {
  group('reading the published history', () {
    test('every version in the document is reported once', () async {
      final host = await _hostServing(HttpStatus.ok, _ispectDocument);

      final versions =
          await PubClient(host: host.uri).publishedVersions('ispect');

      expect(
          _asStrings(versions), _asStrings(_ispectVersions.map(Version.parse)));
    });

    test('the request asks the documented pub endpoint and media type',
        () async {
      final host = await _hostServing(HttpStatus.ok, _ispectDocument);

      await PubClient(host: host.uri).publishedVersions('ispect');

      expect(host.requests.single.uri.path, '/api/packages/ispect');
      expect(
        host.requests.single.headers.value(HttpHeaders.acceptHeader),
        'application/vnd.pub.v2+json',
      );
    });

    test('a version named only inside a pubspec is not a published version',
        () async {
      final host = await _hostServing(
        HttpStatus.ok,
        jsonEncode({
          'name': 'ispect',
          'latest': {
            'version': '9.9.9',
            'pubspec': {'version': '9.9.9'},
          },
          'versions': [
            {
              'version': '1.0.0',
              'pubspec': {'version': '8.8.8'},
            },
          ],
        }),
      );

      final versions =
          await PubClient(host: host.uri).publishedVersions('ispect');

      expect(_asStrings(versions), ['1.0.0']);
    });

    test('an unpublished package reports no versions without failing',
        () async {
      final host = await _hostServing(HttpStatus.notFound, '{"error":{}}');

      expect(
        await PubClient(host: host.uri).publishedVersions('brand_new'),
        isEmpty,
      );
    });

    test('non-semver version strings are discarded', () async {
      final host = await _hostServing(HttpStatus.ok, _noisyDocument);

      final versions = await PubClient(host: host.uri).publishedVersions('x');

      expect(_asStrings(versions), ['1.0.0', '1.0.1']);
    });

    test('a version entry that is not a string is discarded', () async {
      final host = await _hostServing(
        HttpStatus.ok,
        '{"versions":[{"version":1},{"version":"2.0.0"},"loose",null]}',
      );

      final versions = await PubClient(host: host.uri).publishedVersions('x');

      expect(_asStrings(versions), ['2.0.0']);
    });

    test('a repeated version is reported once', () async {
      final host = await _hostServing(
        HttpStatus.ok,
        '{"versions":[{"version":"1.0.0"},{"version":"1.0.0"}]}',
      );

      final versions = await PubClient(host: host.uri).publishedVersions('x');

      expect(_asStrings(versions), ['1.0.0']);
    });
  });

  group('an unanswered question stops the release', () {
    test('a server error fails loudly instead of reporting no versions',
        () async {
      final host = await _hostServing(HttpStatus.serviceUnavailable, 'down');

      await expectLater(
        PubClient(host: host.uri).publishedVersions('ispect'),
        throwsA(
          isA<PubApiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.package, 'package', 'ispect'),
        ),
      );
    });

    test('an unreachable host fails loudly', () async {
      final host = await _hostServing(HttpStatus.ok, _ispectDocument);
      final uri = host.uri;
      await host.stop();

      await expectLater(
        PubClient(host: uri).publishedVersions('ispect'),
        throwsA(
          isA<PubApiException>()
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });

    test('a body that is not JSON fails loudly', () async {
      final host =
          await _hostServing(HttpStatus.ok, '<html>maintenance</html>');

      await expectLater(
        PubClient(host: host.uri).publishedVersions('ispect'),
        throwsA(isA<PubApiException>()),
      );
    });

    test('a document without a versions list fails loudly', () async {
      final host = await _hostServing(HttpStatus.ok, '{"name":"ispect"}');

      await expectLater(
        PubClient(host: host.uri).publishedVersions('ispect'),
        throwsA(isA<PubApiException>()),
      );
    });

    test('a document that is not an object fails loudly', () async {
      final host = await _hostServing(HttpStatus.ok, '["6.1.7"]');

      await expectLater(
        PubClient(host: host.uri).publishedVersions('ispect'),
        throwsA(isA<PubApiException>()),
      );
    });
  });

  group('host configuration', () {
    test('PUB_HOSTED_URL replaces pub.dev', () {
      expect(
        pubHostFrom({'PUB_HOSTED_URL': 'https://packages.internal/pub'}),
        Uri.parse('https://packages.internal/pub'),
      );
    });

    test('a trailing slash does not double up in the request path', () {
      expect(
        pubHostFrom({'PUB_HOSTED_URL': 'https://packages.internal/'}),
        Uri.parse('https://packages.internal'),
      );
    });

    test('an unset or empty PUB_HOSTED_URL falls back to pub.dev', () {
      expect(pubHostFrom({}), Uri.parse('https://pub.dev'));
      expect(pubHostFrom({'PUB_HOSTED_URL': ''}), Uri.parse('https://pub.dev'));
    });

    test('the environment reaches the request the client makes', () async {
      final host = await _hostServing(HttpStatus.ok, _ispectDocument);

      final client =
          PubClient(environment: {'PUB_HOSTED_URL': host.uri.toString()});
      final versions = await client.publishedVersions('ispect');

      expect(client.host, host.uri);
      expect(versions, hasLength(5));
    });

    test('PUB_API_TIMEOUT_SECONDS replaces the 30 second budget', () {
      expect(
        pubTimeoutFrom({'PUB_API_TIMEOUT_SECONDS': '5'}),
        const Duration(seconds: 5),
      );
      expect(pubTimeoutFrom({}), const Duration(seconds: 30));
      expect(
        pubTimeoutFrom({'PUB_API_TIMEOUT_SECONDS': 'soon'}),
        const Duration(seconds: 30),
      );
    });
  });

  group('pagination', () {
    test(
        'the whole history arrives in one response, so next_url is not followed',
        () async {
      final host = await _hostServing(
        HttpStatus.ok,
        jsonEncode({
          'name': 'ispect',
          'next_url': 'http://127.0.0.1:1/api/packages/ispect?page=2',
          'versions': [
            {'version': '1.0.0'},
            {'version': '1.0.1'},
          ],
        }),
      );

      final versions =
          await PubClient(host: host.uri).publishedVersions('ispect');

      expect(_asStrings(versions), ['1.0.0', '1.0.1']);
      expect(host.requests, hasLength(1));
    });
  });

  group('the publish gate', () {
    final published = _ispectVersions.map(Version.parse).toList();

    test('a release above the peak of its line may proceed', () {
      final gate = publishGate(
        package: 'ispect',
        target: Version.parse('7.0.0-rc.1'),
        published: published,
      );

      expect(gate, isA<RisesAbovePeak>());
      expect(gate.allowed, isTrue);
      expect((gate as RisesAbovePeak).peak, Version.parse('7.0.0-dev9'));
    });

    test('an unpublished release the resolver ranks below the peak is blocked',
        () {
      final gate = publishGate(
        package: 'ispect',
        target: Version.parse('7.0.0-dev11.1'),
        published: published,
      );

      expect(gate, isA<BlockedByPeak>());
      expect(gate.allowed, isFalse);
      expect((gate as BlockedByPeak).peak, Version.parse('7.0.0-dev9'));
    });

    test('republishing a version the host already serves is blocked', () {
      final gate = publishGate(
        package: 'ispect',
        target: Version.parse('7.0.0-dev9'),
        published: published,
      );

      expect(gate, isA<AlreadyPublished>());
      expect(gate.allowed, isFalse);
    });

    test('a backport is judged against its own line, not the newest release',
        () {
      final gate = publishGate(
        package: 'ispect',
        target: Version.parse('6.1.8'),
        published: published,
      );

      expect(gate, isA<RisesAbovePeak>());
      expect((gate as RisesAbovePeak).peak, Version.parse('6.1.7'));
    });

    test('a release opening a new line may proceed', () {
      final gate = publishGate(
        package: 'ispect',
        target: Version.parse('8.0.0-dev.1'),
        published: published,
      );

      expect(gate, isA<ReleaseLineUnopened>());
      expect(gate.allowed, isTrue);
    });

    test('an unpublished package may proceed', () {
      final gate = publishGate(
        package: 'brand_new',
        target: Version.parse('7.0.0-rc.1'),
        published: const <Version>[],
      );

      expect(gate, isA<PackageUnpublished>());
      expect(gate.allowed, isTrue);
    });
  });

  group('differential against bash/lib/pub_api.sh', () {
    final root = findRepoRoot(Directory.current.path) ?? '';

    test('both implementations read the same versions from one document',
        () async {
      final host = await _hostServing(HttpStatus.ok, _ispectDocument);

      final fromBash = await _bashListing(root, host.uri, 'ispect');
      final fromDart =
          await PubClient(host: host.uri).publishedVersions('ispect');

      expect(fromBash.exitCode, 0);
      expect(fromBash.versions, _asStrings(fromDart));
    });

    test('both implementations discard the same JSON noise', () async {
      final host = await _hostServing(HttpStatus.ok, _noisyDocument);

      final fromBash = await _bashListing(root, host.uri, 'x');
      final fromDart = await PubClient(host: host.uri).publishedVersions('x');

      expect(fromBash.exitCode, 0);
      expect(fromBash.versions, _asStrings(fromDart));
    });

    test('both implementations succeed with no versions on 404', () async {
      final host = await _hostServing(HttpStatus.notFound, '{"error":{}}');

      final fromBash = await _bashListing(root, host.uri, 'brand_new');
      final fromDart =
          await PubClient(host: host.uri).publishedVersions('brand_new');

      expect(fromBash.exitCode, 0);
      expect(fromBash.versions, isEmpty);
      expect(fromDart, isEmpty);
    });

    test('both implementations fail on a server error', () async {
      final host = await _hostServing(HttpStatus.serviceUnavailable, 'down');

      final fromBash = await _bashListing(root, host.uri, 'ispect');

      expect(fromBash.exitCode, 1);
      await expectLater(
        PubClient(host: host.uri).publishedVersions('ispect'),
        throwsA(isA<PubApiException>()),
      );
    });

    test('both implementations fail on an unreachable host', () async {
      final host = await _hostServing(HttpStatus.ok, _ispectDocument);
      final uri = host.uri;
      await host.stop();

      final fromBash = await _bashListing(root, uri, 'ispect');

      expect(fromBash.exitCode, 1);
      await expectLater(
        PubClient(host: uri).publishedVersions('ispect'),
        throwsA(isA<PubApiException>()),
      );
    });
  }, skip: _skipDifferential());
}

String? _skipDifferential() {
  final repoRoot = findRepoRoot(Directory.current.path);
  if (repoRoot == null ||
      !File(p.join(repoRoot, 'bash', 'lib', 'pub_api.sh')).existsSync()) {
    return 'bash/lib/pub_api.sh is gone; the Dart port is the only source';
  }
  return null;
}
