<div align="center">
<p align="center">
    <a href="https://github.com/yelmuratoff/ispect" align="center">
        <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> An additional package for ISpect to interact with logs using Google Gemini AI. 🚀 </h2>

<p align="center">
An additional package for ISpect to interact with logs using Google Gemini AI.


   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/yelmuratoff/ispect.git">star the repo</a> to support the project! </span>
</p>

<p align="center">
  <a href="https://pub.dev/packages/ispect_ai"><img src="https://img.shields.io/pub/v/ispect_ai.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/K1yoshiSho/ispect"><img src="https://hits.dwyl.com/K1yoshiSho/ispect.svg?style=flat" alt="Repository views"></a>
  <a href="https://github.com/yelmuratoff/ispect"><img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/ispect_ai/score"><img src="https://img.shields.io/pub/likes/ispect_ai?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/ispect_ai/score"><img src="https://img.shields.io/pub/popularity/ispect_ai?logo=flutter" alt="Pub popularity"></a>
  <a href="https://pub.dev/packages/ispect_ai/score"><img src="https://img.shields.io/pub/points/ispect_ai?logo=flutter" alt="Pub points"></a>
</p>

<br>

## Packages
ISpect can be extended using other parts of this package <br>

| Package | Version | Description | 
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [ispect](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect) | [![Pub](https://img.shields.io/pub/v/ispect.svg?style=flat-square)](https://pub.dev/packages/ispect) | **Main** package of ISpect |
| [ispect_ai](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai) | [![Pub](https://img.shields.io/pub/v/ispect_ai.svg)](https://pub.dev/packages/ispect_ai) | An add-on package to use the **Gemini AI Api** to generate a `report` and `log` questions |
| [ispect_jira](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_jira) | [![Pub](https://img.shields.io/pub/v/ispect_jira.svg)](https://pub.dev/packages/ispect_jira) | An add-on package to use the **Jira Atlassian Api** to create issue tickets immediately via `Feedback` |


## 📌 Features

- ✅ Draggable button for route to ISpect page, manage Inspector tools
- ✅ Localizations: ru, en, kk. *(I will add more translations in the future.)*
- ✅ ISpectify logger implementation: **BLoC**, **Dio**, **http**, **Routing**, **Provider**
- ✅ You can customize more options during initialization of ISpect like BLoC, Dispatcher error and etc.
- ✅ Updated ISpect page: added more options.
   - Detailed `HTTP` logs: `request`, `response`, `error`
   - Debug tools
   - Cache manager
   - Device and app info
- ✅ Feedback
- ✅ Performance tracker
- ✅ AI helper

## 📜 Showcase

<div align="center">
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/panel.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/draggable.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/color_picker.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/feedback.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/logs.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/detailed_http_request.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/detailed_http_error.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/detailed_http_response.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/jira_auth.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/ai_chat.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/reporter.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/monitoring.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/cache.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/device_info.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/info.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/ispect/blob/main/assets/preview/inspector.png?raw=true" width="200" style="margin: 5px;" />
</div>

## 📌 Getting Started
Follow these steps to use this package

### Add dependency

```yaml
dependencies:
  ispect: ^2.0.7
  ispect_ai: ^0.0.3
```

### Add import package

```dart
import 'package:ispect/ispect.dart';
import 'package:ispect_ai/ispect_ai.dart';
```

## Easy to use

### Instructions for use:

1. Wrap `runApp` with `ISpect.run` method and pass `ISpectify` instance to it.
2. Initialize `ISpectGoogleAi` to `MaterialApp` and pass the Google Ai token.
For example, from an `.env` file or an environment variable.
```dart
ISpectGoogleAi.init('token');
```
3. In `actionItems` inside `ISpectOptions` add the corresponding Action buttons.
For example:
```dart
actionItems: [
          ISpectifyActionItem(
            title: 'AI Chat',
            icon: Icons.bubble_chart,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AiChatPage(),
                ),
              );
            },
          ),
          ISpectifyActionItem(
            title: 'AI Reporter',
            icon: Icons.report_rounded,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AiReporterPage(),
                ),
              );
            },
          ),
        ],
```
4. Add `ISpectAILocalization` to your `localizationsDelegates` in `MaterialApp`.
```dart
localizationsDelegates: ISpectLocalizations.localizationDelegates([
          ExampleGeneratedLocalization.delegate,
          ISpectAILocalization.delegate,
        ]),
```
5. Wrap your root widget with `ISpectScopeWrapper` widget to enable `ISpect` where you can pass theme and options.
6. Add `ISpectBuilder` widget to your material app's builder and put `NavigatorObserver`.

Please, check the [example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai/example) for more details.

>[!NOTE]
>
> - To add `ISpect Jira`, follow the instructions provided here [ispect_jira](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_jira).
>
> You can also check out an example of usage directly in [ispect_jira/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_jira/example).

```dart
### For change `ISpect` theme:
```dart
ISpect.read(context).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
```

### For handle routing (GoRouter)
You can use `ISpectNavigatorObserver`, but in practice it does not always work correctly with the `GoRouter` package. You need add observer in each GoRoute.
Alternatively, you can use a `listener`:

```dart
    _router.routerDelegate.addListener(() {
      final String location =
          _router.routerDelegate.currentConfiguration.last.matchedLocation;
      ISpect.route(location);
    });
```

### Referenced packages:
A list of great packages I've used in ISpect AI:
[path_provider](https://pub.dev/packages/path_provider), 
[device_info_plus](https://pub.dev/packages/device_info_plus), 
[share_plus](https://pub.dev/packages/share_plus), 
[package_info_plus](https://pub.dev/packages/package_info_plus), 
[gap](https://pub.dev/packages/gap), 
[auto_size_text](https://pub.dev/packages/auto_size_text), 
[feedback](https://pub.dev/packages/feedback), 
[inspector](https://pub.dev/packages/inspector), 
[performance](https://pub.dev/packages/performance), 
[cr_json_widget](https://pub.dev/packages/cr_json_widget).
[google_generative_ai](https://pub.dev/packages/google_generative_ai).
[flutter_markdown](https://pub.dev/packages/flutter_markdown).


<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
<br>