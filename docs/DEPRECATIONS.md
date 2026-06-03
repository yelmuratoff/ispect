# Deprecations and Migration Notes

APIs that still exist for compatibility but are no longer the preferred path.

## Current 5.x deprecations

| Deprecated API                                                                            | Replacement                     | Removal target | Notes                                                                                                                                                                                     |
| ----------------------------------------------------------------------------------------- | ------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ISpectScopeController.of(context)`                                                       | `ISpect.read(context)`          | `6.0.0`        | Both resolve the same scope model. `ISpect.read(context)` is the canonical entry point.                                                                                                   |
| Per-callback network filters: `requestFilter`, `responseFilter`, `errorFilter`            | Composable network filter chain | `6.0.0`        | Existing callbacks continue to forward to the new filtering model during 5.x.                                                                                                             |
| `ISpectBuilder(...)` constructor                                                          | `ISpectBuilder.wrap(...)`       | `6.0.0`        | The `wrap` factory short-circuits before constructing the widget when `kISpectEnabled` is `false`, which preserves tree-shaking. The constructor will be made private in a stable 5.x release. |
| `ISpectLocalizations.delegates()`                                                         | `ISpectLocalizations.delegate()` | `6.0.0`        | The legacy helper injects `GlobalMaterialLocalizations`, `Cupertino`, and `Widgets` along with ISpect's delegate, mutating the host app's localization stack even in release builds. To migrate, add the three `Global*Localizations.delegate` entries from `package:flutter_localizations/flutter_localizations.dart` to your own `localizationsDelegates` list, then spread `...ISpectLocalizations.delegate()` after them. The legacy method keeps working as a forwarder during 5.x. |
| `ispectify_ws` `ISpectWSInterceptor` (and its `ws` dependency)                             | `WsDiagnostics` + a copied adapter | Removed in `5.2.0` (prerelease) | `ispectify_ws` is now provider-agnostic and no longer depends on `ws` or exports `ISpectWSInterceptor`. Bind any client to `WsDiagnostics` via the `WsDiagnosticsSink` port; for the `ws` (plugfox) client, copy `packages/ispectify_ws/example/lib/interceptors/ws_interceptor.dart` and add `ws` to your app. `ISpectWSInterceptorSettings` and the `ws-sent` / `ws-received` / `ws-error` keys are unchanged. |

## Migration guidance

Migrate deprecated APIs while adopting the 5.x line. Deprecated APIs stay covered by compatibility tests until removal.

Before a stable release:

- Every deprecation is documented in `CHANGELOG.md`.
- The relevant package README keeps a replacement example when the migration is not obvious.
- No new deprecations land without a clear removal target.
