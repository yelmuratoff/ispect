// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class ISpectJiraLocalizationKk extends ISpectJiraLocalization {
  ISpectJiraLocalizationKk([String locale = 'kk']) : super(locale);

  @override
  String get successfullyAuthorized => 'Сіз сәтті авторизациядан өттіңіз';

  @override
  String get pleaseCheckAuthCred =>
      'Қате орын алды. Авторизация деректерін қайта тексеріңіз.';

  @override
  String get pickedImages => 'Таңдалған суреттер';

  @override
  String get pleaseAuthToJira => 'Jira-ға авторизация жасаңыз';

  @override
  String get pleaseSelectYourProject => 'Енді жобаңызды таңдаңыз';

  @override
  String get addingAttachmentsToIssue => 'Мәселеге файлдар қосу';

  @override
  String get addingStatusToIssue => 'Мәселеге статус қосу';

  @override
  String get apiToken => 'API токен';

  @override
  String get attachmentsAdded => 'Файлдарды қосу аяқталды';

  @override
  String get authorize => 'Авторизация';

  @override
  String get backToHome => 'Басты бетке оралу';

  @override
  String get changeProject => 'Жобаны өзгерту';

  @override
  String get createIssue => 'Мәселе құру';

  @override
  String get createJiraIssue => 'Jira мәселесін құру';

  @override
  String get creatingIssue => 'Мәселені құру';

  @override
  String get finished => 'Аяқталды';

  @override
  String get fix => 'Хабарлау';

  @override
  String get retry => 'Қайталау';

  @override
  String get selectAssignee => 'Орындаушыны таңдау';

  @override
  String get selectBoard => 'Тақтаны таңдау';

  @override
  String get selectIssueType => 'Мәселе түрін таңдау';

  @override
  String get selectLabel => 'Белгіні таңдау';

  @override
  String get selectPriority => 'Мәселенің басымдылығын таңдау';

  @override
  String get selectSprint => 'Спринтті таңдау';

  @override
  String get selectStatus => 'Статусты таңдау';

  @override
  String get sendIssue => 'Мәселені жіберу';

  @override
  String get settings => 'Параметрлер';

  @override
  String get share => 'Бөлісу';

  @override
  String get submitButtonText => 'Жіберу';

  @override
  String get summary => 'Қысқаша мазмұны';

  @override
  String totalFilesCount(Object number) {
    return 'Файлдардың жалпы саны: $number';
  }

  @override
  String get uploadImages => 'Суреттерді жүктеу';

  @override
  String get noData => 'Деректер жоқ';

  @override
  String get fieldIsRequired => 'Бұл жолды толтыру міндетті';

  @override
  String get jiraInstruction =>
      '1. Jira сайтына кіріңіз.\n2. Сол жақ төменгі бұрыштағы профиль аватарыңызға басыңыз.\n3. Профильге басыңыз.\n4. Есептік жазбаны басқаруға басыңыз.\n5. Қауіпсіздікті таңдаңыз.\n6. API токендерін жасау және басқару бөліміне төмен қарай сырғытып, оны таңдаңыз.\n7. Токен жасап, оны көшіріп, енгізіңіз.';

  @override
  String get projectDomain => 'Жоба домені';

  @override
  String get userEmail => 'Электрондық пошта';

  @override
  String get projectWasSelected => 'Жоба таңдалды';

  @override
  String get issueCreated => 'Мәселе құрылды';

  @override
  String get copiedToClipboard => 'Буферге көшірілді';

  @override
  String get description => 'Сипаттама';
}
