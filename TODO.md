# TODO

This file is intentionally short. Public planning lives in [`ROADMAP.md`](ROADMAP.md), where work is grouped by priority instead of presented as a flat backlog.

## Active Before 5.0 Stable

- Keep generated READMEs in sync with `docs/readme/`.
- Keep package versions and internal dependencies synced through `version.config`.
- Keep security, production-safety, compatibility, and deprecation docs current.
- Add tests for every behavior change in the 5.x pre-release line.

## Release Checks

- `./bash/build_readme.sh --check`
- `./bash/check_version_sync.sh`
- `./bash/check_dependencies.sh`
- package-level `dart analyze` / `flutter analyze`
- package-level `dart test` / `flutter test`
