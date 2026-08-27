# Deprecations and Migration Notes

APIs that still exist for compatibility but are no longer the preferred path.

## Current deprecations

The 7.x line keeps these APIs source-compatible. Their removal is grouped into
the next major release so a patch or minor release cannot break consumers.

| Deprecated API | Replacement | Removal target | Notes |
| --- | --- | --- | --- |
| `ISpectScopeController.of(context)` | `ISpect.read(context)` | `8.0.0` | Both resolve the same scope model. |
| `ISpectLogOptions` | `ISpectErrorHandlerOptions` | `8.0.0` | The alias predates the split between logger error handling and UI options. |
| `LogPageController` | `ISpectLogPageController` | `8.0.0` | The replacement follows the package's public `ISpect*` prefix. |
| `ISpectBuilder(...)` constructor | `ISpectBuilder.wrap(...)` | `8.0.0` | The factory short-circuits before widget construction when `kISpectEnabled` is false. |
| `ISpectLocalizations.delegates()` | `ISpectLocalizations.delegate()` | `8.0.0` | The host app should own its Material, Cupertino, and Widgets localization delegates. |
| Per-callback network filters and their builder methods | Composable request, response, sent, received, and error chains | `8.0.0` | Applies to `ispectify`, Dio, http, and WebSocket settings. Existing callbacks continue to forward during 7.x. |
| `widgetInspectorShortcuts`, `widgetInspectAndCompareShortcuts`, `colorPickerShortcuts`, `zoomShortcuts` | The corresponding `*ShortcutActivators` fields | `8.0.0` | Activators support multi-key chords and the full Flutter shortcut API. |
| `kDefaultSensitiveKeys` | `defaultSensitiveKeys` | `8.0.0` | Backward-compatible constant alias. |
| `redactedMask` | `defaultPlaceholder` | `8.0.0` | Redaction now uses one unified placeholder. |
| `JsonValueNormalizer.normalize(stringifyUnknown:)` | `allowCustomSerialization` | `8.0.0` | Custom serialization must be an explicit opt-in; unknown values are never stringified. |

## Already removed

`ispect`'s panel types moved to `draggable_panel` 4.0 in the `7.0.0` prerelease.
`DraggablePanelItem` became `PanelAction` (`enableBadge` → `badge`,
`description` → `tooltip`, `onTap(context)` → `onPressed()`),
`DraggablePanelButtonItem` became `PanelActionButton`, and `DraggablePanelTheme`
split into `DraggablePanelThemeData` (surface, shape, sizing, motion) and
`DraggableActionPanelThemeData` (action grid and buttons), surfaced as
`ISpectTheme.panelTheme` and `ISpectTheme.panelActionTheme`. Panel positions
are now `PanelPlacement` corners rather than stored pixel pairs; drop any
persisted coordinates. The upstream `MIGRATION.md` maps every removed symbol.

`ispectify_ws`'s client-specific `ISpectWSInterceptor` and its `ws` dependency
were removed in the `5.2.0` prerelease. Use provider-agnostic `WsDiagnostics`
and bind the chosen client through `WsDiagnosticsSink`; copy the matching
adapter from the package example when needed.

## Migration guidance

Migrate deprecated APIs while adopting the 7.x line. Deprecated APIs stay
covered by compatibility tests until their 8.0.0 removal.

Before 8.0.0:

- Search every package, example, and `web_logs_viewer` for consumers before
  removing a symbol.
- Document removals and migrations in the root changelog and README sources.
- Keep replacement examples for migrations that are not obvious.
- Add no new deprecation without a clear major-version removal target.
