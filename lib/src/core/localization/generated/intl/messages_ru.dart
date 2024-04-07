// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru';

  static String m0(number) => "Вы нажали кнопку столько раз: ${number}";

  static String m1(number) => "Для открытия диалога осталось: ${number}";

  static String m2(text) => "Количество закрытий BLoC: ${text}";

  static String m3(text) => "Количество созданий BLoC: ${text}";

  static String m4(text) => "Количество событий BLoC: ${text}";

  static String m5(text) => "Количество переходов BLoC: ${text}";

  static String m6(text) =>
      "Количество записей неудачных HTTP запросов: ${text}";

  static String m7(text) => "Количество записей HTTP запросов: ${text}";

  static String m8(text) => "Количество записей HTTP ответов: ${text}";

  static String m9(text) =>
      "Количество подробных и отладочных записей: ${text}";

  static String m10(text) => "Количество записей об ошибках: ${text}";

  static String m11(text) => "Количество записей исключений: ${text}";

  static String m12(text) => "Количество хороших записей: ${text}";

  static String m13(text) => "Количество информационных записей: ${text}";

  static String m14(text) => "Количество записей провайдеров: ${text}";

  static String m15(text) => "Количество предупреждений: ${text}";

  static String m16(number) => "Общее количество файлов: ${number}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "actions": MessageLookupByLibrary.simpleMessage("Действия"),
        "all_logs_copied": MessageLookupByLibrary.simpleMessage(
            "Все записи скопированы в буфер обмена"),
        "app_data": MessageLookupByLibrary.simpleMessage("Данные приложения"),
        "app_info": MessageLookupByLibrary.simpleMessage(
            "Проверить информацию об устройстве и пакете"),
        "app_version":
            MessageLookupByLibrary.simpleMessage("Версия приложения"),
        "back_to_home": MessageLookupByLibrary.simpleMessage(
            "Вернуться на главную страницу"),
        "basic_settings":
            MessageLookupByLibrary.simpleMessage("Основные настройки"),
        "build_version": MessageLookupByLibrary.simpleMessage("Версия сборки"),
        "cache_cleared": MessageLookupByLibrary.simpleMessage("Кэш очищен"),
        "change_environment":
            MessageLookupByLibrary.simpleMessage("Сменить текущее окружение"),
        "change_theme": MessageLookupByLibrary.simpleMessage("Сменить тему"),
        "clean_history":
            MessageLookupByLibrary.simpleMessage("Очистить историю"),
        "clear_cache": MessageLookupByLibrary.simpleMessage("Очистить кэш"),
        "collapse_logs":
            MessageLookupByLibrary.simpleMessage("Свернуть журнал"),
        "copied_to_clipboard":
            MessageLookupByLibrary.simpleMessage("Скопировано в буфер обмена"),
        "copy": MessageLookupByLibrary.simpleMessage("Скопировать"),
        "copy_all_logs":
            MessageLookupByLibrary.simpleMessage("Копировать все записи"),
        "counter_times_text": m0,
        "enabled": MessageLookupByLibrary.simpleMessage("Включено"),
        "environment_tap_number": m1,
        "error_cache_clearing":
            MessageLookupByLibrary.simpleMessage("Ошибка при очистке кэша"),
        "error_type": MessageLookupByLibrary.simpleMessage("Тип ошибки"),
        "expand_logs":
            MessageLookupByLibrary.simpleMessage("Развернуть журнал"),
        "fix": MessageLookupByLibrary.simpleMessage("Сообщить"),
        "go_to_logger":
            MessageLookupByLibrary.simpleMessage("Перейти к журналу"),
        "initialization_failed":
            MessageLookupByLibrary.simpleMessage("Ошибка инициализации"),
        "log_item_copied": MessageLookupByLibrary.simpleMessage(
            "Запись скопирована в буфер обмена"),
        "login": MessageLookupByLibrary.simpleMessage("Вход"),
        "logout": MessageLookupByLibrary.simpleMessage("Выйти"),
        "not_found": MessageLookupByLibrary.simpleMessage("не найдена"),
        "page_not_found":
            MessageLookupByLibrary.simpleMessage("Ой, страница по этому пути"),
        "performance_tracker": MessageLookupByLibrary.simpleMessage(
            "Отслеживание производительности"),
        "retry": MessageLookupByLibrary.simpleMessage("Повторить"),
        "reverse_logs":
            MessageLookupByLibrary.simpleMessage("Инвертировать журнал"),
        "search": MessageLookupByLibrary.simpleMessage("Поиск"),
        "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
        "share_logs_file":
            MessageLookupByLibrary.simpleMessage("Поделиться файлом журнала"),
        "talker_bloc_close_count": m2,
        "talker_bloc_create_count": m3,
        "talker_bloc_events_count": m4,
        "talker_bloc_transition_count": m5,
        "talker_http_failues_count": m6,
        "talker_http_requests_count": m7,
        "talker_http_responses_count": m8,
        "talker_type_bloc": MessageLookupByLibrary.simpleMessage("BLoC"),
        "talker_type_debug":
            MessageLookupByLibrary.simpleMessage("Подробные и отладочные"),
        "talker_type_debug_count": m9,
        "talker_type_errors": MessageLookupByLibrary.simpleMessage("Ошибки"),
        "talker_type_errors_count": m10,
        "talker_type_exceptions":
            MessageLookupByLibrary.simpleMessage("Исключения"),
        "talker_type_exceptions_count": m11,
        "talker_type_good": MessageLookupByLibrary.simpleMessage("Хорошие"),
        "talker_type_good_count": m12,
        "talker_type_http":
            MessageLookupByLibrary.simpleMessage("HTTP запросы"),
        "talker_type_info": MessageLookupByLibrary.simpleMessage("Информация"),
        "talker_type_info_count": m13,
        "talker_type_provider":
            MessageLookupByLibrary.simpleMessage("Провайдеры"),
        "talker_type_provider_count": m14,
        "talker_type_warnings":
            MessageLookupByLibrary.simpleMessage("Предупреждения"),
        "talker_type_warnings_count": m15,
        "total_files_count": m16,
        "turn_off_inspector":
            MessageLookupByLibrary.simpleMessage("Выключить инспектор"),
        "turn_on_inspector":
            MessageLookupByLibrary.simpleMessage("Включить инспектор"),
        "use_console_logs": MessageLookupByLibrary.simpleMessage(
            "Использовать запись в консоль"),
        "use_history":
            MessageLookupByLibrary.simpleMessage("Использовать историю"),
        "view_and_manage_data": MessageLookupByLibrary.simpleMessage(
            "Просмотр и управление данными приложения"),
        "you_already_in_logger":
            MessageLookupByLibrary.simpleMessage("Вы уже на странице ISpect")
      };
}
