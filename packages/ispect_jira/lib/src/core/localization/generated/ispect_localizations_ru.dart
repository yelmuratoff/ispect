import 'ispect_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class ISpectJiraLocalizationRu extends ISpectJiraLocalization {
  ISpectJiraLocalizationRu([String locale = 'ru']) : super(locale);

  @override
  String get successfullyAuthorized => 'Вы успешно авторизовались';

  @override
  String get pleaseCheckAuthCred =>
      'Произошла ошибка. Пожалуйста, перепроверьте данные авторизации.';

  @override
  String get pickedImages => 'Выбранные изображения';

  @override
  String get pleaseAuthToJira => 'Пожалуйста, авторизуйтесь в Jira';

  @override
  String get pleaseSelectYourProject => 'Теперь, пожалуйста выберите проект';

  @override
  String get addingAttachmentsToIssue => 'Добавление вложений к задаче';

  @override
  String get addingStatusToIssue => 'Добавление статуса к задаче';

  @override
  String get apiToken => 'API токен';

  @override
  String get attachmentsAdded => 'Добавление вложений завершено';

  @override
  String get authorize => 'Авторизация';

  @override
  String get backToHome => 'Вернуться на главную страницу';

  @override
  String get changeProject => 'Изменить проект';

  @override
  String get createIssue => 'Создать задачу';

  @override
  String get createJiraIssue => 'Создать Jira Issue';

  @override
  String get creatingIssue => 'Создание задачи';

  @override
  String get finished => 'Закончено';

  @override
  String get fix => 'Сообщить';

  @override
  String get retry => 'Повторить';

  @override
  String get selectAssignee => 'Выбрать исполнителя';

  @override
  String get selectBoard => 'Выбрать доску';

  @override
  String get selectIssueType => 'Выбрать тип задачи';

  @override
  String get selectLabel => 'Выбрать метку';

  @override
  String get selectPriority => 'Выберите приоритетность задачи';

  @override
  String get selectSprint => 'Выбрать спринт';

  @override
  String get selectStatus => 'Выбрать статус';

  @override
  String get sendIssue => 'Отправить задачу';

  @override
  String get settings => 'Настройки';

  @override
  String get share => 'Поделиться';

  @override
  String get submitButtonText => 'Отправить';

  @override
  String get summary => 'Сводка';

  @override
  String totalFilesCount(Object number) {
    return 'Общее количество файлов: $number';
  }

  @override
  String get uploadImages => 'Загрузить изображения';

  @override
  String get noData => 'Нет данных';

  @override
  String get fieldIsRequired => 'Поле обязательно для заполнения';

  @override
  String get jiraInstruction =>
      '1. Зайдите на свой сайт Jira.\n2. Нажмите на аватар вашего профиля в левом нижнем углу.\n3. Нажмите на Профиль.\n4. Нажмите Управление учетной записью.\n5. Выберите Безопасность.\n6. Прокрутите вниз до раздела Создание и управление API-токенами и нажмите на него.\n7. Создайте токен, затем скопируйте и вставьте его.';

  @override
  String get projectDomain => 'Домен проекта';

  @override
  String get userEmail => 'Электронная почта';

  @override
  String get projectWasSelected => 'Проект выбран';

  @override
  String get issueCreated => 'Задача создана';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get description => 'Описание';
}
