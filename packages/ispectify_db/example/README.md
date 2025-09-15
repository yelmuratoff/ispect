# Examples

Ниже минимальные примеры адаптеров и подключения к цепочке перехватчиков.

## Общая схема

```dart
final client = InterceptingDbClient(
  adapter: MyAdapter(driver),
  interceptors: [ISpectDbInterceptor(logger: ISpectify())],
);
final res = await client.execute<List<Map<String,Object?>>>(DbOperation(
  command: DbCommand.select,
  sql: 'SELECT 1',
));
```

## sqflite

```dart
import 'package:sqflite/sqflite.dart';
import 'package:ispectify_db/ispectify_db.dart';

final class SqfliteAdapter implements DbAdapter {
  SqfliteAdapter(this.db);
  final Database db;

  @override
  Future<DbResult<T>> execute<T>(DbOperation op) async {
    final sw = Stopwatch()..start();
    dynamic out;
    switch (op.command) {
      case DbCommand.select:
        out = await db.rawQuery(op.sql ?? '', op.params?.values.toList());
      case DbCommand.insert:
        out = await db.rawInsert(op.sql ?? '', op.params?.values.toList());
      case DbCommand.update:
        out = await db.rawUpdate(op.sql ?? '', op.params?.values.toList());
      case DbCommand.delete:
        out = await db.rawDelete(op.sql ?? '', op.params?.values.toList());
      default:
        out = await db.execute(op.sql ?? '');
    }
    sw.stop();
    final val = out as T;
    return DbResult<T>(
      value: val,
      durationMs: sw.elapsedMilliseconds,
      rowCount: val is List ? val.length : null,
    );
  }
}
```

## drift

```dart
import 'package:drift/drift.dart';
import 'package:ispectify_db/ispectify_db.dart';

final class DriftAdapter implements DbAdapter {
  DriftAdapter(this.db);
  final GeneratedDatabase db;

  @override
  Future<DbResult<T>> execute<T>(DbOperation op) async {
    final sw = Stopwatch()..start();
    dynamic out;
    // Для drift лучше напрямую вызывать db.customSelect/sql... в зависимости от op
    if (op.command == DbCommand.select) {
      final res = await db.customSelect(op.sql ?? '', variables: const []);
      out = await res.get();
    } else {
      out = await db.customStatement(op.sql ?? '');
    }
    sw.stop();
    final val = out as T;
    return DbResult<T>(value: val, durationMs: sw.elapsedMilliseconds,
      rowCount: val is List ? val.length : null);
  }
}
```

## hive

```dart
import 'package:hive/hive.dart';
import 'package:ispectify_db/ispectify_db.dart';

final class HiveAdapter implements DbAdapter {
  HiveAdapter(this.box);
  final Box box;

  @override
  Future<DbResult<T>> execute<T>(DbOperation op) async {
    final sw = Stopwatch()..start();
    dynamic out;
    switch (op.command) {
      case DbCommand.select:
        out = box.values.toList();
      case DbCommand.insert:
        out = await box.put(op.params?['key'], op.params?['value']);
      case DbCommand.update:
        out = await box.put(op.params?['key'], op.params?['value']);
      case DbCommand.delete:
        out = await box.delete(op.params?['key']);
      default:
        out = null;
    }
    sw.stop();
    final val = out as T;
    return DbResult<T>(value: val, durationMs: sw.elapsedMilliseconds,
      rowCount: val is List ? val.length : null);
  }
}
```

## isar

```dart
import 'package:isar/isar.dart';
import 'package:ispectify_db/ispectify_db.dart';

final class IsarAdapter implements DbAdapter {
  IsarAdapter(this.isar);
  final Isar isar;

  @override
  Future<DbResult<T>> execute<T>(DbOperation op) async {
    final sw = Stopwatch()..start();
    dynamic out;
    // пример: rawQuery не везде есть, показываем концепт
    if (op.command == DbCommand.select) {
      out = await isar.txn(() async {
        // конкретные запросы к коллекциям в зависимости от context/table
        return [];
      });
    } else {
      out = await isar.writeTxn(() async {
        return 1; // условно: вставка/обновление
      });
    }
    sw.stop();
    final val = out as T;
    return DbResult<T>(value: val, durationMs: sw.elapsedMilliseconds,
      rowCount: val is List ? val.length : null);
  }
}
```

## shared_preferences

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispectify_db/ispectify_db.dart';

final class SharedPreferencesAdapter implements DbAdapter {
  SharedPreferencesAdapter(this.prefs);
  final SharedPreferences prefs;

  @override
  Future<DbResult<T>> execute<T>(DbOperation op) async {
    final sw = Stopwatch()..start();
    dynamic out;
    switch (op.command) {
      case DbCommand.select:
        out = prefs.get(op.params?['key'] as String? ?? '');
      case DbCommand.insert:
      case DbCommand.update:
        out = await prefs.setString(
          op.params?['key'] as String? ?? '',
          (op.params?['value']).toString(),
        );
      case DbCommand.delete:
        out = await prefs.remove(op.params?['key'] as String? ?? '');
      default:
        out = null;
    }
    sw.stop();
    final val = out as T;
    return DbResult<T>(value: val, durationMs: sw.elapsedMilliseconds);
  }
}
```

> В примерах код упрощён для наглядности. В реальном проекте учитывайте типизацию, транзакции, ошибки, маппинг параметров.
