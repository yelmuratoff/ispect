# TODO

This file is intentionally short. Public planning lives in [`ROADMAP.md`](ROADMAP.md), where work is grouped by priority instead of presented as a flat backlog.

## Open

- Build a reproducible benchmark suite covering disabled release builds and enabled internal QA/staging builds, measuring logging/export/history behavior for representative event counts (`docs/PERFORMANCE.md` has no numbers yet).
- Add adoption notes or case studies to `docs/USE_CASES.md` only when they are real and attributable, with concrete numbers.

## Release Checks

- `./bash/build_readme.sh --check`
- `./bash/check_version_sync.sh`
- `./bash/check_dependencies.sh`
- package-level `dart analyze` / `flutter analyze`
- package-level `dart test` / `flutter test`
