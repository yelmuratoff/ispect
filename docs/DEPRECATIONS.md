# Deprecations and Migration Notes

APIs that still exist for compatibility but are no longer the preferred path.

## Current deprecations

The 6.x line keeps these APIs source-compatible. Their removal is grouped into
the next major release so a patch or minor release cannot break consumers.

| Deprecated API | Replacement | Removal target | Notes |
| --- | --- | --- | --- |
| `ISpectScopeController.of(context)` | `ISpect.read(context)` | `7.0.0` | Both resolve the same scope model. |
| `ISpectLogOptions` | `ISpectErrorHandlerOptions` | `7.0.0` | The alias predates the split between logger error handling and UI options. |
| `LogPageController` | `ISpectLogPageController` | `7.0.0` | The replacement follows the package's public `ISpect*` prefix. |
| `ISpectBuilder(...)` constructor | `ISpectBuilder.wrap(...)` | `7.0.0` | The factory short-circuits before widget construction when `kISpectEnabled` is false. |
| `ISpectLocalizations.delegates()` | `ISpectLocalizations.delegate()` | `7.0.0` | The host app should own its Material, Cupertino, and Widgets localization delegates. |
| Per-callback network filters and their builder methods | Composable request, response, sent, received, and error chains | `7.0.0` | Applies to `ispectify`, Dio, http, and WebSocket settings. Existing callbacks continue to forward during 6.x. |
| `ISpectBlocSettings.verbose` | `ISpectBlocSettings()` | `7.0.0` | Default settings already capture full event and state payloads. |
| `widgetInspectorShortcuts`, `widgetInspectAndCompareShortcuts`, `colorPickerShortcuts`, `zoomShortcuts` | The corresponding `*ShortcutActivators` fields | `7.0.0` | Activators support multi-key chords and the full Flutter shortcut API. |
| `kDefaultSensitiveKeys` | `defaultSensitiveKeys` | `7.0.0` | Backward-compatible constant alias. |
| `redactedMask` | `defaultPlaceholder` | `7.0.0` | Redaction now uses one unified placeholder. |

## Already removed

`ispectify_ws`'s client-specific `ISpectWSInterceptor` and its `ws` dependency
were removed in the `5.2.0` prerelease. Use provider-agnostic `WsDiagnostics`
and bind the chosen client through `WsDiagnosticsSink`; copy the matching
adapter from the package example when needed.

## Migration guidance

Migrate deprecated APIs while adopting the 6.x line. Deprecated APIs stay
covered by compatibility tests until their 7.0.0 removal.

Before 7.0.0:

- Search every package, example, and `web_logs_viewer` for consumers before
  removing a symbol.
- Document removals and migrations in the root changelog and README sources.
- Keep replacement examples for migrations that are not obvious.
- Add no new deprecation without a clear major-version removal target.
