import 'ispect_localizations.dart';

/// The translations for Russian (`ru`).
class ISpectGeneratedLocalizationRu extends ISpectGeneratedLocalization {
  ISpectGeneratedLocalizationRu([String locale = 'ru']) : super(locale);

  @override
  String get change_theme => 'Сменить тему';

  @override
  String get talker_type_debug => 'Подробные и отладочные';

  @override
  String talker_type_debug_count(Object text) {
    return 'Количество подробных и отладочных записей: $text';
  }

  @override
  String get talker_type_good => 'Хорошие';

  @override
  String talker_type_good_count(Object text) {
    return 'Количество хороших записей: $text';
  }

  @override
  String get talker_type_provider => 'Провайдеры';

  @override
  String talker_type_provider_count(Object text) {
    return 'Количество записей провайдеров: $text';
  }

  @override
  String get talker_type_info => 'Информация';

  @override
  String talker_type_info_count(Object text) {
    return 'Количество информационных записей: $text';
  }

  @override
  String get talker_type_warnings => 'Предупреждения';

  @override
  String talker_type_warnings_count(Object text) {
    return 'Количество предупреждений: $text';
  }

  @override
  String get talker_type_exceptions => 'Исключения';

  @override
  String talker_type_exceptions_count(Object text) {
    return 'Количество записей исключений: $text';
  }

  @override
  String get talker_type_errors => 'Ошибки';

  @override
  String talker_type_errors_count(Object text) {
    return 'Количество записей об ошибках: $text';
  }

  @override
  String get talker_type_http => 'HTTP запросы';

  @override
  String talker_http_requests_count(Object text) {
    return 'Количество записей HTTP запросов: $text';
  }

  @override
  String talker_http_responses_count(Object text) {
    return 'Количество записей HTTP ответов: $text';
  }

  @override
  String talker_http_failues_count(Object text) {
    return 'Количество записей неудачных HTTP запросов: $text';
  }

  @override
  String get talker_type_bloc => 'BLoC';

  @override
  String talker_bloc_transition_count(Object text) {
    return 'Количество переходов BLoC: $text';
  }

  @override
  String talker_bloc_events_count(Object text) {
    return 'Количество событий BLoC: $text';
  }

  @override
  String talker_bloc_close_count(Object text) {
    return 'Количество закрытий BLoC: $text';
  }

  @override
  String talker_bloc_create_count(Object text) {
    return 'Количество созданий BLoC: $text';
  }

  @override
  String get actions => 'Действия';

  @override
  String get reverse_logs => 'Инвертировать журнал';

  @override
  String get copy_all_logs => 'Копировать все записи';

  @override
  String get collapse_logs => 'Свернуть журнал';

  @override
  String get expand_logs => 'Развернуть журнал';

  @override
  String get clean_history => 'Очистить историю';

  @override
  String get share_logs_file => 'Поделиться файлом журнала';

  @override
  String get log_item_copied => 'Запись скопирована в буфер обмена';

  @override
  String get basic_settings => 'Основные настройки';

  @override
  String get enabled => 'Включено';

  @override
  String get use_console_logs => 'Использовать запись в консоль';

  @override
  String get use_history => 'Использовать историю';

  @override
  String get settings => 'Настройки';

  @override
  String get search => 'Поиск';

  @override
  String get all_logs_copied => 'Все записи скопированы в буфер обмена';

  @override
  String get page_not_found => 'Ой, страница по этому пути';

  @override
  String get not_found => 'не найдена';

  @override
  String get back_to_home => 'Вернуться на главную страницу';

  @override
  String get fix => 'Сообщить';

  @override
  String get clear_cache => 'Очистить кэш';

  @override
  String get cache_cleared => 'Кэш очищен';

  @override
  String get error_cache_clearing => 'Ошибка при очистке кэша';

  @override
  String get app_version => 'Версия приложения';

  @override
  String get build_version => 'Версия сборки';

  @override
  String get change_environment => 'Сменить текущее окружение';

  @override
  String get go_to_logger => 'Перейти к журналу';

  @override
  String environment_tap_number(Object number) {
    return 'Для открытия диалога осталось: $number';
  }

  @override
  String counter_times_text(Object number) {
    return 'Вы нажали кнопку столько раз: $number';
  }

  @override
  String get performance_tracker => 'Отслеживание производительности';

  @override
  String get login => 'Вход';

  @override
  String get initialization_failed => 'Ошибка инициализации';

  @override
  String get error_type => 'Тип ошибки';

  @override
  String get retry => 'Повторить';

  @override
  String get logout => 'Выйти';

  @override
  String get you_already_in_logger => 'Вы уже на странице ISpect';

  @override
  String get turn_on_inspector => 'Включить инспектор';

  @override
  String get turn_off_inspector => 'Выключить инспектор';

  @override
  String get view_and_manage_data => 'Просмотр и управление данными приложения';

  @override
  String get app_data => 'Данные приложения';

  @override
  String total_files_count(Object number) {
    return 'Общее количество файлов: $number';
  }

  @override
  String get app_info => 'Проверить информацию об устройстве и пакете';

  @override
  String get copied_to_clipboard => 'Скопировано в буфер обмена';

  @override
  String get copy => 'Скопировать';

  @override
  String cache_size(Object size) {
    return 'Размер кэша: $size';
  }
}
