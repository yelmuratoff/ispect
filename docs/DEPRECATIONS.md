# Deprecations and Migration Notes

This document tracks APIs that remain available for compatibility but are no longer the preferred path.

## Current 5.x Deprecations

| Deprecated API                                                                            | Replacement                     | Removal target | Notes                                                                                                                                                                                     |
| ----------------------------------------------------------------------------------------- | ------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ISpectScopeController.of(context)`                                                       | `ISpect.read(context)`          | `6.0.0`        | Both resolve the same scope model; `ISpect.read(context)` is the canonical entry point.                                                                                                   |
| Per-callback network filters such as `requestFilter`, `responseFilter`, and `errorFilter` | Composable network filter chain | `6.0.0`        | Existing callbacks continue to forward to the new filtering model during 5.x.                                                                                                             |
| `ISpectBuilder(...)` constructor                                                          | `ISpectBuilder.wrap(...)`       | `6.0.0`        | The `wrap` factory short-circuits before constructing the widget when `kISpectEnabled` is `false`, preserving tree-shaking. The constructor will be made private in a stable 5.x release. |
| `ISpectLocalizations.delegates()`                                                         | `ISpectLocalizations.delegate()` | `6.0.0`        | The legacy helper injects `GlobalMaterialLocalizations`/`Cupertino`/`Widgets` along with ISpect's delegate, mutating the host app's localization stack even in release builds. Migrate by adding the three `Global*Localizations.delegate` entries from `package:flutter_localizations/flutter_localizations.dart` to your own `localizationsDelegates` list and spreading `...ISpectLocalizations.delegate()` after them. The legacy method continues to work as a forwarder during 5.x. |

## Migration Guidance

Prefer migrating deprecated APIs while adopting the 5.x line. Deprecated APIs should remain covered by compatibility tests until they are removed.

Before a stable release:

- document every deprecation in `CHANGELOG.md`;
- keep a replacement example in the relevant package README when the migration is not obvious;
- avoid introducing new deprecations without a clear removal target.
