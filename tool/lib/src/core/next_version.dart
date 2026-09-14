import 'package:pub_semver/pub_semver.dart';

import 'exceptions.dart';

/// The kind of increment a release performs.
enum BumpKind {
  patch,
  minor,
  major;

  static BumpKind? tryParse(String value) =>
      BumpKind.values.where((kind) => kind.name == value).firstOrNull;
}

final _gluedCounter = RegExp(r'^[0-9A-Za-z-]*[A-Za-z-][0-9]+$');

/// The `MAJOR.MINOR` release line [version] belongs to.
String releaseLine(Version version) => '${version.major}.${version.minor}';

/// Whether a prerelease counter is glued to its label, as in `7.0.0-dev11`.
///
/// Such an identifier contains letters, so Pub compares it as text and
/// `dev11` sorts below `dev8`.
bool hasGluedCounter(Version version) => version.preRelease
    .any((part) => part is String && _gluedCounter.hasMatch(part));

/// Advances the prerelease counter so the result always sorts above [current].
///
/// A trailing numeric identifier is incremented; otherwise `.1` is appended,
/// which outranks the input because every earlier identifier is equal and the
/// result carries one more of them.
///
/// Throws [VersionRegressionException] when [current] is not a prerelease.
Version nextPrerelease(Version current) {
  if (!current.isPreRelease) {
    throw VersionRegressionException(
      next: '<none>',
      current: current.toString(),
      message: '$current is not a prerelease',
    );
  }

  final identifiers = List<Object>.of(current.preRelease);
  final last = identifiers.last;
  if (last is int) {
    identifiers[identifiers.length - 1] = last + 1;
  } else {
    identifiers.add(1);
  }

  return Version(
    current.major,
    current.minor,
    current.patch,
    pre: identifiers.join('.'),
  );
}

/// Opens a prerelease series on the patch after [current].
///
/// `7.1.0` becomes `7.1.1-dev.1`; a prerelease of the same core would sort
/// *below* the release it follows.
Version startPrerelease(Version current, {String label = 'dev'}) => Version(
      current.major,
      current.minor,
      current.patch + 1,
      pre: '$label.1',
    );

/// The next version for [kind], guaranteed to sort above [current].
///
/// A `patch` bump advances the counter of an existing prerelease rather than
/// the patch number; `minor` and `major` leave the prerelease behind.
///
/// Throws [VersionRegressionException] if the result would not rise.
Version nextVersion(Version current, BumpKind kind) {
  final next = switch (kind) {
    BumpKind.patch => current.isPreRelease
        ? nextPrerelease(current)
        : Version(current.major, current.minor, current.patch + 1),
    BumpKind.minor => Version(current.major, current.minor + 1, 0),
    BumpKind.major => Version(current.major + 1, 0, 0),
  };

  assertRises(next, current);
  return next;
}

/// The `dev` shorthand: advance an existing prerelease, or open a new series.
Version nextDevVersion(Version current) {
  final next =
      current.isPreRelease ? nextPrerelease(current) : startPrerelease(current);
  assertRises(next, current);
  return next;
}

/// The highest of [published] sharing [target]'s `MAJOR.MINOR` line.
///
/// Returns null when the line has no releases yet. Other lines are ignored so
/// a backport is judged against its own line rather than the newest release.
Version? peakInLine(Version target, Iterable<Version> published) {
  final line = releaseLine(target);
  final candidates = published.where((v) => releaseLine(v) == line).toList()
    ..sort();
  return candidates.isEmpty ? null : candidates.last;
}

/// Throws [VersionRegressionException] unless [next] sorts above [current].
void assertRises(Version next, Version current) {
  if (next.compareTo(current) > 0) {
    return;
  }
  throw VersionRegressionException(
    next: next.toString(),
    current: current.toString(),
    message: 'Pub does not order $next above $current',
  );
}
