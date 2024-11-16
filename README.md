<div align="center">
<p align="center">
    <a href="https://github.com/K1yoshiSho/ispect" align="center">
        <img src="https://github.com/K1yoshiSho/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> A package combining Inspector, Talker, and more from pub.dev for efficient project implementation. 🚀 </h2>

<p align="center">
This package is not meant to be a groundbreaking innovation but rather a curated collection of high-quality tools from pub.dev, tailored for my future projects. I've decided to share it with the community in hopes it might be of use to others. It combines time-tested utilities and my personal enhancements aimed at improving project efficiency and adaptability.

As the underlying packages evolve, I plan to update and enhance this package, possibly adding new features based on community feedback and emerging needs. This package is meant to be a dynamic toolset that grows and improves over time, facilitating smoother development processes for Flutter developers.

Your feedback is highly valued as it will help shape future updates and ensure the package remains relevant and useful. 😊


   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/K1yoshiSho/ispect.git">star the repo</a> to support the project! </span>
</p>

<p align="center">
  <a href="https://pub.dev/packages/ispect"><img src="https://img.shields.io/pub/v/ispect.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/K1yoshiSho/ispect"><img src="https://hits.dwyl.com/K1yoshiSho/ispect.svg?style=flat" alt="Repository views"></a>
  <a href="https://github.com/K1yoshiSho/ispect"><img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/likes/ispect?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/popularity/ispect?logo=flutter" alt="Pub popularity"></a>
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/points/ispect?logo=flutter" alt="Pub points"></a>
</p>

<br>

## 📌 Features

- ✅ Draggable button for route to ISpect page, manage Inspector tools
- ✅ Localizations: ru, en, kk. *(I will add more translations in the future.)*
- ✅ Talker logger implementation: **BLoC**, **Dio**, **Routing**, **Provider**
- ✅ You can customize more options during initialization of ISpectTalker like BLoC, Dispatcher error and etc.
- ✅ Updated ISpectTalker page: added more options.
   - Detailed `HTTP` logs: `request`, `response`, `error`
   - Debug tools
   - Cache manager
   - Device and app info
- ✅ Feedback
- ✅ Performance tracker
- ✅ AI helper

## 📌 Getting Started
Follow these steps to use this package

### Add dependency

```yaml
dependencies:
  ispect: ^1.9.7
```

### Add import package

```dart
import 'package:ispect/ispect.dart';
import 'package:talker_flutter/talker_flutter.dart';
```

## Easy to use
Simple example of use `ISpect`<br>
You can manage ISpect using `ISpect.read(context)`.
Put this code in your project at an screen and learn how it works. 😊

<!-- <div style="display: flex; flex-direction: row; align-items: flex-start; justify-content: flex-start;">
  <img src="https://github.com/K1yoshiSho/packages_assets/blob/main/assets/ispect/ispect_upd_preview.gif?raw=true"
  alt="ISpect's example" width="250" style="margin-right: 10px;"/>
</div> -->

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


&nbsp;

### Instructions for use:

1. Wrap `runApp` with `ISpect.run` method and pass `Talker` instance to it.
2. Wrap your root widget with `ISpectScopeWrapper` widget to enable `ISpect` where you can pass theme and options.
3. Add `ISpectBuilder` widget to your material app's builder and put `navigatorKey`.

Please, check the example for more details.

Note:

- For enabling `ISpect AI helper`, you need to pass Google AI Api token to inside `ISpectOptions`.
See: [Google AI Studio](https://aistudio.google.com) for more details.
- For enabling `ISpect Jira`, you need to pass Jira Api data to inside `initialJiraData` from `ISpectBuilder`.
You must save the Jira data in the `onJiraAuthorized` callback. And you can use it in `initialJiraData`.

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
      talkerWrapper.route(location);
    });
```

### How to use Jira:
In order to go to the authorization page of Jira, you need to open ISpect, click on the **"burger menu"** *(Actions)* and open **"Jira"**. The first time you will be taken to the authorization page, the next time you will be taken to the Jira card creation page.  

- Next we will be greeted by the authorization page. As indicated, you will need to log in to Jira, click on your avatar and go to **"Manage account"**.
- Go to **"Settings"**.
- Scroll down to **"API tokens"** and click on **"Create and manage API tokens"**.
- And click on **"Create API token"**, copy and paste the token into the application.  

You should end up with something like this.
In the **"Project domain"** field enter domain like *"anydevkz"*, then the mail you use to log in to Jira. It can be found in the settings.
When you click on "Authorization" I will validate your data, if everything fits, you will have to select your active project. This can always be changed.  

Then you go back and when you go to the Jira page again, you will be taken to the task creation page.

This is where you select a project, as I mentioned above, this is an intermediate mandatory step. You choose a project and move on. But you can move on to another project if needed.  

Also, after authorization in Jira, you will have a **"Create Jira Issue"** button when describing an issue in the Feedback builder.
It will immediately take you to the issue creation page with a description of the issue you described and a screenshot attachment with all your drawings.

### Referenced packages:
A list of great packages I've used in ISpect:
[talker](https://pub.dev/packages/talker), 
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

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
<br>