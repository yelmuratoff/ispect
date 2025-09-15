# ispectify_db

DB-агностичный слой логирования для ISpect на основе Port/Adapter + Interceptor Chain.

- Единые типы: `DbCommand`, `DbOperation`, `DbResult<T>`
- Цепочка перехватчиков: `DbInterceptor`
- Унифицированный адаптер: `DbAdapter`
- Готовый перехватчик логирования: `ISpectDbInterceptor` (редакция, фильтры, duration)
- Лог-ключи: `db-query`, `db-result`, `db-error`

## Установка

```yaml
dependencies:
  ispectify_db:
    path: ../ispectify_db
```

## Быстрый старт

1) Реализуйте адаптер под ваш клиент БД (sqflite/drift/hive/isar/shared_prefs…):

```dart
import 'package:ispectify_db/ispectify_db.dart';

final class MyDbAdapter implements DbAdapter {
  MyDbAdapter(this._driver);
  final Object _driver; // ваш реальный клиент

  @override
  Future<DbResult<T>> execute<T>(DbOperation op) async {
    final sw = Stopwatch()..start();
    // вызов SDK согласно op.command/sql/params...
    final T value = await _callDriver<T>(op);
    sw.stop();
    return DbResult<T>(
      value: value,
      durationMs: sw.elapsedMilliseconds,
      rowCount: value is List ? value.length : null,
    );
  }

  Future<T> _callDriver<T>(DbOperation op) async {
    // ... реальный вызов к БД
    throw UnimplementedError();
  }
}
```

2) Соберите клиент c перехватчиком ISpect:

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

final ispect = ISpectify();
final client = InterceptingDbClient(
  adapter: MyDbAdapter(/*driver*/ Object()),
  interceptors: [
    ISpectDbInterceptor(
      logger: ispect,
      settings: const ISpectDbLoggerSettings(
        printQuery: true,
        printParams: true,
        printResult: true,
        printDuration: true,
      ),
    ),
  ],
);

Future<void> example() async {
  final res = await client.execute<List<Map<String, Object?>>>(
    DbOperation(
      command: DbCommand.select,
      sql: 'SELECT id, email FROM users WHERE active = @active',
      params: {'active': true},
      driver: 'sqflite',
    ),
  );
  // res.value, res.rowCount, res.durationMs ...
}
```

## Примеры адаптеров

Смотрите `example/` — там даны минимальные адаптеры и точки интеграции под:

- sqflite
- drift
- hive
- isar
- shared_preferences

Адаптеры показывают: как превратить вызовы SDK в `DbOperation`/`DbResult`,
и как пройти через `InterceptingDbClient`.

## Настройки логирования

`ISpectDbLoggerSettings`:
- `enabled`, `enableRedaction`
- `printQuery`, `printParams`, `printResult`, `printDuration`, `printError`
- `queryPen`, `resultPen`, `errorPen`
- `queryFilter`, `resultFilter`, `errorFilter`

## UI/Цвета/Иконки

В ISpect добавлены keys: `db-query`, `db-result`, `db-error` с иконками и цветами для light/dark тем.