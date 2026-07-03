# Changelog

## 6.0.6

### Improvements

- **Kurdish localization:** ISpect's UI is now translated into Sorani (`ckb`) and Kurmanji (`ku`); both resolve automatically through `ISpectLocalization.supportedLocales`. Apps that display ISpect in these locales own their Material/Cupertino delegates, as with every other locale.

## 6.0.5

### Improvements

- **`dart:developer` console output:** Opt into DevTools-native structured logging with `ISpectBaseLogger(output: developerLogOutput)` — each entry becomes one `log()` call (boxed output stays intact) with the log level mapped through. The default `print`/console output is unchanged ([#85](https://github.com/yelmuratoff/ispect/issues/85)).

## 6.0.4

### Improvements

- **Pretty/boxed console logs:** Opt into framed, visually-separated console output via `ConsoleSettings(formatter: const BoxedLogEntryFormatter())`, or supply any custom `ILogEntryFormatter`. The compact default is unchanged ([#85](https://github.com/yelmuratoff/ispect/issues/85)).

## 6.0.3

### Bug Fixes

- **WebAssembly (WASM) support:** `ispect` is WASM-ready and supports all six platforms (Android, iOS, web, Windows, macOS, Linux). `flutter build web --wasm` now succeeds; log export uses the browser download on web and WASM, and the native filesystem on other platforms.

## 6.0.2

### Security

- **Redaction hardened across capture and export:** Sensitive keys are matched more broadly (camelCase and whitespace-trimmed forms), the default sensitive-key set is broadened, and credential/PII values are fully masked. Redaction now fails closed — a payload that can't be processed is masked rather than passed through.
- **Diagnostics redacted everywhere they leave the app:** Network URLs (including in generated cURL), database values and error messages, BLoC/Riverpod console output, navigation route arguments, and every export path (JSON, text, Markdown, file share, and clipboard copy) are redacted by default.
- **One-switch redaction control:** A single source of truth turns redaction on or off everywhere at once — `ISpectRedaction.enabled = false` (or `ISpect.run(redactionEnabled: false)`) disables masking across network, database, BLoC/Riverpod, navigation, and all export paths. On by default; disabling is a deliberate opt-out.
- **Inert in production builds:** When ISpect is compiled out (`ISPECT_ENABLED` omitted), observers stay silent and the global logger retains no history and writes nothing to the console, so diagnostics don't accumulate in release builds.

## 6.0.0

### Improvements

- **Owned dark theme by default:** ISpect now ships its own flat dark design across all surfaces — logs, JSON viewer, composer, sheets, inspector, and the performance overlay — independent of the host app, with a paired light variant. Choose the mode via `ISpectTheme.themeMode`, or set `ISpectTheme.useHostColors: true` to inherit the host `ColorScheme` as before.
- **Squircle surfaces:** Cards, buttons, fields, sheets, tiles, and the inspector overlay use continuous (squircle) corners for a smoother, more cohesive look.
- **`ispectify_riverpod`:** New package — `ISpectRiverpodObserver` logs provider lifecycle under `riverpod-*` keys (closes [#80](https://github.com/yelmuratoff/ispect/issues/80)).
- **Provider-agnostic `ispectify_ws`:** WebSocket diagnostics now log any client (`ws`, `socket_io_client`, and `web_socket_channel` adapters ship in the example), plus a new `ws-state` log type for connection lifecycle.
- **HTTP composer (mini-Postman):** Replay a captured request or compose a new one and send it through your own client via `ISpect.registerSender(...)`; the result lands back in the network logs. Redacted values are never resent.
- **Compact network URLs:** Collapsed transactions show only the path and query; the full URL stays in the expanded view. On by default, toggle in Settings.
- **Clearer network cards:** Per-method colored badges, a status-colored accent bar, de-duplicated expanded sections, and higher-contrast rows.
- **Richer widget inspector:** Property chips for composite values (offset, border, gradient, shadow), image/SVG source and decode details, correct selection boxes for rotated and skewed widgets, and grouped `RichText` spans.
- **`ISpectPerformanceOverlay` rebuilt:** Cross-platform (web + desktop) overlay with UI/raster/total bars, FPS, avg/p99 and jank stats, plus an opt-in `enableJankLogging` callback for severe frames.
- **Draggable panel 3.0.0:** More reliable hide/reveal and a content-sized adaptive layout; customize it fully via `ISpectOptions.panelBuilder`.
- **Export metadata:** `ISpectOptions.metadataProvider` embeds app/device details into exported and shared logs via the typed `ISpectMetadata` (host-supplied and not redacted — keep secrets and PII out).

### Behavioral Changes

- **BLoC observer keys:** Granular `bloc-event`, `bloc-transition`, `bloc-state`, `bloc-create`, `bloc-close`, `bloc-done`, `bloc-error` replace `state-change` / `state-error`, and `meta` keys are now kebab-case (`BlocJsonKeys.*`). Update any filters keyed on the old names.
- **Fuller payloads by default:** BLoC and Riverpod now log full event/state values instead of only the runtime type (`int → int` becomes `0 → 1`). Use `ISpectRiverpodSettings.compact`, or set BLoC's `printEventFullData` / `printStateFullData` to `false`, when state may carry PII. The old `ISpectBlocSettings.verbose` now matches the default and is deprecated.
- **`ISpect.run` uncaught-error hook:** Typed `onUncaughtError(Object error, StackTrace? stack)` replaces `onUncaughtErrors(List<dynamic>)`.
- **`ispectify_ws` drops the `ws` dependency:** Copy the adapter from the package example and add `ws` to your app; `ISpectWSInterceptorSettings` and the `ws-sent` / `ws-received` / `ws-error` keys are unchanged.

### Bug Fixes

- **Typed request bodies:** DTOs (e.g. Retrofit / `json_serializable` models) now render as their JSON shape instead of `Instance of ...` in `ispectify_dio` and `ispectify_ws` logs, with redaction reaching their nested fields.
- **`ispectify_dio`:** Responses no longer stay stuck on "Pending" when a downstream interceptor rewrites the request via `copyWith`.
- **Reliable error capture:** Flutter, platform, and zoned errors now report the original thrown object and stack trace, and `ISpect.run`'s `onInit` / `onInitialized` run inside the guarded zone so binding-setup errors are no longer dropped.
- **Navigation logging:** A page opened from under a modal (e.g. pushed from a bottom sheet) is logged as a page transition again instead of being dropped.
- **Logs screen reactivity:** "Clear history" empties the list immediately, and view-controller history changes refresh the UI without a new log emission.
- **Network status code shown again:** Grouped transactions display the response status-code chip (it was read from the wrong metadata key).
- **Color picker accuracy:** The sampled colour now matches the pixel under the crosshair, reports the true colour for translucent and anti-aliased pixels, and no longer drifts to a neighbour when you lift your finger.

### Code Quality

- **Sealed core classes:** Several data and utility classes (`LogDetails`, `RedactionResult`, `CurlUtils`, `JsonTruncator`, `NetworkPayloadSanitizer`, and others) are now `final` / `abstract final`. `RedactionService`, `ISpectErrorHandler`, `NetworkTransaction`, and the two log formatters stay open for subclassing.

## 5.0.4

### Added

- **Layout inspector breadcrumb:** The selected widget's hit-test ancestor chain (Row, Column, Stack, Padding, SizedBox, Align, and other meaningful render objects) is now surfaced as horizontally scrollable chips under the panel title. Tap any chip to re-target the inspector without re-tapping the screen.

### Improvements

- **Breadcrumb navigation:** Auto-scrolls the selected chip into view on every selection change, and uses clamping scroll physics so the list never overscrolls or bounces.

### Bug Fixes

- **Layout inspector — icon selection inside chips:** Material `ActionChip`, `Chip`, `FilterChip`, and `InputChip` previously routed every tap to the label slot, hiding the avatar `Icon` from the inspector path. Tapping the avatar now correctly selects it.

## 5.0.3

### Added

- The log viewer app bar now surfaces aggregate log statistics and a filter count badge, so active filters and totals are visible without opening the filter sheet.
- The JSON viewer breadcrumb bar auto-scrolls to the end as you drill in, keeping the current path segment in view on deep structures.

### Improvements

- The JSON viewer's path navigation got a visual refresh: updated segment colors, tighter spacing, and tap-to-jump segments. The breadcrumb bar moved to its own file for easier reuse.
- App bar leading icons gained consistent padding and dynamic width so action targets stay tappable across varied layouts.

### Fixed

- `ISpectSettingsState.toJson()` no longer throws when `disabled_log_types` is non-empty. `toMap()` now returns a `List<String>` for that field instead of an unmodifiable `Set`.

## 5.0.0

### Breaking Changes

- **Unified `trace()` pipeline:** All logging now flows through one structured pipeline with consistent correlation across every layer.
- **Flattened log data:** The old inheritance-based types are gone — typed subclasses (`NetworkRequestLog`, `DioResponseLog`, `BlocLifecycleLog`, …) are replaced by a metadata-driven `ISpectLogData`, with field accessors like `isNetwork` and `httpStatusCode` moved into extensions. See the migration guide below.
- **`ISpectLogType` is now a `final class`** (no longer an enum): `ISpectLogType.values` becomes `ISpectLogType.builtIn` and exhaustive switches no longer apply, but custom types are first-class — write `const ISpectLogType('my-key', category: 'firebase')` directly.
- **`ISpectLogData.id` is now a 26-character ULID** instead of a per-isolate int — globally unique, lexicographically sortable, and JSON round-trippable. Equality uses the id alone, which fixes deduplication of persisted history.

### Added

- **`ispect_layout`:** New standalone visual layout inspector — tap any widget to read its size, constraints, padding, decoration, text styles, transform, and clip shape, or compare two widgets for the pixel gap. Forked from [`inspector`](https://github.com/kekland/inspector) with expanded render-object coverage.
- **Plugin architecture for the panel:** Lifecycle hooks, custom screens, and action items, with `SafePluginScreen` and a global `ErrorWidget` override keeping third-party plugin failures from taking down the host UI.
- **Custom `ISpectLogType` instances** with their own category, title, color, and icon, safely merged with the built-in entries.
- **Database interceptor cookbook:** Drop-in interceptors and runnable examples for Hive, Isar, Drift, Sembast, ObjectBox, Realm, Firestore, Sqflite, SharedPreferences, GetStorage, and FlutterSecureStorage in `packages/ispectify_db/example`.

### Improvements

- **New trace API:** `trace()`, `traceAsync()`, `traceSync()`, and `traceTransaction()` for correlated logging, plus domain extensions (`authTrace()`, `storageTrace()`, `push()`, `analyticsEvent()`, `paymentTrace()`, `grpcTrace()`).
- **Log exporter:** Writes JSON Lines, plain text, Markdown, and CSV with built-in redaction; pluggable formatters give human-readable and JSON Lines output with ISO-8601 timestamps.
- **Logs screen overhaul:** Resizable desktop split view with keyboard navigation, chip-based search and filtering with category grouping, correlation/transaction-ID filters, expandable network transaction cards with status and duration, live tail with new-log indicators and relative time, 21 new log-type icons, and a JSON viewer with array support and async search.
- **Inspector controls:** Multi-key shortcuts, `initialPanelExpanded`, configurable `decimalPlaces`, smart panel positioning, shape-border and border-radius extraction, and globally-transformed hit testing.
- **Picker & zoom bar:** A floating Cancel/Confirm bar with zoom controls and a live hex preview chip (tap to copy), on-screen-aware hex placement, auto re-snapshot on surface resize, and the restored outside-stroke disc look.
- **`consoleMessage` parameter** on trace, network, WebSocket, and BLoC logs tailors IDE console output without touching structured metadata.
- **Lazy `ISpect.logger`:** Constructed on demand, with a developer warning when used before `ISpect.run`.
- **Wider redaction:** cURL commands and opt-in clipboard redaction now go through `RedactionService`, with optional redaction statistics for data and header operations.
- **Correlation index:** O(1) request/response/error lookup, removing scan-time matching on large histories.
- **Database tracing:** `DbSqlDigest` for normalized SQL grouping, `DbMessageFormatter` for consistent log construction, and new `sizeBytes` and `cacheHit` fields.
- **Accessibility:** Semantic labels on log cards and transactions, 36dp minimum touch targets, and tooltips on app-bar navigation, search, and filter.
- **Faster triage:** Expanded cards show a one-line metadata strip (id, trace source, operation/target, duration, exception type), and the action-sheet header shows the log type's description.

### Behavioral Changes

- **Network redaction on by default:** All network interceptors redact PII out of the box, using an expanded sensitive-key set.
- **`ISpectBlocObserver`** now auto-correlates events, transitions, and changes.
- **Auto-wired navigator observer:** `ISpectNavigatorObserver.observers()` publishes the installed observer in `ISpectNavigatorObserver.current`, and `ISpectBuilder.wrap` falls back to it — the quick-start no longer needs the same observer shared between `MaterialApp.navigatorObservers` and `ISpectOptions.observer`. An explicit `ISpectOptions.observer` still wins.
- **Tips dialog** moved from an automatic popup to a dedicated app-bar icon.

### Deprecations

- **`ISpectScopeController.of(context)`** → use `ISpect.read(context)`. The old method stays as a forwarder and will be removed in 6.0.0.
- **Per-callback network filters** (`requestFilter`, `responseFilter`, `errorFilter`) on `ispectify_dio`, `ispectify_http`, and `ispectify_ws` → use the new composable filter chain. Existing callbacks keep working as forwarders and will be removed in 6.0.0.
- **`ISpectBuilder(...)` constructor** → use `ISpectBuilder.wrap(...)`, which short-circuits before building when `kISpectEnabled` is false (preserving tree-shaking). The constructor will be made private in a stable 5.x release.
- **`ISpectLocalizations.delegates(...)`** → use `ISpectLocalizations.delegate(...)`, which returns only ISpect's delegate and leaves the `Global*Localizations` to the host. The legacy method works as a forwarder during 5.x and will be removed in 6.0.0.

### Bug Fixes

- **Async-gap context safety:** Fixed "deactivated widget's ancestor" errors in `ISpectToaster` and clipboard operations by handling `BuildContext` correctly across async gaps.
- **Stability:** Resolved memory leaks in UI components and made JSON parsing more robust on large datasets.
- **Export hardening:** Added CSV-injection protection in exports and a clipboard size cap.
- **Inspector hit testing:** Now uses Flutter's native pipeline and clamps overlay rects to screen bounds, so taps no longer surface widgets from routes beneath the active one (non-opaque pages, dialogs, modal sheets) or from `Offstage` / `IgnorePointer` subtrees, and selection stays on-screen.
- **Icon glyph rendering:** A `RenderParagraph` actually showing an icon font now displays the glyph and its `U+XXXX` code point under an `ICON` section instead of unreadable tofu.
- **Release-safe inspector:** `describeIdentity` and other diagnostic-only formatters were replaced with release-safe equivalents, so the layout inspector no longer throws or leaks debug data in profile and release builds.
- **JSON viewer state:** `JsonScreen.didUpdateWidget` compares the data's `id`, so the viewer no longer rebuilds its tree and discards expansion state when the parent supplies an equal map.

### CI/Tests

- **Tests & CI:** Refactored the suite for the trace-based architecture with JSON and multipart redaction validation, added widget tests (`ISpectAppBar`, `EmptyLogsWidget`, `LogCard`, `ISpectBuilder`) and BLoC/Dio/HTTP pipeline integration tests, and wired up Codecov with a Flutter version matrix.

### Migration Guide

```dart
// BEFORE (v4.x): Pattern matching on typed subclasses
if (log is NetworkRequestLog) {
  print(log.method);
  print(log.url);
}

// AFTER (v5.0): Use ISpectLogDataX convenience getters
import 'package:ispectify/ispectify.dart';
if (log.isNetwork) {
  print(log.traceOperation);  // HTTP method
  print(log.traceTarget);     // URL
  print(log.httpStatusCode);  // from traceMeta
}

// NEW: Trace API for custom operations
logger.traceAsync(
  category: authCategory,
  source: 'firebase',
  operation: 'signIn',
  run: () => auth.signIn(email, password),
);

// NEW: Domain extensions
logger.push(source: 'fcm', operation: 'received', messageId: id);
logger.analyticsEvent(source: 'firebase', event: 'purchase');
```

## 4.7.4

### Changes

- Removed explicit button styling from action sheet buttons to leverage theme defaults.

## 4.7.3

### Changes

- **JSON Truncation Limit:** Bump default JSON truncation limits for maximum depth, string length, and iterable size.

## 4.7.2

### Improvements

- **Web & WASM Compatibility:** Decoupled `dart:io` dependencies from core file utilities to ensure the `ispect` package works flawlessly on the Web and WASM targets. Native functionality remains unchanged.

## 4.7.1

### Changes

- **`ispectify`:** `time`, `error`, `stackTrace`, and `level` metadata are now passed through to native platform logs (`developer.log`) for better debugging and crash reporting.

## 4.7.0

### Breaking Changes

- **ISpect is now disabled by default.** For production safety and tree-shaking, ISpect is no longer compiled into builds unless you opt in with `--dart-define=ISPECT_ENABLED=true`. Without the flag, all ISpect logic, UI, and logging is removed from the binary at compile time, verified to tree-shake away in production builds.

### New Features

- **Zero-conditional API:** Factory methods handle the `kISpectEnabled` check internally — no `if/else` in your code. `ISpectBuilder.wrap()` returns the child when disabled, `ISpectNavigatorObserver.observers()` returns an empty list, and `ISpectLocalizations.delegates()` returns the base delegates.

  ```dart
  MaterialApp(
    localizationsDelegates: ISpectLocalizations.delegates(),
    navigatorObservers: ISpectNavigatorObserver.observers(),
    builder: (_, child) => ISpectBuilder.wrap(child: child!),
  );
  ```

- **Customizable observer:** `ISpectNavigatorObserver.observers()` also accepts a pre-configured `observer` plus `additional` observers.

### Migration

**Before (conditional):**

```dart
navigatorObservers: kISpectEnabled ? [ISpectNavigatorObserver()] : [],
builder: (_, child) {
  if (kISpectEnabled) return ISpectBuilder(...);
  return child!;
},
```

**After (zero-conditional):**

```dart
navigatorObservers: ISpectNavigatorObserver.observers(),
builder: (_, child) => ISpectBuilder.wrap(child: child!),
```

## 4.6.0

### Breaking Changes

- **API renaming:** `logCustom()` → `logData()`, `ISpectify` → `ISpectLogger`, `ISpectifyLogger` → `ISpectBaseLogger`, `ISpectifyFlutter` → `ISpectFlutter`.
- **`ISpectTheme` changes:** Log-type filtering moved to a `disabledLogTypes` set, light/dark colors unified under `ISpectDynamicColor(light:, dark:)`, and `logDescriptions` now takes a `Map<String, String>` for overriding default descriptions.

  ```dart
  ISpectTheme(
    disabledLogTypes: {'riverpod-add', 'riverpod-update'},
    background: ISpectDynamicColor(light: Colors.white, dark: Colors.black),
    logDescriptions: {'error': 'Critical application errors'},
  );
  ```

### New Features

- **Interceptor config:** Fluent API builders for interceptor settings and support for multiple observers.
- **Logging:** `additionalData` via a centralized `LogFactory`, proper `ISpectLogger` disposal, and full localization of BLoC error and provider-activity logs.
- **Persistent settings:** Log preferences are saved between sessions, with improved log-type filtering controls.
- **Strategy-based redaction:** Configure `RedactionService` with composite, key, and pattern strategies.
- **Platform abstraction:** File operations work across all supported targets via platform-aware directory handling.

### Improvements

- **Faster filtering:** Debounced log-filter updates, fixed-size lists for rendering, and cached contrast lookups in the JSON viewer.
- **Architecture:** Unified interceptor API across HTTP and WebSocket, `ISpectViewController` split into dedicated `FilterManager` / `SettingsManager` and explicit import/export services, a `PlatformOutput` output abstraction, and sealed models (`FileProcessingResult` and related) for type-safe error handling.

### Bug Fixes

- **Type safety:** Stronger typing across HTTP/Dio interceptors and the JSON selector, with unmodifiable cache views.
- **Memory:** Fixed widget memory leaks, object-pool lifecycle issues, and circular dependencies in the service graph.
- **Case-insensitive redaction:** Redaction now matches keys regardless of case.

## 4.4.7

### Added

- Web Live Demo link to README.md

### Changes

- Other minor updates and improvements.

## 4.4.6

### Changes

- Removed hard dependency on `share_plus` by introducing configurable share callbacks; all share flows now rely on `ISpectOptions.onShare`.
- Removed `open_filex` usage in favor of an optional `ISpectOptions.onOpenFile` callback.
- Conditionally render share/open actions across UI so buttons disappear when callbacks are not supplied.
- Eliminated external `provider`, `device_info_plus`, and `package_info_plus` dependencies; JSON explorer now ships with an internal selector.
- Feedback builder and `ispect_jira` package removed to streamline core functionality.
- Updated descriptions of log tags in the info bottom sheet for clarity and consistency.

### Added

- New `ISpectShareRequest`, `ISpectShareCallback`, and `ISpectOpenFileCallback` contracts to keep integrations package-free.
- Added `bloc-done` event logging to `ispectify_bloc` for comprehensive BLoC lifecycle tracking.
- Added `SuperSliverList` support in JSON/logs viewer for improved performance with large datasets.

## 4.4.2

### Added

- Added optional paramater `context` to `ISpectOptions`. This context is used to open `ISpect` screen.

## 4.4.1

### Changes

- `observer` parameter moved from `ISpectBuilder` to `ISpectOptions` for better consistency and usability.

## 4.4.0

### Added

- New package `ispectify_db`: lightweight database logging with tracing and transaction markers.
- cURL command copy functionality for HTTP logs in the log card, supporting both Dio and HTTP interceptors.

### Enhancements

- Stronger and more consistent redaction across HTTP/Dio/WS (incl. Base64/Base64URL, Unicode-friendly); versions synced across packages.

### Fixed

- ispectify_http: use `responseBody` in logs; separate request/response data; preserve non-Map error payloads; redact multipart fields/files (filenames masked).
- ispectify_dio: redact `FormData` in request/response (filenames masked); mark error logs with `LogLevel.error`.
- ispectify_ws: mark error logs with `LogLevel.error`.
- ispectify_db: no commit after rollback; correct log levels; safer `additionalData.value`.
- core: fix `_handleLog` constructor argument order.

### Tests

- HTTP: response body usage, array error payloads, multipart redaction.
- DB: rollback emits no commit; error/success log level assertions.

## 4.3.6

- Documentation updates

## 4.3.4

### Improvements

- **JSON viewer refactor:** Replaced the monolithic JSON-viewer services with specialized, instance-based search/cache/node services and an object pool for better performance on large JSON. Existing widget APIs stay backward-compatible.

### Fixed

- Resolved memory leaks in cache management and circular dependencies in service initialization.

## 4.3.2

### Added

- Optional redaction toggle in settings (enabled by default):
  - `ISpectDioInterceptorSettings.enableRedaction`
  - `ISpectHttpInterceptorSettings.enableRedaction`
  - `ISpectWSInterceptorSettings.enableRedaction`
- Redactor-aware serialization for network data models:
  - `ispectify_dio`: `DioRequestData.toJson`, `DioResponseData.toJson`, `DioErrorData.toJson` now accept an optional `RedactionService` and (when provided) redact headers, data, and metadata. Per-call `ignoredValues`/`ignoredKeys` supported.
  - `ispectify_http`: `HttpRequestData.toJson`, `HttpResponseData.toJson` updated similarly; redaction applied when a redactor is passed.

### Enhancements

- Apply centralized sensitive-data redaction consistently before logging and when serializing `additionalData` across `dio`/`http`/`ws` interceptors. Interceptors pass their redactor into model `toJson(...)` calls when redaction is enabled.
- `ispectify_dio`:
  - Request/response/error logs redact request headers/body, response headers/body, and common metadata (`query-parameters`, `extra`). `FormData` bodies are represented with a safe placeholder.
- `ispectify_http`:
  - Request/response logs redact headers and (when parsable) JSON/string bodies; multipart request details are preserved in shape while avoiding sensitive content.
- `ispectify_ws`:
  - Interceptor respects the redaction toggle and redacts sent/received payloads when enabled.

### Fixed

- Preserve response headers shape while redacting in `ispectify_dio` (`Map<String, List<String>>`) to avoid type/cast issues.

### Updates

- Update `draggable_panel` dependency to version 1.2.0. See what's changed in `draggable_panel`: https://pub.dev/packages/draggable_panel/changelog

## 4.3.0

### Added:

- Add `LogsJsonService` for structured `JSON` export/import of logs and integrate sharing/import features into `ISpectViewController` and UI.
- Implement `DailyFileLogHistory` for file-based log persistence with daily sessions and provide related screens for browsing and sharing sessions.
- Added `File Viewer` to settings sheet in `ISpect` screen to view and manage log files.
- `ispectify_ws` package for WebSocket _(ws package)_ logging with `ISpect` integration.

### Enhancements:

- Extend `ISpectFlutter.init` to accept custom `ILogHistory` instances and disable default print logging.
- Refactor file handlers _(web and native)_ to support configurable file types and `JSON` output.
- Make settings and info callback parameters optional in the app bar and conditionally render related UI.
- Add ability to open log files directly from the `ISpect` screen.

### Changes:

- Rename `ISpectLoggerDioLogger` to `ISpectDioInterceptor` for clarity and consistency with other interceptors
- Rename `ISpectLoggerHttpLogger` to `ISpectHttpInterceptor` and adjust its usage in the example project
- Rename `ISpectLoggerBlocObserver` to `ISpectBLocObserver` for consistency
- Rename `iSpectify` to `logger` and update related classes and documentation for consistency

## Draggable Panel

- Added: Position change listener API in `DraggablePanelController` (`addPositionListener` / `removePositionListener`).
- Added: Public `dockBoundary` getter for consistent boundary logic across widget and controller.
- Changed: `toggle()` now respects current `panelState` (not `initialPanelState`). Auto-toggle on mount removed to preserve user state. Initial position is clamped and (when starting closed) docked to the nearest edge.
- Fixed: Panel no longer resets to default after visibility toggles; duplicate position callbacks removed; unified docking logic.
- Performance: Batched x/y updates during drag via `setPosition(x, y)`; reduced redundant notifications and rebuilds; lifecycle safety (mounted checks) and controller rewire in `didUpdateWidget`.

## 4.2.0

### Added:

- Introduce navigation flow feature to visualize app route transitions.
- Ability to share log with the applied filters in the `ISpect` screen.

### Enhancements:

- Extend `ISpectNavigatorObserver` to buffer `RouteTransition` objects with unique IDs, timestamps, and structured logging using a `TransitionType` `enum`.
- Add `RouteTransition` data model, `List` extensions, and `routeName`/`routeType` extensions for richer route `metadata`.
- Improve `ISpectOptions` equality and `toString` implementations with `DeepCollectionEquality`.
- Toggle default `isLogModals` behavior to `false` for finer logging control.

## 4.1.9

### Changes:

- Replaced `LogScreen` with a generalized `ISpectJsonScreen`, which now accepts a `Map<String, dynamic>` `JSON` input directly instead of extracting it from an object.
- Refactored and migrated the `Color` to `hex` string conversion utility.
- Performed minor improvements and code cleanups.

## 4.1.7

### Changes:

- Minor updates and improvements.

## 4.1.6

### Changes:

- `ISpectPanelItem` -> `DraggablePanelItem`; `ISpectPanelButtonItem` -> `DraggablePanelButtonItem`.
- Added tooltip snackbar when long press on the panel buttons and items.
  Just add `description` field to the `DraggablePanelItem` or `DraggablePanelButtonItem` to show the tooltip.

## 4.1.5

### Enhancements:

- Refactor `InspectorState` to modularize main child, overlay builders, and zoom state handling
- Expose new zoom configuration constants and helper methods in `InspectorState` for enhanced zoom and overlay management

### Changes:

- Revise `README` instructions across all packages to showcase new initialization patterns _(e.g. ISpectFlutter.init, `ISpectJiraClient.initialize`)_
- Rename `ISpectLoggerActionItem` to `ISpectActionItem` and update references in docs and examples
- Add `ISpectPanelItem` and `ISpectPanelButtonItem` models and corresponding usage samples. `Records` -> `Models`
- Refresh quick start and advanced feature code snippets to illustrate updated APIs and options
- Unify headings _(Basic Setup, Custom Issue Creation, etc.)_ and standardize sample app flows

## 4.1.4

### Enhancements:

- Optimize `JSON` truncator to avoid expensive length calls, use correct recursion depth, and handle truncations efficiently
- Extend filter search to include map keys, prevent circular loops, and streamline filter combination logic
- Refine dotted separator painter to distribute dots evenly within container bounds

### CI:

- Upgrade `actions/checkout` to v4 with full fetch depth
- Harden validate_versions workflow with strict error handling, `version.config` and `VERSION` checks
- Switch grep to fixed-string mode and update workflow paths in `sync_versions_and_changelogs`
- Remove obsolete `update_changelogs.yml` file

## 4.1.3

### Infrastructure

- Added comprehensive version management system:
  - Created `version.config` as single source of truth for package versions
  - Added automated dependency synchronization between internal packages
  - Implemented CI/CD workflows for automatic version sync on changes
  - Added scripts for easy version bumping: patch, minor, major, dev versions
  - Created comprehensive documentation in VERSION_MANAGEMENT.md and VERSION.md
- Added validation for package versions:
  - Pre-commit hooks to prevent inconsistent versions
  - Automated checks for internal dependency consistency
  - Pull request validation for versions and changelogs

### Enhanced

- Refactored and improved optimization for handling very large JSON in the detailed log screen.
- Improved search and scroll to matched item functionality in the detailed log screen.

### Added

- Added a button for copying next to the JSON item (map/iterable) inside the detailed log screen.
- Added the ability to share the full log as a file .txt or quickly copy the truncated log to the clipboard.

### Changes

- UI changes in ISpect and log screens for better usability.
- Bumped dependencies to the latest versions.

## 4.1.2

### Added

- `itemsBuilder` to `ISpectOptions` for customizing the items in the `ISpect` screen.

### Changes

- Some other minor updates in the `ISpect` screen.
- Removed `ispect_device` additional package. Now it uses directly.

### Fixed

- Fixed some issues during clearing the cache.

## 4.1.1

### Added

- Add screen size utility to detect and adapt UI based on device screen
- Implement alternative dialog-based UI for larger screen sizes

### Fixed

- Fix issue displaying API fields correctly in the console

### Enhancements

- Implement responsive design for settings bottom sheet and log screens using screen size detection
- Improve search functionality in JSON viewer, added scrolling to the found element

### Changes

- Remove platform-specific configurations for Android and iOS in the example project
- Add macOS support for the example project

## 4.1.0

### Fixed

- Replace square bracket references with backticks in code comments and documentation across multiple packages to improve code documentation readability and consistency

## 4.0.9

### Added

- **JsonTruncatorService** for more robust JSON truncation and formatting
- Introduced more granular widget rendering strategies in JSON explorer

### Fixed

- Fixed potential performance bottlenecks in JSON rendering
- Improved error handling in JSON formatting and logging
- Fix analyzer issue for pub score

### Enhanced

- Refactored JSON attribute rendering to reduce widget rebuilds
- Improved performance of text highlighting in JSON viewer
- Optimized context selection and memoization in JSON explorer components

### Chore

- Cleaned up unused code and simplified complex rendering logic
- Improved code readability in JSON viewer components

## 4.0.8

### Fixed

- Fix analyzer issue for pub score

## 4.0.7

### Fixed

- Fixed not found image in README documentation

## 4.0.6

### Added

- **Custom Performance Overlay** - Changed the approach and some improvements
- **Enhanced Log Navigation** - Search, highlight, and expand/collapse functionality
- **New Option: `logTruncateLength`** - Available in `ISpectLoggerOptions` for configurable log truncation
- **New Configuration: `ISpectHttpInterceptorSettings`** - Added to `ISpectHttpInterceptor` for improved setup flexibility

### Improved

- **JSON Handling** - Async and lazy loading for better performance on large data structures
- **Log Card Refactor** - Improved readability and maintainability
- **Error Handling** - Added filtering for more precise issue tracking

### Fixed

- **Security Cleanup** - Removed `ispect_ai` package and related dependencies

## 4.0.5

### Changed

- Error display now limited to first 10,000 characters for large errors to prevent widget overload and application hanging

## 4.0.4

### Fixed

- Log description filtering method

## 4.0.3

### Added

- Localizations for: `es`, `fr`, `de`, `pt`, `ar`, `ko`, `ja`, `hi`

## 4.0.1

### Breaking Changes

- **`ISpectScopeWrapper` Relocation** - Moved inside `ISpectBuilder`. Now, `ISpectBuilder` serves as a one-stop solution
- **`ISpect.log()` Update** - Replaced with `ISpect.logger.log()` for improved consistency and clarity

### Added

- **Language Support** - Chinese (zh_CN) localization
- **JSON Log Viewer** - Detailed log viewing as a `JSON` tree structure
- **Enhanced HTTP Logs** - HTTP request logging displays all details in `JSON` tree format with search and filtering
- **Log Descriptions** - Added `logDescriptions` to `ISpectTheme` to add, modify, or disable descriptions in the info bottom sheet
- **Theme Scheme Screen** - Included basic `Theme Scheme Screen` in the `ISpect` panel for testing

### Improved

- **`ISpectLogger`:** Constructor now accepts optional components (`logger`, `observer`, `options`, `filter`, `errorHandler`, `history`) and a `configure` method to update an existing instance, with full dartdoc.
- **Bottom sheet:** Replaced `BaseBottomSheet` with a `DraggableScrollableSheet` (configurable `initial` / `min` / `max` sizes).
- **Filtering:** Added a search bar and `FilterChip`-based title filtering with managed enablement state.
- **Navigation logging:** Added flags to control logging of gestures, pages, modals, and other route types, plus a `validate` method to decide what gets logged.

## 3.0.3

### Updated

- Upgraded `draggable_panel` to version `1.0.2`

## 3.0.2

### Fixed

- Corrected `_output = output ?? log_output.outputLog`

## 3.0.1

### Fixed

- Added `DraggablePanelController` to `ISpectBuilder` for controlling the panel
  - See the example project for implementation details

## 3.0.0

### BREAKING CHANGES

- Forked the `Talker` package (where I'm actively contributing) and added it to `ISpect` as `ISpectLogger`
  - This was done to ease usage and reduce external dependencies
  - You can now use `ISpectLogger` to log all application actions

- Separated main functions into different packages:
  - `ispect_ai` - For using `AI` as a log reporter and log description generator (useful for managers and testers)
  - `ispect_jira` - For using `Jira` to create tickets directly in the application
  - `ispect_device` - For getting device data and related information
  - `ispectify_http` - For logging `HTTP` requests
  - `ispectify_dio` - For logging `Dio` requests
  - `ispectify_bloc` - For `BLoC` logging

  Please see usage examples in the respective packages or in `ispect/example`
  For questions, contact: `yelamanyelmuratov@gmail.com`

## 2.0.8

### Changed

- Removed `ISpectPanelButton` and `ISpectPanelItem` and replaced with Records
- Separated `DraggablePanel` into its own package: [draggable_panel](https://pub.dev/packages/draggable_panel)

## 2.0.7

### Breaking Changes

- Jira and AI tools are now separate packages:
  - Jira: [ispect_jira](https://pub.dev/packages/ispect_jira)See usage examples in [ispect_ai/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai/example)
  - ISpect AI: [ispect_ai](https://pub.dev/packages/ispect_ai)
    See usage examples in [ispect_jira/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_jira/example)

## 2.0.5

### Added

- Support to view MultiPart request and response in the Detailed HTTP Logs page (HTTP package)

## 2.0.4

### Added

- Support for `http` package - See the example project for implementation details

## 2.0.3

### Fixed

- `setState` during build inside `ISpectScreen` (ISpectLogger)

## 2.0.1

### Breaking Changes

- Removed `navigatorKey` - Now you can use `NavigatorObserver` for pin panel

## 2.0.0

### Fixed

- No Navigator in context when navigatorKey is not provided
- Panel height factor calculation

## 1.9.8

### Updated

- Upgraded `ISpectLogger` to v4.5.0

### Added

- Enhanced customization for `track` method:
  - Add analytics service name
  - Add event name

## 1.9.7

### Fixed

- Default icons now properly display when theme is null

## 1.9.6

### Fixed

- Keyboard now hides when user taps on the textfield in AI chat

### Changes

- `locale` and `ISpectOptions` are now optional fields

## 1.9.5

### Added

- New logging method: `ISpect.track` for custom analytics events (Amplitude, Firebase, etc.)
- Ability to change log colors and custom log icons

  Example: (SuccessLog is your custom log)

  ```dart
  theme: ISpectTheme(
      logColors: {
        SuccessLog.logKey: const Color(0xFF880E4F),
      },
      logIcons: {
        ISpectLogType.route.key: Icons.router_rounded,
        SuccessLog.logKey: Icons.check_circle_rounded,
      },
    ),
  ```

- Google AI integration for generating log descriptions and reports

### Changed

- `ISpect` replaced with `ISpect` - Use `ISpect` for all logging purposes
  Example: `ISpect.debug('Hello, ISpect!')` -> `ISpect.debug('Hello, ISpect!')`

## 1.9.3

### Added

- New option in `ISpectOptions`: `panelButtons` to add custom buttons to the panel
- New options for NavigatorObserver:
  - `isLogPages` - Toggle logging of page changes
  - `isLogModals` - Toggle logging of modal changes
  - `isLogOtherTypes` - Toggle logging of other change types
- `isFlutterPrintEnabled` option in ISpect.run to enable/disable Flutter print handler

## 1.9.2

### Added

- `ISpectNavigatorObserver` for navigation monitoring

## 1.8.9

### UI Updates

- Improved color picker
- Updated light log colors
- Revised ISpect page layout
- Combined actions and settings
- Various minor visual enhancements

## 1.8.6

### Added

- New option in `ISpectOptions`: `panelItems` to add custom icon buttons to the panel

## 1.8.2

### UI Improvements

- Raised color label in color picker
- Increased zoom scale factor to 3

## 1.7.9

### Changed

- Combined zoom and color picker functionality

## 1.7.7

### Added

- New draggable button with improved design and flow
- Additional Jira documentation

## 1.7.4

### Improved

- Log history features: copy all logs and share file

## 1.7.2

### Added

- Jira integration - Check the example project for implementation details
  (Will be added to formal documentation after testing)

### Fixed

- Deactivated widget error
- Removed unnecessary packages

## 1.7.1

### Added

- Updated Feedback builder for sending developer feedback
- Fixed localization issues when using Navigator inside Feedback

## 1.7.0

### Improved

- Log filtering mechanism
- Various minor enhancements

### Removed (Temporary)

- `Feedback` builder - Will return in a future release

## 1.6.6

### Updated

- Upgraded feedback_plus to version 0.1.2

## 1.6.5

### Fixed

- Issue with late iSpectify initialization

## 1.6.4

### Added

- ISpect's options to the ISpect's parameters

## 1.6.3

### Changed

- Implemented print handler
- Moved ISpect's initialization to the ISpect's run method
  (See example project for implementation details)

## 1.6.2

### Fixed

- String data handling in detailed HTTP page

## 1.6.0

### Updated

- Info text descriptions for logs inside `ISpectScreen`

## 1.5.9

### Added

- Context to `onTap` option for ISpectActionItem for routing to specific pages

## 1.5.7

### Added

- Info button for all logs

### Improved

- Darker background for Draggable button in light theme

## 1.5.6

### UI Adjustments

- Increased padding for Draggable button

## 1.5.5

### Fixed

- Issues with Draggable button
- Enable ISpect in release builds: manage conditions with `isISpectEnabled`

## 1.4.8

### Changed

- Removed shared preference (incompatible with shrink)
- Added parameters to ISpectBuilder for Draggable button customization

## 1.4.6

### Added

- New parameter `theme` in `ISpectScopeWrapper` for customizing ISpect page theme

## 1.4.4

### Added

- New parameter `actionItems` in `ISpectOptions` for adding custom actions to ISpect page's actions sheet

## 1.4.3

### Changed

- Initial ISpect page logs now collapsed by default

### Added

- New parameter `filters` for `initHandling` method
  - Filters work for `BLoC` and exceptions (`FlutterError`, `PlatformDispatcher`, `UncaughtErrors`)
  - Manual configuration required for Riverpod, routes, Dio, etc.

## 1.4.2

### Improved

- Draggable button functionality with new maximum reverse point
- Added localization for Detailed HTTP Logs page
- Minor updates to Detailed HTTP Logs page

## 1.4.0

### Added

- Detailed screens for HTTP logs (request, response, and error)

## 1.3.1

### Improved

- Refactored and optimized code
- Draggable button position now saved in cache
- Updated `analysis_options.yaml` file
- Updated `README.md` file

## 1.3.0

### Updated

- Options for `ISpect.initHandling` (applies to v1.2.8 and v1.2.9 as well)

## 1.2.7

### Added

- More customization options for `ISpect.initHandling`
  - Configure BLoC, Dispatcher error handling, and more during initialization

## 1.2.6

### Documentation

- Added video preview of the package

## 1.2.4

### Added

- New options for `ISpectLogger` detailed monitor page: reverse all logs and toggle expansion
- Moved performance tracker to `Draggable` button (removed from settings sheet)

## 1.2.3

### Changed

- `navigatorContext` no longer required for ISpectBuilder
  - To use Draggable button inside ISpectScreen, pass the key (not available by default)

## 1.2.0

### Updated

- Upgraded ISpectLogger to version 4.3.2

## 1.1.8

### Added

- Kazakh language support

## 1.1.7

### Refactored

- Feedback theme
- ISpect options theme

## 1.1.6

### Updated

- Refactored Riverpod logs on ISpectLogger Page
- Updated dependencies

## 1.1.5

### Added

- Riverpod logs

### Updated

- ISpectLogger Page and Feedback builder

## 1.1.2

### Fixed

- Light theme issues

### Removed

- `ISpectLoggerScreenTheme` (use ISpectOptions theme properties instead)

## 1.1.0

### Updated

- Dependencies to latest versions
- Refactored `ISpect`

## 1.0.8

### Updated

- Dependencies to latest versions
- Performed code formatting and refactoring
- Replaced default lints with `sizzle_lints`

## 1.0.5

### Changed

- Changed ISpectWrapper to builder and moved fields to Scope Wrapper

## 1.0.2

### Changed

- Moved inspector buttons to draggable buttons

## 1.0.1

### Added

- ISpectLocalization and cache management

## 1.0.0

### Initial Release

- Wrapper around Inspector, ISpectLogger, and related functionality
