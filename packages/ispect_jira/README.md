
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
An add-on package to use the Jira Atlassian Api to create issue tickets immediately via Feedback.

   <br>
   <span style="font-size: 0.9em"> Show some ❤️ and <a href="https://github.com/yelmuratoff/ispect.git">star the repo</a> to support the project! </span>
</p>

<!----------------------------
-------------Badges-----------
------------------------------>

<p align="center">
  <a href="https://pub.dev/packages/ispect_jira"><img src="https://img.shields.io/pub/v/ispect_jira.svg" alt="Pub"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/yelmuratoff/ispect_jira"><img src="https://img.shields.io/github/stars/yelmuratoff/ispect_jira?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/ispect_jira/score"><img src="https://img.shields.io/pub/likes/ispect_jira?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/ispect_jira/score"><img src="https://img.shields.io/pub/points/ispect_jira?logo=flutter" alt="Pub points"></a>
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
- ✅ Localizations: kk, en, zh, ru, es, fr, de, pt, ar, ko, ja, hi. *(I will add more translations in the future.)*
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
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/feedback.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/logs.png?raw=true" width="200" style="margin: 5px;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/jira_auth.png?raw=true" width="200" style="margin: 5px;" />
</div>

<!----------------------------
--------Getting Started-------
------------------------------>

## 📌 Before you start using Inspect Jira
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


## 📌 Getting Started
Follow these steps to use this package

<!----------------------------
---------Instructions---------
------------------------------>

## Easy to use
Simple example of use `ISpect`<br>
You can manage ISpect using `ISpect.read(context)`.
Put this code in your project at an screen and learn how it works. 😊


### Instructions for use:

1. Wrap `runApp` with `ISpect.run` method and pass `ISpectify` instance to it.
2. Initialize `ISpectJiraClient` to `MaterialApp` and pass the necessary parameters.
For example, from local storage.
```dart
ISpectJiraClient.initialize(
      projectDomain: 'domain',
      userEmail: 'example@example.com',
      apiToken: 'token',
      projectId: '10007',
      projectKey: 'GTMS4',
    );
```
3. In `actionItems` inside `ISpectOptions` add the Jira Action button.
```dart
actionItems: [
          ISpectifyActionItem(
            title: 'ISpect',
            icon: Icons.bug_report_outlined,
            onTap: (context) {
              if (ISpectJiraClient.isInitialized) {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (_) => const JiraSendIssueScreen(),
                    settings: const RouteSettings(
                      name: 'Jira Send Issue Page',
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (_) => JiraAuthScreen(
                      onAuthorized: (domain, email, apiToken, projectId, projectKey) {
                        /// Save to local storage, for example `shared_preferences`
                      },
                    ),
                    settings: const RouteSettings(
                      name: 'Jira Auth Page',
                    ),
                  ),
                );
              }
            },
          ),
        ],
```
4. Add `ISpectJiraLocalization` to your `localizationsDelegates` in `MaterialApp`.
```dart
localizationsDelegates: ISpectLocalizations.localizationDelegates([
          ExampleGeneratedLocalization.delegate,
          ISpectJiraLocalization.delegate,
        ]),
```
5. Add `ISpectBuilder` widget to your material app's builder and put `NavigatorObserver`, `JiraFeedbackBuilder`.
```dart
child = ISpectBuilder(
            observer: observer,
            feedbackBuilder: (context, onSubmit, controller) => JiraFeedbackBuilder(
              onSubmit: onSubmit,
              theme: theme,
              scrollController: controller,
            ),
            initialPosition: (x: 0, y: 200),
            onPositionChanged: (x, y) {
              /// Save to local storage, for example `shared_preferences`
            },
            child: child,
          );
```

Please, check the [example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect/example) for more details.

>[!NOTE]
>
> - To add `ISpect AI helper`, follow the instructions provided here [ispect_ai](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai).
>
> You can also check out an example of usage directly in [ispect_ai/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_ai/example).
>
> - To `platform & device` tools follow the instructions provided here [ispect_device](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_device).
>
> You can also check out an example of usage directly in [ispect_device/example](https://github.com/yelmuratoff/ispect/tree/main/packages/ispect_device/example).

<!----------------------------
------Referenced packages-----
------------------------------>

<br>
<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
<br>