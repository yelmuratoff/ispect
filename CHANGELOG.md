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
