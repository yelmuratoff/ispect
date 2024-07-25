import 'ispect_localizations.dart';

/// The translations for Russian (`ru`).
class ISpectGeneratedLocalizationRu extends ISpectGeneratedLocalization {
  ISpectGeneratedLocalizationRu([String locale = 'ru']) : super(locale);

  @override
  String get changeTheme => 'Сменить тему';

  @override
  String get talkerTypeDebug => 'Подробные и отладочные';

  @override
  String talkerTypeDebugCount(Object text) {
    return 'Количество подробных и отладочных записей: $text';
  }

  @override
  String get talkerTypeGood => 'Хорошие';

  @override
  String talkerTypeGoodCount(Object text) {
    return 'Количество хороших записей: $text';
  }

  @override
  String get talkerTypePrint => 'Print метод';

  @override
  String talkerTypePrintCount(Object text) {
    return 'Количество print записей: $text';
  }

  @override
  String get talkerTypeProvider => 'Провайдеры';

  @override
  String talkerTypeProviderCount(Object text) {
    return 'Количество записей провайдеров: $text';
  }

  @override
  String get talkerTypeInfo => 'Информация';

  @override
  String talkerTypeInfoCount(Object text) {
    return 'Количество информационных записей: $text';
  }

  @override
  String get talkerTypeWarnings => 'Предупреждения';

  @override
  String talkerTypeWarningsCount(Object text) {
    return 'Количество предупреждений: $text';
  }

  @override
  String get talkerTypeExceptions => 'Исключения';

  @override
  String talkerTypeExceptionsCount(Object text) {
    return 'Количество записей исключений: $text';
  }

  @override
  String get talkerTypeErrors => 'Ошибки';

  @override
  String talkerTypeErrorsCount(Object text) {
    return 'Количество записей об ошибках: $text';
  }

  @override
  String get talkerTypeHttp => 'HTTP запросы';

  @override
  String talkerHttpRequestsCount(Object text) {
    return 'Количество записей HTTP запросов: $text';
  }

  @override
  String talkerHttpResponsesCount(Object text) {
    return 'Количество записей HTTP ответов: $text';
  }

  @override
  String talkerHttpFailuresCount(Object text) {
    return 'Количество записей неудачных HTTP запросов: $text';
  }

  @override
  String get talkerTypeBloc => 'BLoC';

  @override
  String talkerBlocTransitionCount(Object text) {
    return 'Количество переходов BLoC: $text';
  }

  @override
  String talkerBlocEventsCount(Object text) {
    return 'Количество событий BLoC: $text';
  }

  @override
  String talkerBlocClosesCount(Object text) {
    return 'BLoC closes count: $text';
  }

  @override
  String talkerBlocCreatesCount(Object text) {
    return 'BLoC creates count: $text';
  }

  @override
  String get talkerTypeRiverpod => 'Riverpod';

  @override
  String talkerRiverpodAddCount(Object text) {
    return 'Количество добавлений Riverpod: $text';
  }

  @override
  String talkerRiverpodUpdateCount(Object text) {
    return 'Количество обновлений Riverpod: $text';
  }

  @override
  String talkerRiverpodDisposeCount(Object text) {
    return 'Количество закрытий Riverpod: $text';
  }

  @override
  String talkerRiverpodFailsCount(Object text) {
    return 'Количество ошибок Riverpod: $text';
  }

  @override
  String get actions => 'Действия';

  @override
  String get reverseLogs => 'Инвертировать журнал';

  @override
  String get copyAllLogs => 'Копировать все записи';

  @override
  String get collapseLogs => 'Свернуть журнал';

  @override
  String get expandLogs => 'Развернуть журнал';

  @override
  String get cleanHistory => 'Очистить историю';

  @override
  String get shareLogsFile => 'Поделиться файлом журнала';

  @override
  String get logItemCopied => 'Запись скопирована в буфер обмена';

  @override
  String get basicSettings => 'Основные настройки';

  @override
  String get enabled => 'Включено';

  @override
  String get useConsoleLogs => 'Использовать запись в консоль';

  @override
  String get useHistory => 'Использовать историю';

  @override
  String get settings => 'Настройки';

  @override
  String get search => 'Поиск';

  @override
  String get allLogsCopied => 'Все записи скопированы в буфер обмена';

  @override
  String get pageNotFound => 'Ой, страница по этому пути';

  @override
  String get notFound => 'не найдена';

  @override
  String get backToHome => 'Вернуться на главную страницу';

  @override
  String get fix => 'Сообщить';

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get cacheCleared => 'Кэш очищен';

  @override
  String get errorCacheClearing => 'Ошибка при очистке кэша';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get buildVersion => 'Версия сборки';

  @override
  String get changeEnvironment => 'Сменить текущее окружение';

  @override
  String get goToLogger => 'Перейти к журналу';

  @override
  String environmentTapNumber(Object number) {
    return 'Для открытия диалога осталось: $number';
  }

  @override
  String counterTimesText(Object number) {
    return 'Вы нажали кнопку столько раз: $number';
  }

  @override
  String get performanceTracker => 'Отслеживание производительности';

  @override
  String get login => 'Вход';

  @override
  String get initializationFailed => 'Ошибка инициализации';

  @override
  String get errorType => 'Тип ошибки';

  @override
  String get retry => 'Повторить';

  @override
  String get logout => 'Выйти';

  @override
  String get youAlreadyInLogger => 'Вы уже на странице ISpect';

  @override
  String get turnOnInspector => 'Включить инспектор';

  @override
  String get turnOffInspector => 'Выключить инспектор';

  @override
  String get viewAndManageData => 'Просмотр и управление данными приложения';

  @override
  String get appData => 'Данные приложения';

  @override
  String totalFilesCount(Object number) {
    return 'Общее количество файлов: $number';
  }

  @override
  String get appInfo => 'Проверить информацию об устройстве и пакете';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get copy => 'Скопировать';

  @override
  String cacheSize(Object size) {
    return 'Размер кэша: $size';
  }

  @override
  String get method => 'Метод';

  @override
  String get path => 'Путь';

  @override
  String get fullURL => 'Полная ссылка';

  @override
  String get statusCode => 'Код статуса';

  @override
  String get statusMessage => 'Cтатус';

  @override
  String get requestHeaders => 'Headers запроса';

  @override
  String get data => 'Данные';

  @override
  String get headers => 'Headers';

  @override
  String get errorMessage => 'Текст ошибки';

  @override
  String get talkerLogsInfo => 'Информация про логи';

  @override
  String get common => 'Общие';

  @override
  String get errorLogDesc => 'Лог ошибки';

  @override
  String get criticalLogDesc => 'Лог критической ошибки';

  @override
  String get infoLogDesc => 'Лог информативного сообщения';

  @override
  String get debugLogDesc => 'Лог отладочного сообщения';

  @override
  String get verboseLogDesc => 'Лог подробного сообщения';

  @override
  String get warningLogDesc => 'Лог предупреждения';

  @override
  String get exceptionLogDesc => 'Лог исключения';

  @override
  String get goodLogDesc => 'Лог успешного действия';

  @override
  String get routeLogDesc => 'Лог навигации между экранами';

  @override
  String get httpRequestLogDesc => 'Лог отправленного запроса на сервер';

  @override
  String get httpResponseLogDesc => 'Лог ответа сервера на отправленный запрос';

  @override
  String get httpErrorLogDesc => 'Лог ошибки при отправке запроса на сервер';

  @override
  String get blocEventLogDesc => 'Лог события в блоке';

  @override
  String get blocTransitionLogDesc => 'Лог перехода состояния в блоке';

  @override
  String get blocCloseLogDesc => 'Лог закрытия блока';

  @override
  String get blocCreateLogDesc => 'Лог создания блока';

  @override
  String get riverpodAddLogDesc => 'Лог добавления провайдера';

  @override
  String get riverpodUpdateLogDesc => 'Лог обновления провайдера';

  @override
  String get riverpodDisposeLogDesc => 'Лог удаления провайдера';

  @override
  String get riverpodFailLogDesc => 'Лог ошибки при работе с провайдером';

  @override
  String get testerLogDesc =>
      'Для тестировщиков будет полезно знать про эти логи';

  @override
  String get otherLogsForDevelopers =>
      'Другие логи уже используют разработчики';

  @override
  String get printLogDesc => 'Лог стандартного print метода у Flutter';
}
