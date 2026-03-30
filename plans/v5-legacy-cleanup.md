# v5.0 Legacy Cleanup — Clean Break

## Контекст

v5.0 = breaking change, нет backward compat. Убираем все legacy паттерны полностью.
Подробности архитектуры: `plans/universal-trace-architecture.md`.

## Что убрать

### 1. Typed log subclasses (ispectify)

**Удалить файл** `packages/ispectify/lib/src/models/logs.dart`:
- `GoodLog`, `AnalyticsLog`, `RouteLog`, `ProviderLog`, `PrintLog`

**Удалить из barrel** `packages/ispectify/lib/ispectify.dart`:
- `export 'src/models/logs.dart';`

**Обновить вызывающий код** в `packages/ispectify/lib/src/ispectify.dart`:
- `good()` — заменить `GoodLog(...)` на `ISpectLogFactory.create(ISpectLogType.good, ...)`
- `analytics()` — заменить `AnalyticsLog(...)` на `ISpectLogFactory.create(ISpectLogType.analytics, ...)`
- `print()` — заменить `PrintLog(...)` на `ISpectLogFactory.create(ISpectLogType.print, ...)`
- `route()` — заменить `RouteLog(...)` на `ISpectLogFactory.create(ISpectLogType.route, ...)` с `additionalData: {TraceKeys.correlationId: transitionId, TraceKeys.category: TraceCategoryIds.navigation}`
- `provider()` — заменить `ProviderLog(...)` на `ISpectLogFactory.create(ISpectLogType.provider, ...)`

**Обновить** `packages/ispectify/lib/src/utils/error_handler.dart`:
- `ISpectLogError`, `ISpectLogException` — проверить, используют ли `title`. Если да — убрать `title`, оставить только `key`.

### 2. Поле `title` на ISpectLogData

**Удалить** `title` field из `packages/ispectify/lib/src/models/data.dart`:
- Убрать из конструктора, из field, из ==, из hashCode, из toString
- Обновить `header` getter: `'[$key] | $formattedTime\n'`

**Обновить всех пользователей** `title`:
- `data_extensions.dart` — copyWith, generateText — убрать `title`
- `filter/search_filter.dart` — убрать `item.title` из поиска (всё через `key`)
- `filter/filter.dart` — `TitleFilter` убрать или переименовать (см. п.4)
- `history/serialization.dart` — убрать `title` из toJson/fromJson
- `models/log_factory.dart` — убрать `title: options?.titleByKey(...)`, не нужен

### 3. `titleByKey()` на Options

**Удалить** метод `titleByKey()` из `packages/ispectify/lib/src/options.dart`.
**Удалить** поле `_customTitles` из конструктора и из `ISpectLoggerOptions`.

### 4. `TitleFilter` → объединить с `LogTypeKeyFilter`

**Удалить** `TitleFilter` из `packages/ispectify/lib/src/filter/filter.dart`.
**Обновить** `ISpectFilter` в `ispect_filter.dart`:
- Заменить `TitleFilter.fromSet(_titles)` на `LogTypeKeyFilter.fromSet(_titles)`
- Переименовать internal `_titles` → всё на `_logTypeKeys` или объединить sets

**Обновить** `FilterManager` в `packages/ispect/lib/src/common/managers/filter_manager.dart`:
- `data.key ?? data.title` → просто `data.key`
- Все title-related caches → key-based

**Обновить** `packages/ispect/lib/src/common/services/logs_json_service.dart` — если использует `TitleFilter`.

### 5. UI: `RouteLog` type checks → `isRouteLog`

Эта часть уже частично сделана в текущем коде (log_card.dart, desktop_log_row.dart обновлены на `data.isRouteLog`).

**Обновить оставшиеся файлы:**
- `packages/ispect/lib/src/features/ispect/presentation/screens/navigation_flow.dart` — уже `ISpectLogData?` вместо `RouteLog?`, использует `traceCorrelationId`
- `packages/ispect/lib/src/features/ispect/presentation/widgets/navigation_flow/navigation_transition_card.dart` — уже `ISpectLogData?`
- `packages/ispect/lib/src/features/ispect/presentation/widgets/navigation_flow/actions_sheet.dart` — уже `ISpectLogData?`

### 6. UI: `logBuilder` для кастомизации карточек

**Добавить** в `ISpectOptions` (или `ISpectTheme`):

```dart
/// Custom builder for log card widget. If null, uses default card.
final Widget Function(BuildContext context, ISpectLogData log)? logBuilder;
```

Использование в `log_card.dart` и `desktop_log_row.dart`:
```dart
final customBuilder = context.iSpect.options.logBuilder;
if (customBuilder != null) return customBuilder(context, data);
// ... default card implementation
```

Юзер сможет:
```dart
ISpect(
  options: ISpectOptions(
    logBuilder: (context, log) => MyCustomLogCard(log: log),
  ),
)
```

### 7. Network typed subclasses (уже запланировано)

Проверить что `BaseNetworkLog`, `NetworkRequestLog`, `NetworkResponseLog`, `NetworkErrorLog` из `network_logs.dart` тоже удалены или не используются в type checks. Все network логи идут через `trace()` → `ISpectLogData` с `key`.

## Порядок выполнения

1. Удалить `title` field из `ISpectLogData` + обновить все references
2. Удалить `titleByKey()` + `_customTitles`
3. Удалить `TitleFilter`, объединить с `LogTypeKeyFilter`
4. Удалить typed log subclasses (logs.dart) + обновить вызовы в ispectify.dart
5. Обновить UI — убрать все `RouteLog` type checks (частично сделано)
6. Добавить `logBuilder` в options
7. Обновить тесты — убрать `title` assertions, `RouteLog`/`GoodLog` в тестах
8. `dart analyze --fatal-infos` + `flutter analyze --fatal-infos` все пакеты
9. `dart test` / `flutter test` все пакеты

## Валидация

```bash
cd packages/ispectify && dart analyze --fatal-infos && dart test
cd packages/ispectify_db && dart analyze --fatal-infos && dart test
cd packages/ispectify_dio && flutter analyze --fatal-infos && flutter test
cd packages/ispectify_http && flutter analyze --fatal-infos && flutter test
cd packages/ispectify_ws && dart analyze --fatal-infos && dart test
cd packages/ispectify_bloc && flutter analyze --fatal-infos && flutter test
cd packages/ispect && flutter analyze --fatal-infos && flutter test
```

Grep-проверка что ничего не осталось:
```bash
grep -r "\.title" packages/*/lib/src/ --include="*.dart" | grep -v "//\|textTheme\|titleLarge\|titleMedium\|titleSmall\|AppBar\|widget.title\|this.title\|required this"
grep -r "titleByKey" packages/*/lib/ --include="*.dart"
grep -r "TitleFilter" packages/*/lib/ --include="*.dart"
grep -r "GoodLog\|AnalyticsLog\|PrintLog\|ProviderLog" packages/*/lib/ --include="*.dart"
grep -r "is RouteLog\|as RouteLog\|RouteLog?" packages/*/lib/ --include="*.dart"
```
