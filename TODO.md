# TODO

This file is intentionally short. Public planning lives in [`ROADMAP.md`](ROADMAP.md), where work is grouped by priority instead of presented as a flat backlog.

## Active Before 5.0 Stable

- Keep generated READMEs in sync with `docs/readme/`.
- Keep package versions and internal dependencies synced through `version.config`.
- Keep security, production-safety, compatibility, and deprecation docs current.
- Add tests for every behavior change in the 5.x pre-release line.
- Run publish dry-runs for every package before the stable `5.0.0` release.
- Verify the `production_safety.yml` workflow on GitHub Actions and document the result.
- Add migration snippets for each 5.x deprecated API.

## Evidence To Add

- Create reproducible benchmark scenarios for disabled release builds and enabled internal QA/staging builds.
- Measure logging/export/history behavior for representative event counts.
- Add adoption notes or case studies only when they are real and attributable.
- Add a 5-minute onboarding example that starts with metadata-only diagnostics.

## Release Checks

- `./bash/build_readme.sh --check`
- `./bash/check_version_sync.sh`
- `./bash/check_dependencies.sh`
- package-level `dart analyze` / `flutter analyze`
- package-level `dart test` / `flutter test`
