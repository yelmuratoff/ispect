# Changelog

## 4.1.2

### Added
- `itemsBuilder` to `ISpectOptions` for customizing the items in the `ISpect` screen.

### Changes
- Some other minor updates in the `ISpect` screen.
- Removed `ispect_device` additional package. Now it uses directly.

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
- **New Configuration: `ISpectifyHttpLoggerSettings`** - Added to `ISpectifyHttpLogger` for improved setup flexibility

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
- Context to `onTap` option for ISpectifyActionItem for routing to specific pages

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
