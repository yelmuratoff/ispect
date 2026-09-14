# TODO

This file is intentionally short. Public planning lives in [`ROADMAP.md`](ROADMAP.md), where work is grouped by priority instead of presented as a flat backlog.

## Open

- Run and publish the remaining physical-Android measurements: disabled/enabled cold startup and the high-volume log viewer with filters off/on.
- Repeat the physical-iOS startup and high-volume measurements with Simulator, unrelated builds, and other sustained CPU/I/O workloads stopped; treat the 2026-07-17 pass as provisional.
- Add adoption notes or case studies to `docs/USE_CASES.md` only when they are real and attributable, with concrete numbers.

## Release Checks

- `dart run tool/bin/ispect_tool.dart check`
- `dart run tool/bin/ispect_tool.dart deps`
- `dart run tool/bin/ispect_tool.dart publish --dry-run`
- package-level `dart analyze --fatal-infos` / `flutter analyze --fatal-infos`
- package-level `flutter test --dart-define=ISPECT_ENABLED=true`, plus `production_safety_test.dart` without the define
