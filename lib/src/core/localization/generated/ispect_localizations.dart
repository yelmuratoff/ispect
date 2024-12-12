import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'ispect_localizations_en.dart';
import 'ispect_localizations_kk.dart';
import 'ispect_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ISpectGeneratedLocalization
/// returned by `ISpectGeneratedLocalization.of(context)`.
///
/// Applications need to include `ISpectGeneratedLocalization.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/ispect_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ISpectGeneratedLocalization.localizationsDelegates,
///   supportedLocales: ISpectGeneratedLocalization.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ISpectGeneratedLocalization.supportedLocales
/// property.
abstract class ISpectGeneratedLocalization {
  ISpectGeneratedLocalization(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ISpectGeneratedLocalization? of(BuildContext context) {
    return Localizations.of<ISpectGeneratedLocalization>(
        context, ISpectGeneratedLocalization);
  }

  static const LocalizationsDelegate<ISpectGeneratedLocalization> delegate =
      _ISpectGeneratedLocalizationDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru')
  ];

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @addingAttachmentsToIssue.
  ///
  /// In en, this message translates to:
  /// **'Adding attachments to issue'**
  String get addingAttachmentsToIssue;

  /// No description provided for @addingStatusToIssue.
  ///
  /// In en, this message translates to:
  /// **'Adding status to issue'**
  String get addingStatusToIssue;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @aiWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! How can I help you?'**
  String get aiWelcomeMessage;

  /// No description provided for @allLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'All logs copied in buffer'**
  String get allLogsCopied;

  /// No description provided for @analyticsLogDesc.
  ///
  /// In en, this message translates to:
  /// **'The log of sending events to the analytics service'**
  String get analyticsLogDesc;

  /// No description provided for @apiToken.
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get apiToken;

  /// No description provided for @appData.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get appData;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'Check device info & package info'**
  String get appInfo;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @attachmentsAdded.
  ///
  /// In en, this message translates to:
  /// **'Attachments added'**
  String get attachmentsAdded;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Go back to the main page'**
  String get backToHome;

  /// No description provided for @basicSettings.
  ///
  /// In en, this message translates to:
  /// **'Basic settings'**
  String get basicSettings;

  /// No description provided for @blocCloseLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Bloc close log'**
  String get blocCloseLogDesc;

  /// No description provided for @blocCreateLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Bloc creation log'**
  String get blocCreateLogDesc;

  /// No description provided for @blocEventLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Bloc event log'**
  String get blocEventLogDesc;

  /// No description provided for @blocTransitionLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Bloc state transition log'**
  String get blocTransitionLogDesc;

  /// No description provided for @buildVersion.
  ///
  /// In en, this message translates to:
  /// **'Build version'**
  String get buildVersion;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size: {size}'**
  String cacheSize(Object size);

  /// No description provided for @changeEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Change current environment'**
  String get changeEnvironment;

  /// No description provided for @changeProject.
  ///
  /// In en, this message translates to:
  /// **'Change project'**
  String get changeProject;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get changeTheme;

  /// No description provided for @cleanHistory.
  ///
  /// In en, this message translates to:
  /// **'Clean history'**
  String get cleanHistory;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @collapseLogs.
  ///
  /// In en, this message translates to:
  /// **'Collapse logs'**
  String get collapseLogs;

  /// No description provided for @common.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get common;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy all logs'**
  String get copyAllLogs;

  /// No description provided for @counterTimesText.
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times: {number}'**
  String counterTimesText(Object number);

  /// No description provided for @createIssue.
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get createIssue;

  /// No description provided for @createJiraIssue.
  ///
  /// In en, this message translates to:
  /// **'Create Jira Issue'**
  String get createJiraIssue;

  /// No description provided for @creatingIssue.
  ///
  /// In en, this message translates to:
  /// **'Creating issue'**
  String get creatingIssue;

  /// No description provided for @criticalLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Critical error log'**
  String get criticalLogDesc;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @debugLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Debug message log'**
  String get debugLogDesc;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @environmentTapNumber.
  ///
  /// In en, this message translates to:
  /// **'To open the dialog, it remains: {number}'**
  String environmentTapNumber(Object number);

  /// No description provided for @errorCacheClearing.
  ///
  /// In en, this message translates to:
  /// **'Error on clearing cache'**
  String get errorCacheClearing;

  /// No description provided for @errorLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Error log'**
  String get errorLogDesc;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error message'**
  String get errorMessage;

  /// No description provided for @errorType.
  ///
  /// In en, this message translates to:
  /// **'Error type'**
  String get errorType;

  /// No description provided for @exceptionLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Exception log'**
  String get exceptionLogDesc;

  /// No description provided for @expandLogs.
  ///
  /// In en, this message translates to:
  /// **'Expand logs'**
  String get expandLogs;

  /// No description provided for @feedbackDescriptionText.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get feedbackDescriptionText;

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get fieldIsRequired;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get fix;

  /// No description provided for @fullURL.
  ///
  /// In en, this message translates to:
  /// **'Full URL'**
  String get fullURL;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate a report'**
  String get generateReport;

  /// No description provided for @goToLogger.
  ///
  /// In en, this message translates to:
  /// **'Go to logger'**
  String get goToLogger;

  /// No description provided for @goodLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Successful action log'**
  String get goodLogDesc;

  /// No description provided for @headers.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get headers;

  /// No description provided for @hidePanel.
  ///
  /// In en, this message translates to:
  /// **'Hide panel'**
  String get hidePanel;

  /// No description provided for @httpErrorLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Server request error log'**
  String get httpErrorLogDesc;

  /// No description provided for @httpRequestLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Server request log'**
  String get httpRequestLogDesc;

  /// No description provided for @httpResponseLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Server response log'**
  String get httpResponseLogDesc;

  /// No description provided for @infoLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Informational message log'**
  String get infoLogDesc;

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed'**
  String get initializationFailed;

  /// No description provided for @issueCreated.
  ///
  /// In en, this message translates to:
  /// **'Issue successfully created'**
  String get issueCreated;

  /// No description provided for @jiraInstruction.
  ///
  /// In en, this message translates to:
  /// **'1. Go to your Jira website.\n2. Click on your Profile avatar in the bottom left corner.\n3. Click on Profile.\n4. Click Manage your account.\n5. Select Security.\n6. Scroll down to Create and manage API tokens and click on it.\n7. Create a token, then copy and paste it.'**
  String get jiraInstruction;

  /// No description provided for @logItemCopied.
  ///
  /// In en, this message translates to:
  /// **'Log item is copied in clipboard'**
  String get logItemCopied;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @logsCount.
  ///
  /// In en, this message translates to:
  /// **'Logs count'**
  String get logsCount;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'not found'**
  String get notFound;

  /// No description provided for @otherLogsForDevelopers.
  ///
  /// In en, this message translates to:
  /// **'Other logs are already being used by developers'**
  String get otherLogsForDevelopers;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Oops, the page on this path'**
  String get pageNotFound;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @performanceTracker.
  ///
  /// In en, this message translates to:
  /// **'Performance tracking'**
  String get performanceTracker;

  /// No description provided for @pickedImages.
  ///
  /// In en, this message translates to:
  /// **'Picked images'**
  String get pickedImages;

  /// No description provided for @pleaseAuthToJira.
  ///
  /// In en, this message translates to:
  /// **'Please authorize to Jira'**
  String get pleaseAuthToJira;

  /// No description provided for @pleaseCheckAuthCred.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred. Please check the authorization data.'**
  String get pleaseCheckAuthCred;

  /// No description provided for @pleaseSelectYourProject.
  ///
  /// In en, this message translates to:
  /// **'Now, please select a project'**
  String get pleaseSelectYourProject;

  /// No description provided for @printLogDesc.
  ///
  /// In en, this message translates to:
  /// **'The log of the standard print method in Flutter'**
  String get printLogDesc;

  /// No description provided for @projectDomain.
  ///
  /// In en, this message translates to:
  /// **'Project domain'**
  String get projectDomain;

  /// No description provided for @projectWasSelected.
  ///
  /// In en, this message translates to:
  /// **'Project was selected'**
  String get projectWasSelected;

  /// No description provided for @requestHeaders.
  ///
  /// In en, this message translates to:
  /// **'Request headers'**
  String get requestHeaders;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reverseLogs.
  ///
  /// In en, this message translates to:
  /// **'Reverse logs'**
  String get reverseLogs;

  /// No description provided for @riverpodAddLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Provider addition log'**
  String get riverpodAddLogDesc;

  /// No description provided for @riverpodDisposeLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Provider disposal log'**
  String get riverpodDisposeLogDesc;

  /// No description provided for @riverpodFailLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Provider error log'**
  String get riverpodFailLogDesc;

  /// No description provided for @riverpodUpdateLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Provider update log'**
  String get riverpodUpdateLogDesc;

  /// No description provided for @routeLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Screen navigation log'**
  String get routeLogDesc;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @selectAssignee.
  ///
  /// In en, this message translates to:
  /// **'Select assignee'**
  String get selectAssignee;

  /// No description provided for @selectBoard.
  ///
  /// In en, this message translates to:
  /// **'Select board'**
  String get selectBoard;

  /// No description provided for @selectIssueType.
  ///
  /// In en, this message translates to:
  /// **'Select issue type'**
  String get selectIssueType;

  /// No description provided for @selectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select label'**
  String get selectLabel;

  /// No description provided for @selectPriority.
  ///
  /// In en, this message translates to:
  /// **'Select priority'**
  String get selectPriority;

  /// No description provided for @selectSprint.
  ///
  /// In en, this message translates to:
  /// **'Select sprint'**
  String get selectSprint;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select status'**
  String get selectStatus;

  /// No description provided for @sendIssue.
  ///
  /// In en, this message translates to:
  /// **'Send issue'**
  String get sendIssue;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareLogsFile.
  ///
  /// In en, this message translates to:
  /// **'Share logs file'**
  String get shareLogsFile;

  /// No description provided for @statusCode.
  ///
  /// In en, this message translates to:
  /// **'Status code'**
  String get statusCode;

  /// No description provided for @statusMessage.
  ///
  /// In en, this message translates to:
  /// **'Status message'**
  String get statusMessage;

  /// No description provided for @submitButtonText.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButtonText;

  /// No description provided for @successfullyAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You have successfully logged in'**
  String get successfullyAuthorized;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @talkerBlocClosesCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC closes count: {text}'**
  String talkerBlocClosesCount(Object text);

  /// No description provided for @talkerBlocCreatesCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC creates count: {text}'**
  String talkerBlocCreatesCount(Object text);

  /// No description provided for @talkerBlocEventsCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC events count: {text}'**
  String talkerBlocEventsCount(Object text);

  /// No description provided for @talkerBlocTransitionCount.
  ///
  /// In en, this message translates to:
  /// **'BLoC transitions count: {text}'**
  String talkerBlocTransitionCount(Object text);

  /// No description provided for @talkerHttpFailuresCount.
  ///
  /// In en, this message translates to:
  /// **'HTTP failure logs count: {text}'**
  String talkerHttpFailuresCount(Object text);

  /// No description provided for @talkerHttpRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'HTTP request logs count: {text}'**
  String talkerHttpRequestsCount(Object text);

  /// No description provided for @talkerHttpResponsesCount.
  ///
  /// In en, this message translates to:
  /// **'HTTP response logs count: {text}'**
  String talkerHttpResponsesCount(Object text);

  /// No description provided for @talkerLogsInfo.
  ///
  /// In en, this message translates to:
  /// **'Info about logs'**
  String get talkerLogsInfo;

  /// No description provided for @talkerRiverpodAddCount.
  ///
  /// In en, this message translates to:
  /// **'Riverpod adds count: {text}'**
  String talkerRiverpodAddCount(Object text);

  /// No description provided for @talkerRiverpodDisposeCount.
  ///
  /// In en, this message translates to:
  /// **'Riverpod disposes count: {text}'**
  String talkerRiverpodDisposeCount(Object text);

  /// No description provided for @talkerRiverpodFailsCount.
  ///
  /// In en, this message translates to:
  /// **'Riverpod fails count: {text}'**
  String talkerRiverpodFailsCount(Object text);

  /// No description provided for @talkerRiverpodUpdateCount.
  ///
  /// In en, this message translates to:
  /// **'Riverpod updates count: {text}'**
  String talkerRiverpodUpdateCount(Object text);

  /// No description provided for @talkerTypeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Event logging method'**
  String get talkerTypeAnalytics;

  /// No description provided for @talkerTypeAnalyticsCount.
  ///
  /// In en, this message translates to:
  /// **'Number of track logs: {text}'**
  String talkerTypeAnalyticsCount(Object text);

  /// No description provided for @talkerTypeBloc.
  ///
  /// In en, this message translates to:
  /// **'BLoC'**
  String get talkerTypeBloc;

  /// No description provided for @talkerTypeDebug.
  ///
  /// In en, this message translates to:
  /// **'Verbose & debug'**
  String get talkerTypeDebug;

  /// No description provided for @talkerTypeDebugCount.
  ///
  /// In en, this message translates to:
  /// **'Verbose and debug logs count: {text}'**
  String talkerTypeDebugCount(Object text);

  /// No description provided for @talkerTypeErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get talkerTypeErrors;

  /// No description provided for @talkerTypeErrorsCount.
  ///
  /// In en, this message translates to:
  /// **'Error logs count: {text}'**
  String talkerTypeErrorsCount(Object text);

  /// No description provided for @talkerTypeExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get talkerTypeExceptions;

  /// No description provided for @talkerTypeExceptionsCount.
  ///
  /// In en, this message translates to:
  /// **'Exception logs count: {text}'**
  String talkerTypeExceptionsCount(Object text);

  /// No description provided for @talkerTypeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get talkerTypeGood;

  /// No description provided for @talkerTypeGoodCount.
  ///
  /// In en, this message translates to:
  /// **'Good logs count: {text}'**
  String talkerTypeGoodCount(Object text);

  /// No description provided for @talkerTypeHttp.
  ///
  /// In en, this message translates to:
  /// **'HTTP requests'**
  String get talkerTypeHttp;

  /// No description provided for @talkerTypeInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get talkerTypeInfo;

  /// No description provided for @talkerTypeInfoCount.
  ///
  /// In en, this message translates to:
  /// **'Info logs count: {text}'**
  String talkerTypeInfoCount(Object text);

  /// No description provided for @talkerTypePrint.
  ///
  /// In en, this message translates to:
  /// **'Print method'**
  String get talkerTypePrint;

  /// No description provided for @talkerTypePrintCount.
  ///
  /// In en, this message translates to:
  /// **'Print method logs count: {text}'**
  String talkerTypePrintCount(Object text);

  /// No description provided for @talkerTypeProvider.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get talkerTypeProvider;

  /// No description provided for @talkerTypeProviderCount.
  ///
  /// In en, this message translates to:
  /// **'Provider logs count: {text}'**
  String talkerTypeProviderCount(Object text);

  /// No description provided for @talkerTypeRiverpod.
  ///
  /// In en, this message translates to:
  /// **'Riverpod'**
  String get talkerTypeRiverpod;

  /// No description provided for @talkerTypeWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get talkerTypeWarnings;

  /// No description provided for @talkerTypeWarningsCount.
  ///
  /// In en, this message translates to:
  /// **'Warning logs count: {text}'**
  String talkerTypeWarningsCount(Object text);

  /// No description provided for @testerLogDesc.
  ///
  /// In en, this message translates to:
  /// **'It will be useful for testers to know about these logs'**
  String get testerLogDesc;

  /// No description provided for @totalFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Total files count: {number}'**
  String totalFilesCount(Object number);

  /// No description provided for @turnOffInspector.
  ///
  /// In en, this message translates to:
  /// **'Turn off inspector'**
  String get turnOffInspector;

  /// No description provided for @turnOnInspector.
  ///
  /// In en, this message translates to:
  /// **'Turn on inspector'**
  String get turnOnInspector;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeMessage;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload images'**
  String get uploadImages;

  /// No description provided for @useConsoleLogs.
  ///
  /// In en, this message translates to:
  /// **'Use console logs'**
  String get useConsoleLogs;

  /// No description provided for @useHistory.
  ///
  /// In en, this message translates to:
  /// **'Use history'**
  String get useHistory;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User email'**
  String get userEmail;

  /// No description provided for @verboseLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Verbose message log'**
  String get verboseLogDesc;

  /// No description provided for @viewAndManageData.
  ///
  /// In en, this message translates to:
  /// **'Viewing and managing application data'**
  String get viewAndManageData;

  /// No description provided for @warningLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Warning log'**
  String get warningLogDesc;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @youAlreadyInLogger.
  ///
  /// In en, this message translates to:
  /// **'You are already in the logger page'**
  String get youAlreadyInLogger;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;
}

class _ISpectGeneratedLocalizationDelegate
    extends LocalizationsDelegate<ISpectGeneratedLocalization> {
  const _ISpectGeneratedLocalizationDelegate();

  @override
  Future<ISpectGeneratedLocalization> load(Locale locale) {
    return SynchronousFuture<ISpectGeneratedLocalization>(
        lookupISpectGeneratedLocalization(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_ISpectGeneratedLocalizationDelegate old) => false;
}

ISpectGeneratedLocalization lookupISpectGeneratedLocalization(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ISpectGeneratedLocalizationEn();
    case 'kk':
      return ISpectGeneratedLocalizationKk();
    case 'ru':
      return ISpectGeneratedLocalizationRu();
  }

  throw FlutterError(
      'ISpectGeneratedLocalization.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
