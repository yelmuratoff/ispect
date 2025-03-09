// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class ISpectJiraLocalizationHi extends ISpectJiraLocalization {
  ISpectJiraLocalizationHi([String locale = 'hi']) : super(locale);

  @override
  String get successfullyAuthorized => 'आपने सफलतापूर्वक प्रमाणीकरण किया है';

  @override
  String get pleaseCheckAuthCred =>
      'एक त्रुटि हुई। कृपया अपने प्रमाणीकरण क्रेडेंशियल्स को दोबारा जांचें।';

  @override
  String get pickedImages => 'चयनित छवियाँ';

  @override
  String get pleaseAuthToJira => 'कृपया Jira में प्रमाणित करें';

  @override
  String get pleaseSelectYourProject => 'अब, कृपया अपना प्रोजेक्ट चुनें';

  @override
  String get addingAttachmentsToIssue => 'मुद्दे में संलग्नक जोड़ना';

  @override
  String get addingStatusToIssue => 'मुद्दे में स्थिति जोड़ना';

  @override
  String get apiToken => 'API टोकन';

  @override
  String get attachmentsAdded => 'संलग्नक सफलतापूर्वक जोड़े गए';

  @override
  String get authorize => 'प्रमाणित करें';

  @override
  String get backToHome => 'होम पर वापस';

  @override
  String get changeProject => 'प्रोजेक्ट बदलें';

  @override
  String get createIssue => 'मुद्दा बनाएँ';

  @override
  String get createJiraIssue => 'Jira मुद्दा बनाएँ';

  @override
  String get creatingIssue => 'मुद्दा बनाया जा रहा है';

  @override
  String get finished => 'समाप्त';

  @override
  String get fix => 'रिपोर्ट करें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get selectAssignee => 'असाइनी चुनें';

  @override
  String get selectBoard => 'बोर्ड चुनें';

  @override
  String get selectIssueType => 'मुद्दे का प्रकार चुनें';

  @override
  String get selectLabel => 'लेबल चुनें';

  @override
  String get selectPriority => 'प्राथमिकता चुनें';

  @override
  String get selectSprint => 'स्प्रिंट चुनें';

  @override
  String get selectStatus => 'स्थिति चुनें';

  @override
  String get sendIssue => 'मुद्दा भेजें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get share => 'साझा करें';

  @override
  String get submitButtonText => 'जमा करें';

  @override
  String get summary => 'सारांश';

  @override
  String totalFilesCount(Object number) {
    return 'कुल फाइलों की संख्या: $number';
  }

  @override
  String get uploadImages => 'छवियाँ अपलोड करें';

  @override
  String get noData => 'कोई डेटा नहीं';

  @override
  String get fieldIsRequired => 'यह फ़ील्ड आवश्यक है';

  @override
  String get jiraInstruction =>
      '1. अपनी Jira साइट पर जाएँ।\n2. निचले बाएँ कोने में अपने प्रोफाइल अवतार पर क्लिक करें।\n3. प्रोफाइल पर क्लिक करें।\n4. अपने खाते का प्रबंधन करें पर क्लिक करें।\n5. सुरक्षा चुनें।\n6. API टोकन प्रबंधन तक स्क्रॉल करें और उस पर क्लिक करें।\n7. एक टोकन उत्पन्न करें, फिर उसे कॉपी और पेस्ट करें।';

  @override
  String get projectDomain => 'प्रोजेक्ट डोमेन';

  @override
  String get userEmail => 'ईमेल';

  @override
  String get projectWasSelected => 'प्रोजेक्ट चुना गया';

  @override
  String get issueCreated => 'मुद्दा बनाया गया';

  @override
  String get copiedToClipboard => 'क्लिपबोर्ड में कॉपी किया गया';

  @override
  String get description => 'विवरण';
}
