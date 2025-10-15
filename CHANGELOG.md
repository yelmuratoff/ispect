# Changelog

## 4.4.5

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
- `ispectify_ws` package for WebSocket *(ws package)* logging with `ISpect` integration.

### Enhancements:

- Extend `ISpectifyFlutter.init` to accept custom `ILogHistory` instances and disable default print logging.
- Refactor file handlers *(web and native)* to support configurable file types and `JSON` output.
- Make settings and info callback parameters optional in the app bar and conditionally render related UI.
- Add ability to open log files directly from the `ISpect` screen.

### Changes:
- Rename `ISpectifyDioLogger` to `ISpectDioInterceptor` for clarity and consistency with other interceptors
- Rename `ISpectifyHttpLogger` to `ISpectHttpInterceptor` and adjust its usage in the example project
- Rename `ISpectifyBlocObserver` to `ISpectBLocObserver` for consistency
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
- Revise `README` instructions across all packages to showcase new initialization patterns *(e.g. ISpectifyFlutter.init, `ISpectJiraClient.initialize`)*
- Rename `ISpectifyActionItem` to `ISpectActionItem` and update references in docs and examples
- Add `ISpectPanelItem` and `ISpectPanelButtonItem` models and corresponding usage samples. `Records` -> `Models`
- Refresh quick start and advanced feature code snippets to illustrate updated APIs and options
- Unify headings *(Basic Setup, Custom Issue Creation, etc.)* and standardize sample app flows

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
- **New Option: `logTruncateLength`** - Available in `ISpectifyOptions` for configurable log truncation
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

### Updated ISpectify
- **Documentation** - Comprehensive documentation added to the `ISpectify` class
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
- Forked the `Talker` package (where I'm actively contributing) and added it to `ISpect` as `ISpectify`
  - This was done to ease usage and reduce external dependencies
  - You can now use `ISpectify` to log all application actions
  
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
  - Jira: [ispect_jira](https://pub.dev/packages/ispect_jira)  
    See usage examples in [ispect_ai/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai/example)
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
- `setState` during build inside `ISpectScreen` (ISpectify)

## 2.0.1

### Breaking Changes
- Removed `navigatorKey` - Now you can use `NavigatorObserver` for pin panel

## 2.0.0

### Fixed
- No Navigator in context when navigatorKey is not provided
- Panel height factor calculation

## 1.9.8

### Updated
- Upgraded `ISpectify` to v4.5.0

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
        ISpectifyLogType.route.key: Icons.router_rounded,
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
- New options for `ISpectify` detailed monitor page: reverse all logs and toggle expansion
- Moved performance tracker to `Draggable` button (removed from settings sheet)

## 1.2.3

### Changed
- `navigatorContext` no longer required for ISpectBuilder
  - To use Draggable button inside ISpectScreen, pass the key (not available by default)

## 1.2.0

### Updated
- Upgraded ISpectify to version 4.3.2

## 1.1.8

### Added
- Kazakh language support

## 1.1.7

### Refactored
- Feedback theme
- ISpect options theme

## 1.1.6

### Updated
- Refactored Riverpod logs on ISpectify Page
- Updated dependencies

## 1.1.5

### Added
- Riverpod logs

### Updated
- ISpectify Page and Feedback builder

## 1.1.2

### Fixed
- Light theme issues

### Removed
- `ISpectifyScreenTheme` (use ISpectOptions theme properties instead)

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
- Wrapper around Inspector, ISpectify, and related functionality
