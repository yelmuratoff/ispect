# Changelog

## 4.0.6
  - Improved JSON handling with async and lazy loading for better performance on large structures.
  - Custom Performance Overlay to visualize frame timings and improve performance insights.
  - Added search, highlighting, and expand/collapse.
  - Log Card Refactoring to enhance readability and maintainability.
  - Improved error handling with filtering.
  - Added `logTruncateLength` to `ISpectifyOptions` for log truncation.
  - Removed `ispect_ai` package and dependencies due to security concerns.
  - Updated documentation and removed related references.

## 4.0.5
- Display of errors has been changed. Now, if the errors are large, only the first 10,000 characters will be displayed.
This is done in order not to overload the widget and not to cause the application to hang.

## 4.0.4
- Fixed the log description filtering method.

## 4.0.3
- Added localizations for: `es`, `fr`, `de`, `pt`, `ar`, `ko`, `ja`, `hi`.

## 4.0.1

### Major Changes
- **`ISpectScopeWrapper` Relocation**: Moved inside `ISpectBuilder`. Now, `ISpectBuilder` serves as a one-stop solution for all your needs. Refer to the example project for a clearer understanding.
- **`ISpect.log()` Update**: Replaced with `ISpect.logger.log()` for improved consistency and clarity.

### New Features
- **Language Support**: Added **Chinese (zh_CN)** localization.
- **JSON Log Viewer**: Introduced detailed log viewing as a `JSON` tree structure.
- **Enhanced HTTP Logs**: Updated HTTP request logging to display all details in a `JSON` tree format, with added search and filtering capabilities.
- **Log Descriptions**: Added `logDescriptions` to `ISpectTheme`. This allows you to add, modify, or disable descriptions in the info bottom sheet.
- **Theme Scheme Screen**: Included a basic `Theme Scheme Screen` in the `ISpect` panel for testing purposes.

### ISpectify Updates
- **Documentation**: Added comprehensive documentation to the `ISpectify` class.
- **Constructor Enhancement**: Modified to accept optional components (`logger`, `observer`, `options`, `filter`, `errorHandler`, `history`).
- **Configuration Method**: Introduced a `configure` method to update the configuration of an existing inspector instance.
- **Internal Logic**: Updated to leverage the new components and options effectively.

### Minor Updates & Improvements
- **Bottom Sheet Revamp**:
  - Removed `BaseBottomSheet` widget.
  - Implemented `DraggableScrollableSheet` with configurable `initial`, `min`, and `max` child sizes.
  - Updated the build method to integrate `DraggableScrollableSheet`.
  - Adjusted layout and styling for the new bottom sheet structure.
- **Filtering Enhancements**:
  - Added a `ValueNotifier` to manage filter enablement state.
  - Introduced a `SearchBar` for log filtering.
  - Replaced `InkWell` with `FilterChip` for title filtering.
  - Adjusted layout and styling to support new search and filter components.
- **Navigation Logging**:
  - Added properties to control logging of gestures, pages, modals, and other navigation types.
  - Updated `didPush`, `didReplace`, `didPop`, `didRemove`, and `didStartUserGesture` methods to log navigation events based on these properties.
  - Introduced a `validate` method to determine if a route should be logged based on its type.
  - Enhanced log messages with detailed route and argument information.

### Styling & Optimization
- Improved consistency in terminology and formatting.
- Streamlined descriptions for clarity and brevity.


## 3.0.3
- Upgrade version of `draggable_panel` to `1.0.2`.

## 3.0.2
- Fix:
   - Fixed `_output = output ?? log_output.outputLog;`.

## 3.0.1
- Fix:
   - Added `DraggablePanelController` to `ISpectBuilder` for controlling the panel.
   See the example project for more details.

## 3.0.0
- BREAKING CHANGES:
   - I forked the `Talker` package where I'm just as actively contributing and added it to `ISpect` as `ISpectify`. This was done for ease of use, and to not depend on external packages. You can now use `ISpectify` to log all actions in your application.
   - I have separated the main functions into different separate packages, so you can decide what you want to use.
      - `ispect_ai` - for using `AI` as a log reporter and log description generator. Useful for managers and testers.
      - `ispect_jira` - for using `Jira` to create tickets directly in the application.
      - `ispect_device` - for getting device data, etc.
      - `ispectify_http` - for logging `HTTP` requests.
      - `ispectify_dio` - for logging `Dio` requests.
      - `ispectify_bloc` - for `BLoC` logging.
   Please look at the usage examples in the corresponding packages. You can look at the usage example in `ispect/example`.
   For any questions you can write to my mail: `yelamanyelmuratov@gmail.com`.

## 2.0.8
- Now, `ISpectPanelButton` and `ISpectPanelItem` have been removed and replaced with Records.
Additionally, `DraggablePanel` has been separated into its own package and moved to [draggable_panel](https://pub.dev/packages/draggable_panel).

## 2.0.7
- Breaking change: Jira and AI tools are now separated into separate packages.
   - Jira: [ispect_jira](https://pub.dev/packages/ispect_jira)  
   You can also check out an example of usage directly in [ispect_ai/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai/example).
   - ISpect AI: [ispect_ai](https://pub.dev/packages/ispect_ai)  
   You can also check out an example of usage directly in [ispect_jira/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_jira/example).

## 2.0.5
- Feature: Support to view MultiPart request and response in the Detailed HTTP Logs page. (http package)

## 2.0.4
- Feature: Added support for `http` package. See the example project for more details.

## 2.0.3
- Fix: `setState` during build inside `ISpectScreen` (ISpectify).

## 2.0.1
- Breaking changes: `navigatorKey` is removed. Now you can use `NavigatorObserver` for pin panel.

## 2.0.0
- Fix: no Navigator in the context when navigatorKey is not provided.
- Fix: panel height factor fixed

## 1.9.8
- `ISpectify` was upgraded to v4.5.0.
- Now you can customize `track` method.
   - You can add analytic's service name.
   - You can add event's name.


## 1.9.7
- Fix: default icons not showed if theme is null.

## 1.9.6
- Fix: hided keyboard when the user taps on the textfield in the AI chat.
- Changes: `locale` and `ISpectOptions` now optional fields.

## 1.9.5
- Added new method for logging: `ISpect.track`. This method allows you to log custom events for analytics *(Amplitude, Firebase, etc.)*.
- `ISpect` replaced with `ISpect`. Now you can use `ISpect` for all logging purposes.  
Example: `ISpect.debug('Hello, ISpect!')` -> `ISpect.debug('Hello, ISpect!')`.
- The ability to change the color of logs and custom log icons.  
Example: *(SuccessLog is your custom log)*  
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
- Added Google AI to ISpect.
Use it if you need to use Google AI helper for generating logs description, and logs report.
- Some other minor updates.

## 1.9.3
- Added a new option to the `ISpectOptions` class: `panelButtons`. This option allows you to add new buttons to the panel.
- Added new options to the NavigatorObserver:
   - `isLogPages` - whether to log page changes.
   - `isLogModals` - whether to log modal changes.
   - `isLogOtherTypes` - whether to log other types of changes.
- Added `isFlutterPrintEnabled` option to the ISpect.run method. This option allows you to enable or disable the Flutter print handler.

## 1.9.2
- Added `ISpectNavigatorObserver` for navigation monitoring.

## 1.8.9
- UI updates:
   - Updated the color picker.
   - Updated light colors of logs.
   - Updated layout of the ISpect page.
   - Actions and settings now combined.
   - Other minor updates.

## 1.8.6
- Added a new option to the `ISpectOptions` class: `panelItems`. This option allows you to add new icon buttons to the panel.

## 1.8.2
- Raised the color label in the color picker.
- Increased the zoom scale factor to 3.

## 1.7.9
- Zoom and color picker was combined.

## 1.7.7
- New draggable button with a new design and flow.
- Added some documentation about Jira.

## 1.7.4
- Minor changes with history of logs: copy all logs and share file.
<!-- - Minor changes with draggable button, now it is possible to open after horizontal drag end. -->

## 1.7.2
- Added Jira to ISpect. Please check the example project for better understanding.
After some testing, I will release it as a stable version and add it to the documentation.
- Fixed deactivated widget error.
- Removed unnecessary packages.

## 1.7.1
- Updated Feedback builder added. Now you can use it to send feedback to the developer.
Note: I removed it because after inside Feedback I changed the Navigator to the normal Overlay the localization stopped working. This has been fixed.

## 1.7.0
- Improved log filtering.
- Some minor improvements.
- Temporary removed `Feedback` builder. It will be added in the next release.

## 1.6.6
- Upgraded feedback_plus to version 0.1.2.

## 1.6.5
- Fix issue with late iSpectify initialization.

## 1.6.4
- Added ISpect's options to the ISpect's params.

## 1.6.3
- Implemented print handler and moved ISpect's initialization to the ISpect's run method. Please check example project for better understanding.

## 1.6.2
- Handle if data is String inside detailed HTTP page.

## 1.6.0
- Updated info text description of logs inside `ISpectScreen`.

## 1.5.9
- Added context to `onTap` option for ISpectifyActionItem for routing to a specific page.

## 1.5.7
- Added info button for all logs.
- More darken background for the Draggable button in light theme.

## 1.5.6
- Increased padding for the Draggable button.

## 1.5.5
- Fix issues with Draggable button. Enable ISpect on the release build: manage confitions with `isISpectEnabled`.

## 1.4.8
- Removed shared preference because it is not work with shrink. So, now you can use parameters inside ISpectBuilder for manipulating the Draggable button.

## 1.4.6
- Added a new parameter `theme` to `ISpectScopeWrapper` for customizing the theme of the `ISpect` page.

## 1.4.4
- Added a new parameter `actionItems` to `ISpectOptions` for adding custom actions to the `ISpect` page's actions sheet.

## 1.4.3
- Initial ISpect page logs are now collapsed by default.
- Added a new parameter `filters` to the `initHandling` method. 
  - Filters work only for `BLoC` and exceptions such as `FlutterError`, `PlatformDispatcher`, and `UncaughtErrors`.
  - For Riverpod, routes, Dio, etc., manual configuration is required.

## 1.4.2
- Updated draggable button functionality with a new maximum reverse point.
- Added localization for the Detailed HTTP Logs page.
- Made minor updates to the Detailed HTTP Logs page.

## 1.4.0
- Introduced new feature: detailed screens for HTTP logs, including request, response, and error.

## 1.3.1
- Refactored and optimized the code.
- Draggable button's position is now saved in cache.
- Updated `analysis_options.yaml` file.
- Updated `README.md` file.

## 1.3.0
- Updated options of `ISpect.initHandling` (also applies to versions 1.2.8 and 1.2.9).

## 1.2.7
- Added more options to `ISpect.initHandling`.
  - You can now customize more options during the initialization of `ISpect`, such as BLoC, Dispatcher error, etc.

## 1.2.6
- Updated documentation: added a video preview of the package.

## 1.2.4
- Added some options to the `ISpectify` detailed monitor page: reverse all logs and toggle expansion.
- Moved performance tracker to the `Draggable` button and removed it from the settings sheet.

## 1.2.3
- `navigatorContext` is no longer required for ISpectBuilder.
  - To use the Draggable button inside ISpectScreen, pass the key. By default, it is not possible to use the Draggable button inside ISpectScreen.

## 1.2.0
- Upgraded ISpectify to version 4.3.2.

## 1.1.8
- Added Kazakh language support.

## 1.1.7
- Refactored feedback theme.
- Refactored options theme of ISpect.

## 1.1.6
- Refactored Riverpod logs on the ISpectify Page.
- Updated dependencies.

## 1.1.5
- Added Riverpod logs.
- Made updates to the ISpectify Page and Feedback builder.

## 1.1.2
- Fixed issues with the light theme.
- Removed `ISpectifyScreenTheme`. Use ISpectOptions theme properties instead.

## 1.1.0
- Upgraded dependencies to the latest version.
- Refactored `ISpect`.

## 1.0.8
- Upgraded dependencies to the latest version.
- Performed formatting and refactoring.
- Replaced default lints with `sizzle_lints`.

## 1.0.5
- Changed ISpectWrapper to builder, and moved fields to Scope Wrapper.

## 1.0.2
- Moved inspector buttons to draggable buttons.

## 1.0.1
- Added ISpectLocalization and cache management.

## 1.0.0
- Initial release: Wrapper around Inspector, ISpectify, etc.
