import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'ispect_localizations_ar.dart';
import 'ispect_localizations_de.dart';
import 'ispect_localizations_en.dart';
import 'ispect_localizations_es.dart';
import 'ispect_localizations_fr.dart';
import 'ispect_localizations_hi.dart';
import 'ispect_localizations_ja.dart';
import 'ispect_localizations_kk.dart';
import 'ispect_localizations_ko.dart';
import 'ispect_localizations_pt.dart';
import 'ispect_localizations_ru.dart';
import 'ispect_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ISpectJiraLocalization
/// returned by `ISpectJiraLocalization.of(context)`.
///
/// Applications need to include `ISpectJiraLocalization.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/ispect_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ISpectJiraLocalization.localizationsDelegates,
///   supportedLocales: ISpectJiraLocalization.supportedLocales,
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
/// be consistent with the languages listed in the ISpectJiraLocalization.supportedLocales
/// property.
abstract class ISpectJiraLocalization {
  ISpectJiraLocalization(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ISpectJiraLocalization? of(BuildContext context) {
    return Localizations.of<ISpectJiraLocalization>(
        context, ISpectJiraLocalization);
  }

  static const LocalizationsDelegate<ISpectJiraLocalization> delegate =
      _ISpectJiraLocalizationDelegate();

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('kk'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @successfullyAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You have successfully authorized'**
  String get successfullyAuthorized;

  /// No description provided for @pleaseCheckAuthCred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please double-check your authorization credentials.'**
  String get pleaseCheckAuthCred;

  /// No description provided for @pickedImages.
  ///
  /// In en, this message translates to:
  /// **'Selected images'**
  String get pickedImages;

  /// No description provided for @pleaseAuthToJira.
  ///
  /// In en, this message translates to:
  /// **'Please authorize in Jira'**
  String get pleaseAuthToJira;

  /// No description provided for @pleaseSelectYourProject.
  ///
  /// In en, this message translates to:
  /// **'Now, please select your project'**
  String get pleaseSelectYourProject;

  /// No description provided for @addingAttachmentsToIssue.
  ///
  /// In en, this message translates to:
  /// **'Adding attachments to the issue'**
  String get addingAttachmentsToIssue;

  /// No description provided for @addingStatusToIssue.
  ///
  /// In en, this message translates to:
  /// **'Adding status to the issue'**
  String get addingStatusToIssue;

  /// No description provided for @apiToken.
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get apiToken;

  /// No description provided for @attachmentsAdded.
  ///
  /// In en, this message translates to:
  /// **'Attachments added successfully'**
  String get attachmentsAdded;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @changeProject.
  ///
  /// In en, this message translates to:
  /// **'Change project'**
  String get changeProject;

  /// No description provided for @createIssue.
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get createIssue;

  /// No description provided for @createJiraIssue.
  ///
  /// In en, this message translates to:
  /// **'Create Jira issue'**
  String get createJiraIssue;

  /// No description provided for @creatingIssue.
  ///
  /// In en, this message translates to:
  /// **'Creating issue'**
  String get creatingIssue;

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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// No description provided for @submitButtonText.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButtonText;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @totalFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Total files count: {number}'**
  String totalFilesCount(Object number);

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload images'**
  String get uploadImages;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldIsRequired;

  /// No description provided for @jiraInstruction.
  ///
  /// In en, this message translates to:
  /// **'1. Go to your Jira site.\n2. Click your profile avatar in the bottom-left corner.\n3. Click on Profile.\n4. Click Manage your account.\n5. Select Security.\n6. Scroll down to API token management and click on it.\n7. Generate a token, then copy and paste it.'**
  String get jiraInstruction;

  /// No description provided for @projectDomain.
  ///
  /// In en, this message translates to:
  /// **'Project domain'**
  String get projectDomain;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get userEmail;

  /// No description provided for @projectWasSelected.
  ///
  /// In en, this message translates to:
  /// **'Project selected'**
  String get projectWasSelected;

  /// No description provided for @issueCreated.
  ///
  /// In en, this message translates to:
  /// **'Issue created'**
  String get issueCreated;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;
}

class _ISpectJiraLocalizationDelegate
    extends LocalizationsDelegate<ISpectJiraLocalization> {
  const _ISpectJiraLocalizationDelegate();

  @override
  Future<ISpectJiraLocalization> load(Locale locale) {
    return SynchronousFuture<ISpectJiraLocalization>(
        lookupISpectJiraLocalization(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'ja',
        'kk',
        'ko',
        'pt',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_ISpectJiraLocalizationDelegate old) => false;
}

ISpectJiraLocalization lookupISpectJiraLocalization(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return ISpectJiraLocalizationAr();
    case 'de':
      return ISpectJiraLocalizationDe();
    case 'en':
      return ISpectJiraLocalizationEn();
    case 'es':
      return ISpectJiraLocalizationEs();
    case 'fr':
      return ISpectJiraLocalizationFr();
    case 'hi':
      return ISpectJiraLocalizationHi();
    case 'ja':
      return ISpectJiraLocalizationJa();
    case 'kk':
      return ISpectJiraLocalizationKk();
    case 'ko':
      return ISpectJiraLocalizationKo();
    case 'pt':
      return ISpectJiraLocalizationPt();
    case 'ru':
      return ISpectJiraLocalizationRu();
    case 'zh':
      return ISpectJiraLocalizationZh();
  }

  throw FlutterError(
      'ISpectJiraLocalization.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
