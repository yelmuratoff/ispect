/// Failures the tooling raises for a caller to report and exit on.
sealed class ToolException implements Exception {
  const ToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `version.config` is missing, empty, or does not hold a semantic version.
final class VersionConfigException extends ToolException {
  const VersionConfigException(super.message);
}

/// A computed or requested version is not ordered above the one it replaces.
final class VersionRegressionException extends ToolException {
  const VersionRegressionException({
    required this.next,
    required this.current,
    required String message,
  }) : super(message);

  final String next;
  final String current;
}

/// A package version does not match `version.config`.
final class VersionSyncException extends ToolException {
  const VersionSyncException(super.message, {required this.outOfSync});

  /// Package names whose `version:` line disagrees with `version.config`.
  final List<String> outOfSync;
}

/// A manifest or lockfile the tooling rewrites is missing or malformed.
final class ManifestException extends ToolException {
  const ManifestException(super.message);
}

/// A pubspec on disk cannot be read as a YAML mapping.
final class PubspecException extends ToolException {
  const PubspecException(super.message);
}

/// An internal `^` constraint between monorepo packages does not match
/// `version.config`.
final class DependencyConsistencyException extends ToolException {
  const DependencyConsistencyException(
    super.message, {
    required this.inconsistencies,
  });

  /// One rendered message per offending constraint.
  final List<String> inconsistencies;
}

/// A documentation source directory or template file is missing.
final class DocsSourceException extends ToolException {
  const DocsSourceException(super.message);
}

/// A `<!-- partial:NAME -->` marker names a partial that cannot be resolved,
/// either because no such file exists or because the references form a cycle.
final class PartialResolutionException extends ToolException {
  const PartialResolutionException(super.message, {required this.partialName});

  /// The partial named by the marker that could not be expanded.
  final String partialName;
}

/// A changelog the tooling reads or propagates is missing or has no section
/// for the requested version.
final class ChangelogException extends ToolException {
  const ChangelogException(super.message);
}

/// A file a release run manages is unsafe to snapshot or to restore, because
/// it escapes the repository, resolves through a symlink, or is not a regular
/// file.
final class ManagedPathException extends ToolException {
  const ManagedPathException(super.message, {required this.path});

  /// The repository-relative path that was rejected.
  final String path;
}

/// A precondition of a release run does not hold, so no artifact was written.
final class ReleasePrepException extends ToolException {
  const ReleasePrepException(super.message);
}

/// A package host left the published history of a package unanswered.
final class PubApiException extends ToolException {
  const PubApiException(
    super.message, {
    required this.package,
    this.statusCode,
  });

  /// The package whose published versions could not be read.
  final String package;

  /// The HTTP status the host answered, or null when it never answered.
  final int? statusCode;
}
