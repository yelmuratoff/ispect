import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import 'exceptions.dart';
import 'next_version.dart';

const _fallbackHost = 'https://pub.dev';
const _fallbackTimeout = Duration(seconds: 30);
const _pubAcceptHeader = 'application/vnd.pub.v2+json';

final _trailingSlashes = RegExp(r'/+$');

/// The package host `PUB_HOSTED_URL` selects, or `https://pub.dev`.
Uri pubHostFrom(Map<String, String> environment) {
  final configured = environment['PUB_HOSTED_URL'] ?? '';
  final host = configured.isEmpty ? _fallbackHost : configured;
  return Uri.parse(host.replaceAll(_trailingSlashes, ''));
}

/// The per-request budget `PUB_API_TIMEOUT_SECONDS` selects, or 30 seconds.
Duration pubTimeoutFrom(Map<String, String> environment) {
  final seconds = int.tryParse(environment['PUB_API_TIMEOUT_SECONDS'] ?? '');
  return seconds == null || seconds <= 0
      ? _fallbackTimeout
      : Duration(seconds: seconds);
}

/// Reads the version history a package host already serves.
///
/// `GET /api/packages/<name>` is defined by the Hosted Pub Repository
/// Specification v2, which returns the whole `versions` array in one response:
/// https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md
final class PubClient {
  PubClient({
    Uri? host,
    Duration? timeout,
    Map<String, String>? environment,
  })  : _host = host ?? pubHostFrom(environment ?? Platform.environment),
        _timeout =
            timeout ?? pubTimeoutFrom(environment ?? Platform.environment);

  final Uri _host;
  final Duration _timeout;

  /// The host this client questions.
  Uri get host => _host;

  /// Every version [package] has published, distinct and unordered.
  ///
  /// An unpublished package answers 404 and yields an empty list. Version
  /// strings the resolver cannot parse are discarded.
  ///
  /// Throws [PubApiException] when the host answers anything other than 200 or
  /// 404, cannot be reached, or does not answer with a version list. A caller
  /// deciding whether to publish must never read a failure as an empty history.
  Future<List<Version>> publishedVersions(String package) async {
    final uri =
        Uri.parse('$_host/api/packages/${Uri.encodeComponent(package)}');
    final body = await _read(uri, package);
    if (body == null) {
      return const <Version>[];
    }
    return _versionsIn(body, uri, package);
  }

  Future<String?> _read(Uri uri, String package) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      return await _get(client, uri, package).timeout(_timeout);
    } on TimeoutException {
      throw PubApiException(
        '$uri did not answer within ${_timeout.inSeconds}s',
        package: package,
      );
    } on IOException catch (error) {
      throw PubApiException(
        '$uri could not be reached: $error',
        package: package,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _get(HttpClient client, Uri uri, String package) async {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, _pubAcceptHeader);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    switch (response.statusCode) {
      case HttpStatus.ok:
        return body;
      case HttpStatus.notFound:
        return null;
      default:
        throw PubApiException(
          '$uri answered ${response.statusCode}',
          package: package,
          statusCode: response.statusCode,
        );
    }
  }
}

List<Version> _versionsIn(String body, Uri uri, String package) {
  final decoded = _decode(body, uri, package);
  if (decoded is! Map<String, Object?>) {
    throw PubApiException(
      '$uri answered JSON that is not a package document',
      package: package,
      statusCode: HttpStatus.ok,
    );
  }

  final entries = decoded['versions'];
  if (entries is! List<Object?>) {
    throw PubApiException(
      '$uri did not list the published versions of $package',
      package: package,
      statusCode: HttpStatus.ok,
    );
  }

  final versions = <Version>{};
  for (final entry in entries) {
    if (entry is! Map<String, Object?>) {
      continue;
    }
    final value = entry['version'];
    if (value is! String) {
      continue;
    }
    final parsed = _tryParseVersion(value);
    if (parsed != null) {
      versions.add(parsed);
    }
  }
  return versions.toList(growable: false);
}

Object? _decode(String body, Uri uri, String package) {
  try {
    return jsonDecode(body);
  } on FormatException catch (error) {
    throw PubApiException(
      '$uri answered a body that is not JSON: ${error.message}',
      package: package,
      statusCode: HttpStatus.ok,
    );
  }
}

Version? _tryParseVersion(String value) {
  try {
    return Version.parse(value);
  } on FormatException {
    return null;
  }
}

/// The verdict on releasing one package version over what a host already serves.
sealed class PublishGate {
  const PublishGate({required this.package, required this.target});

  final String package;
  final Version target;

  /// Whether the release may proceed.
  bool get allowed;
}

/// The host serves no version of the package yet.
final class PackageUnpublished extends PublishGate {
  const PackageUnpublished({required super.package, required super.target});

  @override
  bool get allowed => true;
}

/// The target is the first release of its `MAJOR.MINOR` line.
final class ReleaseLineUnopened extends PublishGate {
  const ReleaseLineUnopened({required super.package, required super.target});

  @override
  bool get allowed => true;
}

/// The resolver ranks the target above the peak of its release line.
final class RisesAbovePeak extends PublishGate {
  const RisesAbovePeak({
    required super.package,
    required super.target,
    required this.peak,
  });

  final Version peak;

  @override
  bool get allowed => true;
}

/// The host already serves this exact version, so the upload would be rejected.
final class AlreadyPublished extends PublishGate {
  const AlreadyPublished({required super.package, required super.target});

  @override
  bool get allowed => false;
}

/// The resolver would keep serving [peak], so consumers never see the target
/// even though the publish itself succeeds.
final class BlockedByPeak extends PublishGate {
  const BlockedByPeak({
    required super.package,
    required super.target,
    required this.peak,
    required this.reason,
  });

  final Version peak;
  final String reason;

  @override
  bool get allowed => false;
}

/// The lowest version the gate would let through, given [peaks] — the highest
/// version each package already serves on the line being released.
///
/// The monorepo publishes every package from one `version.config`, so the
/// answer has to clear the highest peak among them, not each one separately.
/// Returns null when no package has opened the line yet.
Version? lowestPublishableAbove(Iterable<Version> peaks) {
  final highest = peaks.isEmpty ? null : (peaks.toList()..sort()).last;
  if (highest == null) {
    return null;
  }
  return highest.isPreRelease
      ? nextPrerelease(highest)
      : Version(highest.major, highest.minor, highest.patch + 1);
}

/// Decides whether [target] may be released for [package] over [published].
///
/// A release only counts when the resolver ranks it above the highest version
/// already published on the same `MAJOR.MINOR` line; other lines are ignored so
/// a backport is judged against its own series.
PublishGate publishGate({
  required String package,
  required Version target,
  required Iterable<Version> published,
}) {
  if (published.isEmpty) {
    return PackageUnpublished(package: package, target: target);
  }
  if (published.contains(target)) {
    return AlreadyPublished(package: package, target: target);
  }

  final peak = peakInLine(target, published);
  if (peak == null) {
    return ReleaseLineUnopened(package: package, target: target);
  }

  try {
    assertRises(target, peak);
    return RisesAbovePeak(package: package, target: target, peak: peak);
  } on VersionRegressionException catch (error) {
    return BlockedByPeak(
      package: package,
      target: target,
      peak: peak,
      reason: error.message,
    );
  }
}
