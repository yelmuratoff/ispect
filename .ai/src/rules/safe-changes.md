# Safe Change Rules

## Sensitive Surfaces

- Treat public package exports, constructor parameters, log keys, metadata key names, and trace category IDs as compatibility surfaces.
- Treat generated localization APIs and ARB keys as compatibility surfaces for the Flutter UI.
- Treat `kISpectEnabled`, `ISpect.run`, `ISpect.initialize`, and production-safety build behavior as release-safety surfaces.
- Treat redaction defaults, placeholder values, and sensitive key sets as security surfaces.

## Before Changing APIs

- Search all packages and `web_logs_viewer` for consumers before renaming or removing a public symbol.
- Check `docs/DEPRECATIONS.md` before removing deprecated APIs.
- Prefer additive changes and deprecation notes for package consumers.
- Update examples and README sources when changing public setup instructions.

## Generated Or Derived Files

- Generated localization files live under `core/localization/generated`; change ARB/source config first.
- Generated README files should be rebuilt with `./bash/build_readme.sh`.
- Coverage output and build output should remain uncommitted.

## Anti-Patterns

- Do not casually rename log keys like `http-request`, `db-query`, or `bloc-error`; filters and exported sessions depend on them.
- Do not change disabled-build behavior to rely on runtime checks only.
- Do not make broad UI refactors in `ispect` while fixing a core logging bug.
