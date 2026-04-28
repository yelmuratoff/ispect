# Deprecations and Migration Notes

This document tracks APIs that remain available for compatibility but are no longer the preferred path.

## Current 5.x Deprecations

| Deprecated API                                                                            | Replacement                     | Removal target | Notes                                                                                   |
| ----------------------------------------------------------------------------------------- | ------------------------------- | -------------- | --------------------------------------------------------------------------------------- |
| `ISpectScopeController.of(context)`                                                       | `ISpect.read(context)`          | `6.0.0`        | Both resolve the same scope model; `ISpect.read(context)` is the canonical entry point. |
| Per-callback network filters such as `requestFilter`, `responseFilter`, and `errorFilter` | Composable network filter chain | `6.0.0`        | Existing callbacks continue to forward to the new filtering model during 5.x.           |

## Migration Guidance

Prefer migrating deprecated APIs while adopting the 5.x line. Deprecated APIs should remain covered by compatibility tests until they are removed.

Before a stable release:

- document every deprecation in `CHANGELOG.md`;
- keep a replacement example in the relevant package README when the migration is not obvious;
- avoid introducing new deprecations without a clear removal target.
