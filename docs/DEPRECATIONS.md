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
| `RedactionService.redactTarget` | `RedactionService.redactUrl` on a configured service | `8.0.0` | The static helper built a throwaway service per call and had no consumer in the toolkit. |
| `RedactionService.redactWithStats`, `RedactionService.redactHeadersWithStats` | `NetworkPayloadSanitizer.headersMapWithProvenance` / `bodyWithProvenance` | `8.0.0` | Redaction provenance is derived from the sanitizer pass that already runs. |
| `ISpectLogData.header` | `HumanLogEntryFormatter` | `8.0.0` | The formatter is the single console line renderer; `header` lacked source, category, and correlation metadata. |
| `static redact(...)` on `ispectify_bloc` and `ispectify_riverpod` data classes | `StateTracePreparer` | `8.0.0` | Observers prepare payloads through the shared preparer; the per-class helpers used weaker key-only masking. |
| `dbReadOperations` (`ispectify_db`) | `dbCategory.secondaryOperations` | `8.0.0` | DB log keys are chosen by `dbCategory`; the constant listed a larger set that no emit path consulted. |
| `ISpectBlocSettings.formatEvent`, `ISpectRiverpodSettings.formatValue` | `printEventFullData` / `printValues` | `8.0.0` | The observers format payloads themselves; the helpers had no caller. |
| `ISpectBlocSettings.redactAdditionalData`, `ISpectRiverpodSettings.redactAdditionalData` | `StateTracePreparer.prepareAdditionalData` | `8.0.0` | The observers already prepare `additionalData` through the shared preparer. |
| `DbLogKeys.source`, `operation`, `target`, `durationMs`, `slow`, `success`, `meta`, `transactionId`, `error` | The matching `TraceKeys` constants | `8.0.0` | DB entries are emitted through `trace()`, which writes these keys from `TraceKeys`. |
| `DbTxnOps` | The operation of `traceTransaction(logMarkers: true)` entries | `8.0.0` | No emit path reads the class; transaction markers come from `ispectify`. |
| `ISpectDbCore.redact`, `ISpectDbCore.redactIfNeeded` | `RedactionService.redactByKeys` | `8.0.0` | Thin wrappers with no caller in the toolkit. |
| `dbTransaction(meta:)` | `meta` on the DB calls inside `run` | `8.0.0` | The parameter was accepted but never logged. |
| `ISpectDbTxn.runInTransactionZone` | `ISpectLogger.dbTransaction` | `8.0.0` | `currentTransactionId()` already reads the trace transaction that `dbTransaction` opens. |
| `HttpResponseData(preDecodedBody:)` | Omit the argument | `8.0.0` | The interceptor decodes `response.bodyBytes` itself and never passes a prepared body. |
| `NetworkLoggerMixin.shouldProcess` | The settings' `shouldProcess*` chain predicates | `8.0.0` | No interceptor called it. |
| `NetworkLoggerMixin.asStringMap`, `BaseNetworkInterceptor.asStringMap` | `NetworkPayloadSanitizer.toStringKeyMap` | `8.0.0` | The replacement bounds the copy; the old helper returned unbounded maps. |
| `NetworkPayloadSanitizer.headersOrNull`, `ensureMap`, `stringKeyMap`, `nullIfEmpty` | `headersMap`, `toStringKeyMap`, or an `isEmpty` check | `8.0.0` | Unused convenience wrappers. |
| `RedactionContext.isSensitiveKeyLower` | `RedactionContext.isSensitiveKey` | `8.0.0` | The lowercased variant skips camelCase and separator canonicalization, so it can disagree with `classifyKey`. |
| `RedactionService.redactExportString` | `redactForExport` on a configured `RedactionService` | `8.0.0` | The static helper had no consumer; exports redact through the configured service. |
| `StringBuffer.writelnIf` (`StringBufferExtension`) | `if (condition) buffer.writeln(value)` | `8.0.0` | Unused extension exported with the navigator observer. |
| `ISpectSettingsState.isAllLogTypesEnabled` | `disabledLogTypes.isEmpty` | `8.0.0` | No caller in the toolkit. |
| `LogsJsonService.shareLogsAsJsonFile`, `shareFilteredLogsAsJsonFile`, `saveFilteredLogsToDevice` | `exportToJson` or `formatFilteredContent` with `LogsFileFactory.shareFile` / `saveToDevice` | `8.0.0` | The share sheets compose those calls directly. |
| `ISpectToaster.showErrorToast(l10n:)`, `showInfoToast(l10n:)`, `showSuccessToast(l10n:)` | Omit the argument | `8.0.0` | These toasts render only the caller's `title` and `message`, so the parameter was never read. |
| `InspectorMode.inspectAndCompare` (`ispect_layout`) | `InspectorController.enterCompareMode()` (`InspectorMode.compareSelect`) | `8.0.0` | The compare shortcut and button use `compareSelect`; the hover-compare mode was reachable only through `setMode`. |

## Already removed

`ispect`'s panel types moved to `draggable_panel` 4.0 in `7.0.0`.
`DraggablePanelItem` became `PanelAction` (`enableBadge` → `badge`,
`description` → `tooltip`, `onTap(context)` → `onPressed()`),
`DraggablePanelButtonItem` became `PanelActionButton`, and `DraggablePanelTheme`
split into `DraggablePanelThemeData` (surface, shape, sizing, motion) and
`DraggableActionPanelThemeData` (action grid and buttons), surfaced as
`ISpectTheme.panelTheme` and `ISpectTheme.panelActionTheme`. Panel positions
are now `PanelPlacement` corners rather than stored pixel pairs; drop any
persisted coordinates. `PanelStyle`, re-exported by early `7.0.0` prereleases,
is internal to `draggable_panel` 4.0.0; author panel tokens through
`ISpectTheme.panelTheme`. The upstream `MIGRATION.md` maps every removed symbol.

`ispectify_ws`'s client-specific `ISpectWSInterceptor` and its `ws` dependency
were removed in `6.0.0` (developed as the `5.2.0` prereleases). Use provider-agnostic `WsDiagnostics`
and bind the chosen client through `WsDiagnosticsSink`; copy the matching
adapter from the package example when needed.

## Migration guidance

Migrate deprecated APIs while adopting the 7.x line. Deprecated APIs stay
source-compatible until their 8.0.0 removal.

Before 8.0.0:

- Search every package, example, and `web_logs_viewer` for consumers before
  removing a symbol.
- Document removals and migrations in the root changelog and README sources.
- Keep replacement examples for migrations that are not obvious.
- Add no new deprecation without a clear major-version removal target.
