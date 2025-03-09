Documentation will be updated soon
<!----------------------------
----------Logo & Title--------
------------------------------>
<div align="center">
<p align="center">
    <a href="https://github.com/yelmuratoff/ispect" align="center">
        <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> A Handy Toolkit for Mobile App Debugging 🚀 </h2>

<p align="center">
ISpect is a simple yet versatile library inspired by web inspectors, tailored for mobile application development.
An additional package for logging and handling Dio.

   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/yelmuratoff/ispect.git">star the repo</a> to support the project! </span>
</p>

<!----------------------------
-------------Badges-----------
------------------------------>

<p align="center">
  <a href="https://pub.dev/packages/ispect"><img src="https://img.shields.io/pub/v/ispect.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/yelmuratoff/ispect"><img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/likes/ispect?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/ispect/score"><img src="https://img.shields.io/pub/points/ispect?logo=flutter" alt="Pub points"></a>
</p>

<br>

<!----------------------------
--------Other packages--------
------------------------------>

## Packages
ISpect can be extended using other parts of this package <br>

| Package | Version | Description | 
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [ispect](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect) | [![Pub](https://img.shields.io/pub/v/ispect.svg?style=flat-square)](https://pub.dev/packages/ispect) | **Main** package of ISpect |
| [ispect_ai](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai) | [![Pub](https://img.shields.io/pub/v/ispect_ai.svg)](https://pub.dev/packages/ispect_ai) | An add-on package to use the **Gemini AI Api** to generate a `report` and `log` questions |
| [ispect_jira](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_jira) | [![Pub](https://img.shields.io/pub/v/ispect_jira.svg)](https://pub.dev/packages/ispect_jira) | An add-on package to use the **Jira Atlassian Api** to create issue tickets immediately via `Feedback` |
| [ispect_device](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_device) | [![Pub](https://img.shields.io/pub/v/ispect_device.svg)](https://pub.dev/packages/ispect_device) | An additional package for using tools to view platform & device info. |
| [ispectify](https://github.com/yelmuratoff/ispect/tree/main/packages/ispectify) | [![Pub](https://img.shields.io/pub/v/ispectify.svg)](https://pub.dev/packages/ispectify) | An additional package for logging and handling. Based on `Talker`. |
| [ispectify_bloc](https://github.com/yelmuratoff/ispect/tree/main/packages/ispectify_bloc) | [![Pub](https://img.shields.io/pub/v/ispectify_bloc.svg)](https://pub.dev/packages/ispectify_bloc) | An additional package for logging and handling `BLoC`. |
| [ispectify_dio](https://github.com/yelmuratoff/ispect/tree/main/packages/ispectify_dio) | [![Pub](https://img.shields.io/pub/v/ispectify_dio.svg)](https://pub.dev/packages/ispectify_dio) | An additional package for logging and handling `Dio`. |
| [ispectify_http](https://github.com/yelmuratoff/ispect/tree/main/packages/ispectify_http) | [![Pub](https://img.shields.io/pub/v/ispectify_http.svg)](https://pub.dev/packages/ispectify_http) | An additional package for logging and handling `http`. |

<!----------------------------
-----------Features-----------
------------------------------>

## 📌 Features

- ✅ Draggable panel for route to ISpect page and manage Inspector tools
You can also use it separately: https://pub.dev/packages/draggable_panel
- ✅ Localizations: kk, en, zh, ru. *(I will add more translations in the future.)*
- ✅ `ISpectify` logger *(inspired on `Talker`)* implementation: **BLoC**, **Dio**, **http**, **Routing**, **Provider**
- ✅ You can customize more options during initialization of ISpect like BLoC, Dispatcher error and etc.
- ✅ Updated ISpect page: added more options.
   - Detailed `HTTP` logs: `request`, `response`, `error`
   - Debug tools
   - Cache manager
   - Device and app info *([ispect_device](https://pub.dev/packages/ispect_device))*
- ✅ Feedback builder from [pub.dev/feedback](https://pub.dev/packages/feedback)
- ✅ Performance tracker
- ✅ AI helper

<!----------------------------
--------Showcase images-------
------------------------------>

## 📜 Showcase

<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/panel.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/draggable.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/color_picker.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/feedback.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/logs.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/monitoring.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/cache.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/device_info.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/info.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/inspector.png?raw=true" width="200" style="margin: 5px;" />
</div>

<!----------------------------
--------Getting Started-------
------------------------------>

## 📌 Getting Started
Follow these steps to use this package

## Easy to use
Simple example of use `ISpect`<br>
You can manage ISpect using `ISpect.read(context)`.
Put this code in your project at an screen and learn how it works. 😊


### Instructions for use:

1. Wrap `runApp` with `ISpect.run` method and pass `ISpectify` instance to it.
2. Add `ISpectBuilder` widget to your material app's builder and put `NavigatorObserver`.
3. Add `ISpectLocalizations` to your `localizationsDelegates` in `MaterialApp`.
```dart
localizationsDelegates: ISpectLocalizations.localizationDelegates([ // ISpect localization delegates
          ExampleGeneratedLocalization.delegate, // Your localization delegate
        ]),
```
4. Add `ISpectifyDioLogger` to the `Dio` instance form interceptors in the `onInit` method of `ISpect.run`.
```dart
onInit: (iSpectify) {
      dio.interceptors.add(
        ISpectifyDioLogger(
          iSpectify: ISpect.iSpectify,
        ),
      );
    },
```

Please, check the [example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect/example) for more details.

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
<br>