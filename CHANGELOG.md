# Changelog

## 5.2.0-dev.21

### Added

- **`ispectify_riverpod`:** New package — `ISpectRiverpodObserver` logs provider add/update/dispose/fail under `riverpod-*` keys (closes [#80](https://github.com/yelmuratoff/ispect/issues/80)).
- **Trace extensions:** `ISpectLoggerBloc` and `ISpectLoggerRiverpod` add one method per lifecycle event.
- **`ispectify_ws` is now provider-agnostic:** `WsDiagnostics` and the `WsDiagnosticsSink` port log any WebSocket client; ready-to-copy `ws`, `socket_io_client`, and `web_socket_channel` adapters ship in the package example.
- **WebSocket connection state:** New `ws-state` log type and `wsState` emitter capture connection-lifecycle transitions.

### Changed

- **BLoC observer keys:** Granular `bloc-event`, `bloc-transition`, `bloc-state`, `bloc-create`, `bloc-close`, `bloc-done`, `bloc-error` replace `state-change` / `state-error` — update filters keyed on the old names.
- **BLoC `meta` keys:** Now kebab-case; read them via `BlocJsonKeys.*`.
- **Riverpod `printValues` defaults to `true`:** Use `ISpectRiverpodSettings.compact` when provider state may carry PII.
- **`ISpect.run` uncaught-error hook:** `onUncaughtErrors` (`void Function(List<dynamic>)`) is replaced by typed `onUncaughtError` (`void Function(Object error, StackTrace? stack)`).
- **`ispectify_ws` drops the `ws` dependency:** `ISpectWSInterceptor` is no longer exported — copy the adapter from `ispectify_ws/example/lib/interceptors/ws_interceptor.dart` and add `ws` to your app. `ISpectWSInterceptorSettings` and the `ws-sent` / `ws-received` / `ws-error` keys are unchanged.

### Fixed

- **Typed request bodies:** DTOs passed as-is (e.g. Retrofit freezed/`json_serializable` models) now render as their JSON shape instead of `Instance of ...` in `ispectify_dio` and `ispectify_ws` logs; redaction now reaches their fields too. Rendering is recursive, so DTOs nested inside maps and lists (`json_serializable` without `explicitToJson`) are covered as well.
- **`ispectify_dio`:** Responses no longer stay stuck on "Pending" when a downstream interceptor rewrites the request via `copyWith`.
- **`ISpect.run` zone consistency:** `onInit` and `onInitialized` now run inside the guarded zone, so binding setup shares a zone with `runApp` and stops dropping errors via a "Zone mismatch".
- **Error capture shape:** Flutter, present, platform, and zoned errors all report the original thrown object and its stack trace; Flutter errors previously logged a stringified message.
- **Navigation logging:** A page opened from under a modal (e.g. a profile pushed from a bottom sheet) is now logged as a page transition governed by `isLogPages`, instead of being silently dropped as a "modal" transition.
- **Logs screen reactivity:** "Clear history" now empties the visible list immediately instead of after re-entering the screen; history mutations driven by the view controller refresh the UI without a new log emission.

### Improvements

- **Compact network URLs:** Grouped HTTP transactions show only the path and query in the collapsed list (full URL stays in the expanded view). Toggle via the Settings sheet or `ISpectSettingsState.compactNetworkUrls`; on by default.
- **Draggable panel upgraded to 3.0.0:** Reliable button hide/reveal and a content-sized adaptive layout that anchors to the button.
- **Customizable panel via `ISpectOptions.panelBuilder`:** Receive a prepared `ISpectPanelData` and return a `DraggablePanel` configured with any `draggable_panel` parameter.
- **Inspector property chips:** Composite values (offset, border, gradient, shadow) get inline labels, asymmetric radii render in a 2×2 grid, multi-shadows split per row, and `ImageFilter` descriptions are cleaned up.
- **Inspector selection box:** Correctly encloses rotated and skewed widgets, with the size label moved above the box.
- **Typography span grouping:** Multi-span `RichText` groups each span's chips under a preview of its text.
- **Sealed data and utility classes:** `LogDetails`, `ConsoleSettings`, `RedactionResult`, `HeaderRedactionResult`, `RedactionContext`, `RedactionStats`, `CurlUtils`, `JsonTruncator`, `NetworkPayloadSanitizer`, and `ISpectDateTimeFormatter` are now `final` / `abstract final` and can no longer be subclassed.
- **Formatters stay extendable:** `ExtendedLoggerFormatter` and `HumanLogEntryFormatter` are `base class` (`extends` still works); `RedactionService`, `ISpectErrorHandler`, and `NetworkTransaction` remain open.
- **`ISpectPerformanceOverlay` rebuilt:** Cross-platform overlay (web + desktop) with UI/raster/total bars, avg/p99/jank stats, current FPS, target line, and a freeze button; bottleneck-based FPS surfaces single hitches instead of averaging them away.
- **Jank diagnostics:** New `onJankBurst` callback and opt-in `enableJankLogging` (severe frames logged under `performance-jank` / `performance-error`); a perception threshold and 800 ms cold-start warmup keep false positives off the dropped-frame counter.
- **Overlay display options:** `compact: true` single-line summary, `showP90: true`, and a color-blind-safe palette via `ISpectPerformanceOverlayPalettes`.

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

- All logging now flows through a unified `trace()` pipeline. The pipeline produces structured data with consistent tracking across every layer of the app.
- Log data was flattened. The old inheritance-based types are gone, replaced by a metadata-driven `ISpectLogData` structure. Field accessors like `isNetwork` and `httpStatusCode` moved into extensions.
- Typed subclasses such as `NetworkRequestLog`, `DioResponseLog`, and `BlocLifecycleLog` have been removed. Use the new trace system instead.
- `ISpectLogType` is no longer an enum. It is now a `final class`, so `ISpectLogType.values` is gone in favour of `ISpectLogType.builtIn`, and exhaustive switch on its values is no longer possible. The upside is that custom types are first-class. You can write `const ISpectLogType('my-key', category: 'firebase')` directly.
- `ISpectLogData.id` is now a 26-character ULID string instead of a per-isolate auto-incrementing int. IDs are lexicographically sortable, globally unique across processes, isolates, and reloaded log files, and they survive JSON round-trips through the new optional `id` constructor parameter. Equality and `hashCode` use the id alone, so two entries with identical content are no longer considered equal. That fixes set and list deduplication on persisted history.

### Added

- A new `ispect_layout` package, a standalone visual layout inspector for Flutter. Tap any widget to read its size, constraints, padding, decoration, text styles, transform matrix, and clip shape. Compare two widgets to see the pixel gap between them. It is forked from [`inspector`](https://github.com/kekland/inspector) 4.1.0 and maintained inside the ISpect monorepo. On top of the upstream feature set it adds expanded render-object coverage (`RenderTransform` matrix decomposition, `RenderBackdropFilter`, every `RenderClip*`, `RenderEditable`), a wrapper-ancestors section for same-size proxies, gradient, shadow, and border-radius breakdowns, image-source introspection, a RichText preview, and a refactored `BoxInfoPanelWidget` split into testable extractor and widget modules.
- An extensible plugin architecture for the ISpect panel, with lifecycle hooks, custom screens, and action items. `SafePluginScreen` and a global `ErrorWidget` override keep third-party plugin failures from taking down the host UI.
- You can now define your own `ISpectLogType` instances with category, configurable title, color, and icon. Theme validation safely merges custom and built-in entries.
- A database interceptor cookbook with drop-in interceptors and runnable examples for Hive, Isar, Drift, Sembast, ObjectBox, Realm, Firestore, Sqflite, SharedPreferences, GetStorage, and FlutterSecureStorage in `packages/ispectify_db/example`.

### Improvements

- The new trace API adds `trace()`, `traceAsync()`, `traceSync()`, and `traceTransaction()` for flexible logging with correlation support.
- New domain extensions cover common operations, including `authTrace()`, `storageTrace()`, `push()`, `analyticsEvent()`, `paymentTrace()`, and `grpcTrace()`.
- The new log exporter writes JSON Lines, plain text, Markdown, and CSV, with redaction and security protection built in.
- The desktop layout was redesigned with a resizable split view, keyboard navigation, and persistent layout ratios.
- Search and filter were reworked. Field matching gets inline navigation, filters use chip-based selection and category grouping, and correlation IDs and transaction IDs are filterable directly from log details.
- Correlated network logs now appear as expandable transaction cards with status and duration indicators, plus dedicated transaction badges and detailed request and response views.
- Live tail picked up new-log indicators, scroll-to-edge support, and relative time formatting.
- 21 new icons and colors landed for various log types, and the JSON viewer gained array support and async search.
- Inspector controls now support multi-key `ShortcutActivator` shortcuts through Flutter `Shortcuts` and `Actions`, an `initialPanelExpanded` flag for default panel state, configurable `decimalPlaces`, smart panel positioning, shape-border and border-radius extraction for clipping and physical widgets, and globally-transformed hit testing for accurate overlap detection.
- The picker and zoom action bar swapped the tap-to-commit gesture for a floating Cancel and Confirm bar at the bottom of the screen. The bar includes zoom minus and plus controls, a live colour preview chip (hex value, tap to copy), and an adaptive compact layout that collapses labels on narrow screens.
- The colour picker's hex chip now picks the first side of the disc that fits fully on-screen, trying above, then right, then left, then below, instead of the previous binary above-or-right fallback. The readout no longer disappears when the picker hugs a corner.
- The picker and zoom snapshot is re-taken automatically when the surface size changes (desktop window resize, web layout shift, orientation change), so the loupe stays in sync with the live UI instead of showing stale pixels.
- The picker disc visual is back to the legacy strokeAlignOutside look. The image fills the full disc and three concentric strokes are painted outside the canvas with a soft drop shadow.
- Pluggable log formatters cover human-readable and JSON Lines output with ISO-8601 timestamps for console and exports.
- A new `consoleMessage` parameter on trace, network, WebSocket, and BLoC logs lets you tailor IDE console output without touching structured metadata.
- `ISpect.logger` is now constructed lazily and emits a developer warning when used before `ISpect.run`.
- Redaction reaches further. cURL commands go through `RedactionService`, `copyClipboard` supports opt-in clipboard redaction, and redaction statistics for data and header operations are available optionally.
- A new log correlation index gives O(1) request, response, and error lookup in the log screen, which removes scan-time matching on large histories.
- Database tracing picked up `DbSqlDigest` for normalized SQL grouping, `DbMessageFormatter` for consistent log construction, and new `sizeBytes` and `cacheHit` fields for performance insight.
- Accessibility improvements include semantic labels on log cards and transaction widgets, larger touch targets (36dp minimum), and tooltips on app bar navigation, search, and filter actions.
- Expanded log cards now show a single-line metadata strip under the title with id, trace source, operation or target, duration, and exception type. That removes a hop into the detail view for the most common triage info.
- The log action sheet displays the log type's description in its header, so you can confirm the type before opening the details.
- Action buttons on log cards shrank to 28dp with tighter context-menu tile spacing for higher density on phones.

### Behavioral Changes

- All network interceptors now have PII redaction enabled by default, using an expanded list of sensitive keys.
- `ISpectBlocObserver` automatically correlates events, transitions, and changes for easier debugging.
- The tips dialog moved from an automatic popup to a dedicated app bar icon.
- The navigator observer is auto-wired. `ISpectNavigatorObserver.observers()` now publishes the installed observer in `ISpectNavigatorObserver.current`, and `ISpectBuilder.wrap` falls back to it when `ISpectOptions.observer` is not provided. The quick-start no longer requires sharing the same observer instance between `MaterialApp.navigatorObservers` and `ISpectOptions.observer`. The navigation drill-down screen wires up automatically, and an explicit `ISpectOptions.observer` still wins.
- The developer warning previously emitted by `debugPrint` when `ISpect.logger` was accessed before `ISpect.run` or `ISpect.initialize` has been removed. The lazy fallback continues to return a default `ISpectLogger`. UI integration still requires explicit initialization.

### Deprecations

- `ISpectScopeController.of(context)` is deprecated in favour of the canonical `ISpect.read(context)`. The two were duplicate entry points to the same `InheritedNotifier` lookup. The old method remains as a forwarder and will be removed in 6.0.0.
- Per-callback network filters (`requestFilter`, `responseFilter`, `errorFilter`) on `ispectify_dio`, `ispectify_http`, and `ispectify_ws` are deprecated in favour of the new composable filter chain. Existing callbacks keep working as forwarders and will be removed in 6.0.0.
- The `ISpectBuilder(...)` constructor is deprecated in favour of `ISpectBuilder.wrap(...)`. The factory short-circuits before constructing the widget when `kISpectEnabled` is false, which preserves tree-shaking. The constructor defers the disabled-build short-circuit to `build()`, which keeps the state class reachable. The constructor will be made private in a stable 5.x release.
- `ISpectLocalizations.delegates(...)` is deprecated in favour of the new `ISpectLocalizations.delegate(...)`. The old method injects `GlobalMaterialLocalizations`, `Cupertino`, and `Widgets` alongside ISpect's delegate, which mutates the host app's localization stack even in release builds. The new method returns only ISpect's delegate concatenated with the host's list and leaves the Globals to the host. To migrate, list the three `Global*Localizations.delegate` entries yourself and spread `...ISpectLocalizations.delegate()` after them. The legacy method continues to work as a forwarder during 5.x and will be removed in 6.0.0.

### Bug Fixes

- Fixed critical "deactivated widget's ancestor" errors in `ISpectToaster` and clipboard operations by handling `BuildContext` correctly across async gaps.
- Resolved memory leaks in UI components and made JSON parsing more robust on large datasets.
- Added protection against CSV injection in exports and capped clipboard size to prevent memory issues.
- Inspector overlay rects and pointer coordinates are now clamped to screen bounds, which fixes off-screen tracking and out-of-viewport selection.
- The inspector uses Flutter's native hit-test pipeline, so taps no longer surface widgets from routes beneath the active one (non-opaque pages, dialogs, modal sheets) or from `Offstage` and `IgnorePointer` subtrees.
- When the selected `RenderParagraph` is actually rendering an icon (a single Private-Use-Area code point in `MaterialIcons`, `CupertinoIcons`, or a similar icon font), the info panel now shows the glyph itself plus its `U+XXXX` code point under an `ICON` section, instead of unreadable tofu under `TEXT`.
- `describeIdentity` and other diagnostic-only formatters were replaced with release-safe equivalents, so the layout inspector no longer throws or leaks debug data in profile and release builds.
- `JsonScreen.didUpdateWidget` now compares the data's `id` instead of object identity, so the viewer no longer rebuilds its node tree and discards expansion state when the parent supplies a fresh map with the same content.

### CI/Tests

- The test suite was refactored for the new trace-based architecture, with better validation for JSON and multipart redaction.
- Added widget tests for `ISpectAppBar`, `EmptyLogsWidget`, `LogCard`, and `ISpectBuilder`. Added integration tests for the BLoC, Dio, and HTTP logging pipelines, plus a comprehensive `ISpectBlocObserver` lifecycle and correlation suite.
- Integrated Codecov coverage reporting with a Flutter version matrix in CI and added a coverage badge to the README.
- Unified the testing and analysis workflows on GitHub Actions.

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

#### ispectify:

- `time`, `error`, `stackTrace`, and `level` metadata are now properly passed and displayed in native platform logs (`developer.log`) for better debugging and crash reporting.

## 4.7.0

### 🚨 IMPORTANT: Behavioral Changes

**ISpect is now DISABLED by default.**
To ensure production safety and enable effective tree-shaking, ISpect is no longer included in builds by default.

To enable ISpect, you **must** use the following build flag:

```bash
flutter run --dart-define=ISPECT_ENABLED=true
```

If the flag is not set (default), all ISpect-related logic, UI, and logging will be **completely removed** from your application binary during compilation.

### New Features

#### Zero-Conditional API

Factory methods that handle `kISpectEnabled` check internally — no `if/else` needed in your code:

```dart
void main() {
  ISpect.run(() => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers: ISpectNavigatorObserver.observers(),
      builder: (_, child) => ISpectBuilder.wrap(child: child!),
      home: const HomePage(),
    );
  }
}
```

**New methods:**

- `ISpectBuilder.wrap()` — returns child when disabled
- `ISpectNavigatorObserver.observers()` — returns empty list when disabled
- `ISpectLocalizations.delegates()` — returns base delegates when disabled

#### Enhanced Observer API

`ISpectNavigatorObserver.observers()` now accepts optional pre-configured observer for full customization:

```dart
navigatorObservers: ISpectNavigatorObserver.observers(
  observer: ISpectNavigatorObserver(
    onPush: (route, prev) => print('pushed'),
    onPop: (route, prev) => print('popped'),
    isLogGestures: true,
  ),
  additional: [AnalyticsObserver()],
),
```

---

### Security Improvements

#### Verified Tree-Shaking

Tested production builds show effective code removal:

| Build                     | APK Size | "ispect" strings |
| ------------------------- | -------- | ---------------- |
| Obfuscated Production     | 42.4 MB  | 5                |
| Non-obfuscated Production | 44.5 MB  | 34               |
| Development               | 51.0 MB  | 276              |

---

### Documentation

- Updated examples to use zero-conditional API
- Added security recommendations section

---

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

### 🚨 Breaking Changes

#### API Renaming

To improve consistency and clarity, several core classes and methods have been renamed:

**Methods:**

- `logCustom()` → `logData()` - Better reflects the purpose of logging custom data

**Classes:**

- `ISpectify` → `ISpectLogger` - More descriptive name for the main logger
- `ISpectifyLogger` → `ISpectBaseLogger` - Clarifies the base logger abstraction
- `ISpectifyFlutter` → `ISpectFlutter` - Shorter, cleaner naming

#### ISpectTheme API Changes

**1. Simplified log type filtering:**

```dart
// ❌ Before (verbose)
logDescriptions: [
  LogDescription(key: 'riverpod-add', isDisabled: true),
  LogDescription(key: 'riverpod-update', isDisabled: true),
],

// ✅ Now (clean and simple)
disabledLogTypes: {'riverpod-add', 'riverpod-update'},
```

**2. Unified color theming with `ISpectDynamicColor`:**

```dart
// ❌ Before (separate light/dark properties)
lightBackgroundColor: Colors.white,
darkBackgroundColor: Colors.black,
lightDividerColor: Colors.grey.shade300,
darkDividerColor: Colors.grey.shade800,

// ✅ Now (unified with ISpectDynamicColor)
background: ISpectDynamicColor(
  light: Colors.white,
  dark: Colors.black,
),
divider: ISpectDynamicColor(
  light: Colors.grey.shade300,
  dark: Colors.grey.shade800,
),
```

**3. Customizable log descriptions:**

`logDescriptions` now accepts `Map<String, String>` for overriding default descriptions:

```dart
ISpectTheme(
  logColors: {'error': Colors.red},
  logIcons: {'error': Icons.error},
  logDescriptions: {
    'error': 'Critical application errors',
    'info': 'Informational messages',
  },
)
```

---

### ✨ New Features

#### Interceptor Configuration

- **Fluent API builders** for cleaner interceptor settings configuration
- **Multiple observers support** with improved notification mechanism

#### Logging Enhancements

- **Enhanced context**: `additionalData` support with centralized `LogFactory`
- **Resource management**: Proper disposal functionality in `ISpectLogger`
- **Localization**: Full support for bloc error logs and provider activity across all languages

#### Settings & Filtering

- **Persistent settings**: Your log preferences are now saved between sessions
- **Advanced filtering**: Improved log type filtering with better UI controls

#### Security & Privacy

- **Strategy-based redaction**: Configure via `RedactionService` with composite, key, and pattern strategies
- **Comprehensive tests**: Unit tests for settings builders and redaction service

#### Platform Support

- **Platform abstraction**: File operations now work correctly across all supported targets via platform-aware directory handling

---

### 🔧 Improvements

#### Performance

- **70% faster filtering**: Log filter updates now use debouncing for dramatic performance gains
- **Optimized rendering**: Widget rendering and list creation now use fixed-size lists
- **Better caching**: JSON viewer uses cached contrast lookups for stable text rendering

#### Architecture

- **Unified logging interface**: Consistent API across HTTP and WebSocket interceptors
- **Cleaner separation**: `ISpectViewController` now uses dedicated `FilterManager`/`SettingsManager` and explicit import/export services
- **Platform-aware output**: All logging migrated to `PlatformOutput` abstraction
- **Sealed models**: `FileProcessingResult` and related JSON/observer models for type-safe error handling

#### Code Quality

- **Better initialization**: Logger now uses `addPostFrameCallback` for improved state management
- **Simplified logic**: Cleaner header redaction in `RedactionService`
- **Reduced duplication**: Improved code organization across all modules
- **Enhanced error handling**: More robust error handling and logging throughout

#### Documentation

- **Comprehensive guides**: Detailed usage examples and configuration guides added
- **Better comments**: Improved inline documentation for easier maintenance

---

### 🐛 Bug Fixes

#### Type Safety

- **HTTP/Dio interceptors**: Improved type safety across all interceptor implementations
- **JSON selector**: Enhanced null-safety and generic type constraints
- **Memory safety**: Unmodifiable cache views prevent accidental mutations

#### Performance & Memory

- **Widget optimization**: Fixed memory leaks in widgets and list creation
- **Object pool**: Resolved lifecycle management and performance issues
- **Circular dependencies**: Fixed initialization order in service dependency graph

#### Functionality

- **Case-insensitive redaction**: Redact method now handles keys regardless of case
- **Error handling**: More robust error handling across all modules

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

### Architecture Refactoring

- Refactored JSON viewer services
- Replaced monolithic services with specialized implementations:
  - Split `JsonViewerCacheService` into `SearchCacheService` and `NodeHierarchyCacheService`
  - Decomposed `JsonNodeService` into `NodeExpansionService`, `NodeCollapseService`, and `NodeNavigationService`
  - Implemented strategy pattern for `JsonSearchService` with pluggable search algorithms
  - Added universal object pool with dependency injection support
- Migrated from static method calls to instance-based service architecture
- Eliminated temporary v2 files, replaced legacy implementations

### Performance Improvements

- Object pooling reduces memory allocations by ~60% through reusable collections
- LRU caching improves search performance by ~80% with intelligent eviction
- Adaptive batch processing for large JSON datasets (80-300 items per batch)
- Widget memoization reduces unnecessary rebuilds by ~70%
- Automatic algorithm selection based on data characteristics
- Optimized UI update frequency to prevent performance degradation

### Technical Changes

- Implemented Facade pattern for unified service interfaces
- Added Factory pattern for flexible service instantiation
- Full dependency injection support for improved testability
- Real-time performance metrics and memory tracking
- Type-safe generic implementations for object pools and caches
- Separated cache management for search results and node hierarchy

### Core Component Updates

- Updated `JsonExplorerStore` to use new service architecture
- Migrated search operations from static to instance methods
- Integrated specialized cache services with clear boundaries
- Added comprehensive performance monitoring throughout the system

### Fixed

- Resolved memory leaks in cache management
- Fixed circular dependencies in service initialization
- Corrected object pool lifecycle management
- Eliminated performance bottlenecks in large JSON processing
- Improved testability by removing static dependencies

### Migration

- All legacy services replaced with new implementations
- Maintained backward compatibility for existing widget APIs
- Added comprehensive architecture documentation

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

### Updated ISpectLogger

- **Documentation** - Comprehensive documentation added to the `ISpectLogger` class
- **Constructor Enhancement** - Modified to accept optional components (`logger`, `observer`, `options`, `filter`, `errorHandler`, `history`)
- **Configuration Method** - Introduced `configure` method to update existing inspector instance configuration
- **Internal Logic** - Updated to leverage new components and options effectively

### Improved

- **Bottom Sheet Revamp**
  - Removed `BaseBottomSheet` widget
  - Implemented `DraggableScrollableSheet` with configurable `initial`, `min`, and `max` child sizes
  - Updated build method to integrate `DraggableScrollableSheet`
  - Adjusted layout and styling for new bottom sheet structure
- **Filtering Enhancements**
  - Added `ValueNotifier` to manage filter enablement state
  - Introduced `SearchBar` for log filtering
  - Replaced `InkWell` with `FilterChip` for title filtering
  - Adjusted layout and styling to support new search and filter components
- **Navigation Logging**
  - Added properties to control logging of gestures, pages, modals, and other navigation types
  - Updated `didPush`, `didReplace`, `didPop`, `didRemove`, and `didStartUserGesture` methods
  - Introduced `validate` method to determine if a route should be logged based on its type
  - Enhanced log messages with detailed route and argument information

### Styling & Optimization

- Improved consistency in terminology and formatting
- Streamlined descriptions for clarity and brevity

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
