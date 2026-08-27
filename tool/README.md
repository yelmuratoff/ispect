# ispect_tool

Release, version, and documentation tooling for the ISpect monorepo. Replaces
the bash scripts under `bash/`, which are frozen and scheduled for deletion.

```bash
cd tool && dart pub get          # once after a fresh clone
dart run tool/bin/ispect_tool.dart <command>
```

```bash
./bash/release_prep.sh --carry-changelog
→ dart run tool/bin/ispect_tool.dart release-prep --carry-changelog

./bash/publish.sh --auto
→ dart run tool/bin/ispect_tool.dart publish --auto
```

## Commands

| Command                           | Replaces                 | Does                                                                                       |
| --------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------ |
| `version check`                   | `check_version_sync.sh`  | Every package `version:` matches `version.config`                                          |
| `version bump <kind\|dev\|X.Y.Z>` | `bump_version.sh`        | Advances `VERSION`, refusing anything Pub does not order above the current one             |
| `sync [--bump k] [--dry-run]`     | `update_versions.sh`     | Propagates `VERSION` to manifests, internal constraints, and the web lockfile              |
| `deps`                            | `check_dependencies.sh`  | Internal `^<version>` constraints match `version.config`                                   |
| `readme [--check]`                | `build_readme.sh`        | Builds `README.md` and `packages/*/README.md` from `docs/readme/**`                        |
| `llms [--check]`                  | `build_llms.sh`          | Builds `llms.txt` from repository metadata                                                 |
| `changelog [--full-copy]`         | `update_changelog.sh`    | Propagates a root changelog section to the packages                                        |
| `release-prep [kind] [opts]`      | `release_prep.sh`        | Runs the whole release synchronization inside a rollback transaction                       |
| `check-published`                 | the gate in `publish.sh` | Refuses a version the resolver would not rank above the published peak of its release line |
| `publish [--dry-run\|--auto]`     | `publish.sh`             | Publishes every package in dependency order behind its preflights                          |

`publish --only <package>` narrows the run to one package — the way to resume a
release after a single package failed while the rest went out.

## Layout

`bin/` wires the `CommandRunner` and nothing else. All logic lives in
`lib/src/core/` as importable, I/O-injectable functions, so another tool can
drive it in-process instead of spawning a subprocess. `lib/src/cli/` holds thin
`Command` adapters.

## Testing

```bash
cd tool && dart test
```

Three kinds of test carry different weight:

- **Golden** — `readme_builder_test.dart` and `llms_builder_test.dart` regenerate
  the committed `README.md`, `packages/*/README.md`, and `llms.txt` and require a
  byte-identical result. These survive the deletion of the bash scripts and are
  the strongest ongoing guarantee.
- **Differential** — `*_differential_test.dart` and `bash_conformance_test.dart`
  run the frozen bash script and the Dart implementation over the same fixture
  and require identical exit codes and byte-identical trees. They are scaffolding
  for the migration and are deleted with their subject.
- **Unit** — behaviour and error branches per module.

`publish_test.dart` never reaches pub.dev: `ProcessRunner` and
`PublishConfirmation` are injected, and the suite asserts a poisoned `dart` on
`PATH` was never invoked.
