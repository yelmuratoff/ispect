# TODO

This file is intentionally short. Public planning lives in [`ROADMAP.md`](ROADMAP.md), where work is grouped by priority instead of presented as a flat backlog.

## Open

- Run and publish the remaining physical-Android measurements: disabled/enabled cold startup and the high-volume log viewer with filters off/on.
- Add adoption notes or case studies to `docs/USE_CASES.md` only when they are real and attributable, with concrete numbers.

## Release Checks

- `./bash/build_readme.sh --check`
- `./bash/check_version_sync.sh`
- `./bash/check_dependencies.sh`
- package-level `dart analyze` / `flutter analyze`
- package-level `dart test` / `flutter test`
