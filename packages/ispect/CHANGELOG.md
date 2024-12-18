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
- Fix: `setState` during build inside `ISpectPage` (Talker).

## 2.0.1
- Breaking changes: `navigatorKey` is removed. Now you can use `NavigatorObserver` for pin panel.

## 2.0.0
- Fix: no Navigator in the context when navigatorKey is not provided.
- Fix: panel height factor fixed

## 1.9.8
- `Talker` was upgraded to v4.5.0.
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
- `ISpectTalker` replaced with `ISpect`. Now you can use `ISpect` for all logging purposes.  
Example: `ISpectTalker.debug('Hello, ISpect!')` -> `ISpect.debug('Hello, ISpect!')`.
- The ability to change the color of logs and custom log icons.  
Example: *(SuccessLog is your custom log)*  
```dart
    theme: ISpectTheme(
        logColors: {
          SuccessLog.logKey: const Color(0xFF880E4F),
        },
        logIcons: {
          TalkerLogType.route.key: Icons.router_rounded,
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
- Fix issue with late talker initialization.

## 1.6.4
- Added ISpectTalker's options to the ISpect's params.

## 1.6.3
- Implemented print handler and moved ISpectTalker's initialization to the ISpect's run method. Please check example project for better understanding.

## 1.6.2
- Handle if data is String inside detailed HTTP page.

## 1.6.0
- Updated info text description of logs inside `ISpectPage`.

## 1.5.9
- Added context to `onTap` option for TalkerActionItem for routing to a specific page.

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
- Initial ISpectTalker page logs are now collapsed by default.
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
- Updated options of `ISpectTalker.initHandling` (also applies to versions 1.2.8 and 1.2.9).

## 1.2.7
- Added more options to `ISpectTalker.initHandling`.
  - You can now customize more options during the initialization of `ISpectTalker`, such as BLoC, Dispatcher error, etc.

## 1.2.6
- Updated documentation: added a video preview of the package.

## 1.2.4
- Added some options to the `Talker` detailed monitor page: reverse all logs and toggle expansion.
- Moved performance tracker to the `Draggable` button and removed it from the settings sheet.

## 1.2.3
- `navigatorContext` is no longer required for ISpectBuilder.
  - To use the Draggable button inside ISpectPage, pass the key. By default, it is not possible to use the Draggable button inside ISpectPage.

## 1.2.0
- Upgraded Talker to version 4.3.2.

## 1.1.8
- Added Kazakh language support.

## 1.1.7
- Refactored feedback theme.
- Refactored options theme of ISpect.

## 1.1.6
- Refactored Riverpod logs on the Talker Page.
- Updated dependencies.

## 1.1.5
- Added Riverpod logs.
- Made updates to the Talker Page and Feedback builder.

## 1.1.2
- Fixed issues with the light theme.
- Removed `TalkerScreenTheme`. Use ISpectOptions theme properties instead.

## 1.1.0
- Upgraded dependencies to the latest version.
- Refactored `ISpectTalker`.

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
- Initial release: Wrapper around Inspector, Talker, etc.
