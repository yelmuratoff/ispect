# Version Management System

How versions are kept consistent across the ISpect monorepo.

## Files

- `version.config`, the single source of truth for the current version.
- `CHANGELOG.md`, the source of truth for release notes.
- `bash/release_prep.sh`, the single user-facing command for version bumps and release synchronization.
- `bash/update_versions.sh`, the version and dependency helper used by `release_prep.sh`.
- `bash/update_changelog.sh`, the changelog propagation helper used by `release_prep.sh`.
- `bash/build_readme.sh` and `bash/build_llms.sh`, the generated-document helpers used by `release_prep.sh`.
- `bash/check_version_sync.sh`, validates version synchronization.
- `bash/check_dependencies.sh`, validates that internal package dependencies are consistent.
- `bash/pre-commit.sh`, Git hook that catches version drift before a commit lands.
- `.github/workflows/sync_versions_and_changelogs.yml`, CI workflow for automatic version and changelog sync.
- `.github/workflows/validate_versions.yml`, CI workflow that validates versions in pull requests.
- `.github/workflows/production_safety.yml`, CI workflow that verifies release builds with `ISPECT_ENABLED` omitted.

## Usage

### One-command release synchronization

```bash
# Patch bump (default).
./bash/release_prep.sh

# Explicit patch, minor, or major bump.
./bash/release_prep.sh --bump minor

# Keep VERSION and refresh every release-managed artifact.
./bash/release_prep.sh --skip-bump

# Advance the current prerelease and carry its notes forward.
./bash/release_prep.sh --carry-changelog

# Resume an interrupted prerelease sync without another bump.
./bash/release_prep.sh --skip-bump --recover-changelog
```

The default patch mode increments a stable patch version or advances the
counter of the current prerelease. Use `--skip-bump` after editing
`CHANGELOG.md` or `docs/readme/**` to regenerate everything without changing
the version.

### Prerelease numbering

Separate the counter from its label with a dot: `7.1.0-dev.1`, `7.1.0-dev.2`,
… `7.1.0-dev.10`. Semantic Versioning compares a dot-separated numeric
identifier as a number but an identifier containing letters as text, so the
glued form `7.1.0-dev10` resolves *below* `7.1.0-dev8`: Pub keeps handing
consumers the older code while the newer release sits on pub.dev unreachable,
and nothing reports an error.

The scripts refuse to write a version that Pub does not order above the current
one, and warn while `VERSION` still glues its counter to the label.
`publish.sh` additionally asks the host what it already serves and blocks a
version that is not ranked above the peak of the same `MAJOR.MINOR` line;
releases on other lines are ignored, so backporting `6.1.8` after `7.0.0`
shipped still passes.

A series already published in the glued form cannot be repaired by renumbering
it — the whole dot-form family sorts below every glued version. Leave the label
(`7.1.0-rc.1`) or the prerelease (`7.1.0`) instead. `7.0.0-dev8` through
`7.0.0-dev11` shipped this way, and Pub ranks `7.0.0-dev9` highest of them.

The command updates version metadata, internal constraints, the web-viewer
lockfile, the root and package changelogs, generated READMEs, and `llms.txt`.
It validates the complete result and restores all managed files to their
pre-run state if any step fails.

Use `--skip-bump --recover-changelog` only to recover an interrupted
prerelease carry when the root changelog still starts with the immediately
previous prerelease. Recovery is explicit, and stable changelog sections are
never renamed.

### Automatic updates via CI/CD

The GitHub Actions workflows automate the rest.

`sync_versions_and_changelogs.yml`:

- Triggers when `version.config` or `CHANGELOG.md` changes.
- Runs `release_prep.sh --skip-bump`, using the same workflow as local development.
- Validates the web-viewer lockfile with the CI-pinned Flutter 3.32.6 toolchain.
- Commits and pushes the changes back.

`validate_versions.yml`:

- Runs on pull requests to main branches.
- Runs release-prep regression tests.
- Checks package versions, internal constraints, and the web-viewer lockfile.
- Checks that `CHANGELOG.md` documents the current version.
- Checks that generated READMEs and `llms.txt` match their sources.

## How it works

1. `version.config` contains a single `VERSION` variable.
2. `release_prep.sh` optionally bumps it, then synchronizes every package `pubspec.yaml` and internal dependency.
3. `CHANGELOG.md` remains the release-note source of truth and is copied to package changelogs.
4. `docs/readme/**` remains the README source of truth; generated READMEs and `llms.txt` are rebuilt.
5. The web-viewer manifest and lockfile are synchronized with the same version.
6. All checks pass before the transaction is accepted.
7. CI repeats the no-bump path and validates the lockfile with Flutter 3.32.6.

## Best practices

1. Use `release_prep.sh` for every bump or no-bump synchronization.
2. Keep user-facing notes in the root `CHANGELOG.md`.
3. Keep README source changes under `docs/readme/**`.
4. Install the pre-commit hook to catch version drift locally.
5. Run `publish.sh --dry-run` before any publish attempt.
6. Review the generated diff before committing or publishing.

## Pre-commit hook

A pre-commit hook catches version drift before it lands:

```bash
cp bash/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

The hook:

1. Checks that all package versions match `version.config`.
2. Checks that internal dependencies are consistent with the current version.
3. Validates `CHANGELOG.md` formatting.
4. Confirms the current version is documented in the changelog.

## Troubleshooting

If you hit a sync issue:

1. Run `./bash/release_prep.sh --skip-bump`.
2. If it fails, read the first reported error; managed files have already been restored.
3. Use `./bash/check_version_sync.sh`, `./bash/check_dependencies.sh`, `./bash/build_readme.sh --check`, and `./bash/build_llms.sh --check` to isolate remaining drift.
