import 'package:ispect/src/core/localization/generated/ispect_localizations.dart';

/// The translations for Russian (`ru`).
class ISpectGeneratedLocalizationRu extends ISpectGeneratedLocalization {
  ISpectGeneratedLocalizationRu([super.locale = 'ru']);

  @override
  String get changeTheme => 'Сменить тему';

  @override
  String get talkerTypeDebug => 'Подробные и отладочные';

  @override
  String talkerTypeDebugCount(Object text) =>
      'Количество подробных и отладочных записей: $text';

  @override
  String get talkerTypeGood => 'Хорошие';

  @override
  String talkerTypeGoodCount(Object text) =>
      'Количество хороших записей: $text';

  @override
  String get talkerTypeProvider => 'Провайдеры';

  @override
  String talkerTypeProviderCount(Object text) =>
      'Количество записей провайдеров: $text';

  @override
  String get talkerTypeInfo => 'Информация';

  @override
  String talkerTypeInfoCount(Object text) =>
      'Количество информационных записей: $text';

  @override
  String get talkerTypeWarnings => 'Предупреждения';

  @override
  String talkerTypeWarningsCount(Object text) =>
      'Количество предупреждений: $text';

  @override
  String get talkerTypeExceptions => 'Исключения';

  @override
  String talkerTypeExceptionsCount(Object text) =>
      'Количество записей исключений: $text';

  @override
  String get talkerTypeErrors => 'Ошибки';

  @override
  String talkerTypeErrorsCount(Object text) =>
      'Количество записей об ошибках: $text';

  @override
  String get talkerTypeHttp => 'HTTP запросы';

  @override
  String talkerHttpRequestsCount(Object text) =>
      'Количество записей HTTP запросов: $text';

  @override
  String talkerHttpResponsesCount(Object text) =>
      'Количество записей HTTP ответов: $text';

  @override
  String talkerHttpFailuresCount(Object text) =>
      'Количество записей неудачных HTTP запросов: $text';

  @override
  String get talkerTypeBloc => 'BLoC';

  @override
  String talkerBlocTransitionCount(Object text) =>
      'Количество переходов BLoC: $text';

  @override
  String talkerBlocEventsCount(Object text) => 'Количество событий BLoC: $text';

  @override
  String talkerBlocClosesCount(Object text) => 'BLoC closes count: $text';

  @override
  String talkerBlocCreatesCount(Object text) => 'BLoC creates count: $text';

  @override
  String get talkerTypeRiverpod => 'Riverpod';

  @override
  String talkerRiverpodAddCount(Object text) =>
      'Количество добавлений Riverpod: $text';

  @override
  String talkerRiverpodUpdateCount(Object text) =>
      'Количество обновлений Riverpod: $text';

  @override
  String talkerRiverpodDisposeCount(Object text) =>
      'Количество закрытий Riverpod: $text';

  @override
  String talkerRiverpodFailsCount(Object text) =>
      'Количество ошибок Riverpod: $text';

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
  String environmentTapNumber(Object number) =>
      'Для открытия диалога осталось: $number';

  @override
  String counterTimesText(Object number) =>
      'Вы нажали кнопку столько раз: $number';

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
  String totalFilesCount(Object number) => 'Общее количество файлов: $number';

  @override
  String get appInfo => 'Проверить информацию об устройстве и пакете';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get copy => 'Скопировать';

  @override
  String cacheSize(Object size) => 'Размер кэша: $size';
}
