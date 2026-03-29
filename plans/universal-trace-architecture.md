# Universal Trace Architecture for ispectify — Final Plan

## ⚠️ Контекст для чтения этого плана

**Это план рефакторинга v5.0 с breaking changes.** Код в этом плане — это **целевое состояние**, а НЕ текущий код.

### Что НОВОЕ (создаётся с нуля):

- `ISpectTraceCategory`, `TraceCategoryIds`, `TraceKeys` — новые классы
- `ISpectTraceConfig` — новый base config (заменяет standalone конфиги)
- `ISpectTraceToken` — новый token для manual spans
- `trace()`, `traceAsync()`, `traceSync()`, `traceStart/End()`, `traceStream()`, `traceTransaction()` — extension methods на `ISpectLogger` (НЕ существуют в текущем коде)
- Domain extensions: `authTrace()`, `storageTrace()`, `push()`, `sse()`, `grpcTrace()`, `graphqlTrace()`, `paymentTrace()`, `analyticsEvent()` — все новые
- `TraceStreamTransformer` — новый
- `CategoryFilter`, `SourceFilter` — новые
- `FakeISpectLogger` — новый testing utility
- `LogExporter` — новый batch export utility
- Новые `ISpectLogType` enum values: `wsError`, `authSuccess`, `authError`, `storageResult`, `storageQuery`, `storageError`, `pushReceived`, `pushSent`, `pushError`, `paymentSuccess`, `paymentError`, `stateChange`, `stateError`, `sseReceived`, `sseError`, `grpcRequest`, `grpcResponse`, `grpcError`, `graphqlRequest`, `graphqlResponse`, `graphqlError`
- `ISpectLogType.category` field — новый
- `ISpectTheme.categoryLabels`, `ISpectTheme.logCategories` — новые поля
- `ISpectLogDataX` convenience extension — новый
- `toText()`, `toMarkdown()` на `ISpectLogDataSerialization` — новые методы в существующем extension
- Новые l10n строки: `categoryNetwork`, `categoryWebSocket`, `categoryDb`, etc.

### Что СУЩЕСТВУЕТ и ИСПОЛЬЗУЕТСЯ (из текущего кода):

- `ISpectLogger` — класс, `class ISpectLogger` (не final, extendable), `options.enabled`, `logData()`
- `ISpectLogData` — единственный log entity, конструктор с positional `Object? message` + named params
- `ISpectLogType` enum — существующие values (`httpRequest`, `httpResponse`, `httpError`, `dbQuery`, `dbResult`, `dbError`, `wsSent`, `wsReceived`, `blocEvent`, `blocTransition`, `blocState`, `blocCreate`, `blocClose`, `blocDone`, `blocError`, `riverpodAdd`, `riverpodUpdate`, `riverpodDispose`, `riverpodFail`, `route`, `good`, `analytics`, `provider`, `print`, `error`, `critical`, `info`, `debug`, `verbose`, `warning`, `exception`) + `fromKey()` static method
- `RedactionService.redactByKeys()` — static, `(Object? data, List<String> keys)`
- `defaultSensitiveKeys` — `const Set<String>` (102 entries)
- `cleanMap()` — `Map<String, Object?> → Map<String, Object?>`
- `samplePass()` — `bool samplePass(double? rate)`
- `generateTraceId()` — `String`, 16-char hex
- `BaseNetworkInterceptor` mixin — redaction logic
- `NetworkTransaction` — корреляция request/response
- `ISpectLogDataSerialization` extension — `toJson()` method
- `Filter<T>` abstract class — `bool apply(T item)`
- `LogLevel` enum — `critical`, `error`, `warning`, `info`, `debug`, `verbose`
- `ISpectBlocObserver` — `_shouldLog({required bool toggle, required Object? candidate})`
- `ISpectDbConfig` — standalone класс (НЕ наследует ничего)
- `ISpectDbCore` — static utilities (`truncateValue`, `sqlDigest`, `redactPositionalArgs`)

### Что УДАЛЯЕТСЯ (clean break v5.0):

- Typed log subclasses: `NetworkRequestLog`, `NetworkResponseLog`, `NetworkErrorLog`, `BaseNetworkLog`
- Dio models: `DioRequestLog`, `DioResponseLog`, `DioErrorLog`
- HTTP models: `HttpRequestLog`, `HttpResponseLog`, `HttpErrorLog`
- WS models: `WSSentLog`, `WSReceivedLog`, `WSErrorLog`, `WSLogFields`
- BLoC models: `BlocLifecycleLog` (sealed) + 7 subclasses
- `kRequestIdKey` constant (заменяется на `'requestId'` в meta)

### Что РЕФАКТОРИТСЯ (существующий код изменяется):

- `ISpectLogType` — добавляется `category` field, новые enum values
- `ISpectDbConfig` — теперь `extends ISpectTraceConfig` (`slowQueryThreshold` → `slowThreshold`)
- `ISpectBlocObserver` — вместо typed subclasses → `logger.trace()`
- Dio/HTTP/WS interceptors — вместо typed subclasses → `logger.trace()` с `logKey`
- `NetworkTransaction` — fallback getters обновляются (`method`→`operation`, `url`→`target`, `statusCode`→`meta.statusCode`)
- `NetworkTransactionService` — requestId extraction из `meta['requestId']`
- `ISpectLogDataSerialization` — добавляются `toText()`, `toMarkdown()`
- `ISpectTheme` — добавляются `categoryLabels`, `logCategories`
- `log_type_filter_section.dart` — hardcoded prefix matching → dynamic `_resolveCategory`
- `LogCard`/`DesktopLogRow` — `additionalData?['statusCode']` → `data.httpStatusCode`
- `ISpectConstants` — новые icons/colors для новых log types

### Ключевые именования (breaking changes):

- `kRequestIdKey = 'request-id'` (kebab) → `'requestId'` (camelCase, nested в meta)
- `ISpectDbConfig.slowQueryThreshold` → `ISpectTraceConfig.slowThreshold`
- `additionalData['method']` → `additionalData['operation']` (TraceKeys.operation)
- `additionalData['url']` → `additionalData['target']` (TraceKeys.target)
- `additionalData['statusCode']` (top-level) → `additionalData['meta']['statusCode']` (nested)

---

## Цель

Единый trace-фундамент для логирования **любых** операций в мобильном приложении. Всё проходит через один pipeline. Всё видно в ISpect UI. Всё фильтруется без хардкода. Логи легко экспортируются как JSON/txt/md. JSON viewer — единственный detail view (простой, универсальный, минимум поддержки).

**Принципы:**

- KISS > over-engineering. Если можно проще — делаем проще.
- SOLID, DRY, но без преждевременных абстракций.
- Testable, flexible, expandable. Добавление нового сервиса = минимум кода.
- Zero overhead в production (tree-shaking, early bail-out).
- Код легко поддерживать — меньше кастомного, больше generic.

---

## Part 1: Core Trace Foundation (`packages/ispectify/lib/src/trace/`)

### 1.1. `ISpectTraceCategory`

Определяет категорию. Каждый домен создаёт `const` экземпляр. `pickLogKey()` — единственный метод, тесно связан с данными категории (не нарушает `const`).

```dart
/// trace_category.dart

@immutable
final class ISpectTraceCategory {
  const ISpectTraceCategory({
    required this.id,
    required this.successKey,
    required this.errorKey,
    this.secondaryKey,
    this.secondaryOperations = const {},  // ← MUST be const {} for immutability
  });

  final String id;                        // 'network', 'db', 'ws', 'auth', ...
  final String successKey;                // log key при успехе (default)
  final String errorKey;                  // log key при ошибке
  final String? secondaryKey;             // optional: альтернативный success key
  /// Operations that use secondaryKey instead of successKey.
  /// **MUST be const** for @immutable contract: `const {'GET', 'HEAD'}`.
  /// Never pass a mutable Set — use `const {}` or `Set.unmodifiable()`.
  final Set<String> secondaryOperations;

  /// Determines the log key based on error state and operation.
  ///
  /// For HTTP: secondaryKey = 'http-request', secondaryOperations = {'GET', 'HEAD'}
  ///   → GET request → 'http-request'; POST response → 'http-response'; error → 'http-error'
  ///
  /// For WS: secondaryKey = 'ws-sent', secondaryOperations = {'send'}
  ///   → send → 'ws-sent'; receive → 'ws-received'; error → 'ws-error'
  ///
  /// For DB: secondaryKey = 'db-query', secondaryOperations = {'query', 'get', 'select', ...}
  ///   → select → 'db-query'; insert → 'db-result'; error → 'db-error'
  String pickLogKey({required bool isError, required String operation}) {
    if (isError) return errorKey;
    if (secondaryKey != null && secondaryOperations.contains(operation)) {
      return secondaryKey!;
    }
    return successKey;
  }
}
```

> **Почему нет `messageBuilder`:** Message formatting — в trace pipeline через единый `buildTraceMessage()` (top-level function в `trace_message.dart`). Не нужен per-category — message это одна строка в списке, а детали всегда в JSON viewer.

### 1.2. SSOT: Category ID и Log Key константы

> **SSOT проблема:** Category ID строки (`'network'`, `'db'`, `'auth'`, ...) и log key строки (`'http-request'`, `'db-query'`, ...)
> используются в 4 местах: `ISpectTraceCategory`, `ISpectLogType`, `_resolveCategory`, `_categoryLabel`.
> Если опечатка в одном месте — сломается группировка/фильтрация.
>
> **Решение:** Единые const строки. Все 4 места ссылаются на них.

```dart
/// trace_category_ids.dart — SSOT для category ID строк

abstract final class TraceCategoryIds {
  // ── Network protocols (по семантике протокола, не по transport layer) ──
  static const network = 'network';   // HTTP REST (Dio, http, Chopper)
  static const ws = 'ws';             // WebSocket (bidirectional)
  static const sse = 'sse';           // Server-Sent Events (unidirectional)
  static const grpc = 'grpc';         // gRPC (HTTP/2 + protobuf)
  static const graphql = 'graphql';   // GraphQL (query/mutation/subscription)

  // ── Data & state ─────────────────────────────────────────────────────
  static const db = 'db';             // Database (SQL, NoSQL, KV)
  static const state = 'state';       // State management (BLoC, Riverpod, MobX)

  // ── Services ─────────────────────────────────────────────────────────
  static const auth = 'auth';         // Authentication (sign in/out/up, token refresh)
  static const storage = 'storage';   // File/Object storage (upload, download)
  static const push = 'push';         // Push notifications (FCM, OneSignal)
  static const analytics = 'analytics'; // Analytics events
  static const payment = 'payment';   // Payments, in-app purchases

  // ── UI ────────────────────────────────────────────────────────────────
  static const navigation = 'navigation'; // Route changes

  // ── Fallback ──────────────────────────────────────────────────────────
  static const general = 'general';

  /// Все built-in category IDs. Используется в UI для prefix heuristic.
  static const builtIn = {
    network, ws, sse, grpc, graphql,
    db, state,
    auth, storage, push, analytics, payment,
    navigation,
  };
}
```

### 1.2b. Предопределённые категории

```dart
/// trace_categories.dart
/// Все category ID и log key ссылаются на ISpectLogType.key через константы.
///
/// NB: `final` а не `const` — в Dart `.key` property access на enum value
/// НЕ является compile-time constant expression. `final` top-level variable
/// инициализируется lazily при первом обращении (guaranteed single init).

final networkCategory = ISpectTraceCategory(
  id: TraceCategoryIds.network,
  successKey: ISpectLogType.httpResponse.key,
  errorKey: ISpectLogType.httpError.key,
  secondaryKey: ISpectLogType.httpRequest.key,
  secondaryOperations: const {'GET', 'HEAD', 'OPTIONS'},
);

final dbCategory = ISpectTraceCategory(
  id: TraceCategoryIds.db,
  successKey: ISpectLogType.dbResult.key,
  errorKey: ISpectLogType.dbError.key,
  secondaryKey: ISpectLogType.dbQuery.key,
  secondaryOperations: const {'query', 'get', 'select', 'find', 'count', 'list'},
);

final authCategory = ISpectTraceCategory(
  id: TraceCategoryIds.auth,
  successKey: ISpectLogType.authSuccess.key,
  errorKey: ISpectLogType.authError.key,
);

final wsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.ws,
  successKey: ISpectLogType.wsReceived.key,  // receive → default success
  errorKey: ISpectLogType.wsError.key,       // error
  secondaryKey: ISpectLogType.wsSent.key,    // send → secondary
  secondaryOperations: const {'send'},
);

final sseCategory = ISpectTraceCategory(
  id: TraceCategoryIds.sse,
  successKey: ISpectLogType.sseReceived.key,
  errorKey: ISpectLogType.sseError.key,
);

final storageCategory = ISpectTraceCategory(
  id: TraceCategoryIds.storage,
  successKey: ISpectLogType.storageResult.key,
  errorKey: ISpectLogType.storageError.key,
  secondaryKey: ISpectLogType.storageQuery.key,
  secondaryOperations: const {'download', 'list', 'getUrl', 'getMetadata'},
);

final stateCategory = ISpectTraceCategory(
  id: TraceCategoryIds.state,
  successKey: ISpectLogType.stateChange.key,
  errorKey: ISpectLogType.stateError.key,
);

final pushCategory = ISpectTraceCategory(
  id: TraceCategoryIds.push,
  successKey: ISpectLogType.pushReceived.key,
  errorKey: ISpectLogType.pushError.key,
  secondaryKey: ISpectLogType.pushSent.key,
  secondaryOperations: const {'sent', 'send'},
);

// NB: analyticsCategory использует один key для success и error.
// Осознанное решение: analytics events редко имеют distinct error types.
// Если в будущем нужна дифференциация — добавить ISpectLogType.analyticsError.
final analyticsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.analytics,
  successKey: ISpectLogType.analytics.key,
  errorKey: ISpectLogType.analytics.key,  // same — intentional (KISS)
);

final paymentCategory = ISpectTraceCategory(
  id: TraceCategoryIds.payment,
  successKey: ISpectLogType.paymentSuccess.key,
  errorKey: ISpectLogType.paymentError.key,
);

// NB: navigationCategory — route push и pop связаны через correlationId.
// ISpectNavigatorObserver генерирует routeId при push и передаёт как correlationId
// во все связанные events (push, pop, replace, remove) одного route.
// Пользователь может нажать "Show Related" на push и увидеть pop (и наоборот).
final navigationCategory = ISpectTraceCategory(
  id: TraceCategoryIds.navigation,
  successKey: ISpectLogType.route.key,
  errorKey: ISpectLogType.route.key,  // same — intentional (KISS)
);

// NB: gRPC использует traceStart/traceEnd → ОДИН лог per call.
// Для one-log протоколов secondary/success distinction менее важна,
// но сохранена для consistency с UI фильтрацией:
// - 'grpc-request' = read-only операции (unary query, server streaming subscription)
// - 'grpc-response' = write/mutate операции (не в secondaryOperations → default success)
// - 'grpc-error' = ошибки
// Если семантика не подходит — interceptor может использовать explicit logKey override.
final grpcCategory = ISpectTraceCategory(
  id: TraceCategoryIds.grpc,
  successKey: ISpectLogType.grpcResponse.key,
  errorKey: ISpectLogType.grpcError.key,
  secondaryKey: ISpectLogType.grpcRequest.key,
  secondaryOperations: const {'unary', 'serverStreaming'},
);

final graphqlCategory = ISpectTraceCategory(
  id: TraceCategoryIds.graphql,
  successKey: ISpectLogType.graphqlResponse.key,
  errorKey: ISpectLogType.graphqlError.key,
  secondaryKey: ISpectLogType.graphqlRequest.key,
  secondaryOperations: const {'query', 'subscription'},
);
```

> **SSOT:** Category ID → `TraceCategoryIds`. Log key → `ISpectLogType.*.key`. Одно место правды.
> **`final` not `const`:** В Dart, `EnumValue.field` не является compile-time constant expression. `final` top-level variable — lazy initialized, single init, immutable after.
> **Новые категории:** `final myCategory = ISpectTraceCategory(id: 'xxx', ...)`. Пользователь использует свои строки — нет ограничений.
> Редко используемые (background, performance) — не определяем заранее, пользователь создаёт сам когда нужно.

### 1.3. `ISpectTraceConfig`

```dart
/// trace_config.dart

@immutable
class ISpectTraceConfig {
  const ISpectTraceConfig({
    this.sampleRate,
    this.errorSampleRate = 1.0,    // errors всегда логируются (default 100%)
    this.redact = true,
    this.redactKeys = defaultSensitiveKeys,  // Set<String> — matches type
    this.maxValueLength = 500,
    this.attachStackOnError = false,
    this.slowThreshold,
  });

  /// Sampling rate for successful operations.
  /// - `null` (default) → log ALL successful operations (no sampling)
  /// - `1.0` → log all (same as null)
  /// - `0.5` → log ~50%
  /// - `0.0` → log none (suppress all success logs)
  final double? sampleRate;

  /// Sampling rate for error operations (default: 1.0 = log all errors).
  /// **WARNING:** Setting to `0.0` completely suppresses ALL error logs.
  /// This is dangerous for production monitoring — errors will be silently dropped.
  /// Use with extreme caution. Prefer `1.0` (default) for errors.
  final double errorSampleRate;
  final bool redact;
  final Set<String> redactKeys;       // Set — matches defaultSensitiveKeys type
  final int maxValueLength;
  final bool attachStackOnError;
  final Duration? slowThreshold;

  /// Sampling precedence (от высшего к низшему):
  /// 1. Error → `errorSampleRate` (всегда, игнорирует localSample и sampleRate)
  /// 2. `localSample` (per-call `sample:` параметр в trace/traceAsync/etc.)
  /// 3. `sampleRate` (config-level, задаётся при создании ISpectTraceConfig)
  /// 4. `null` → log ALL (default — нет sampling)
  ///
  /// Пример: config sampleRate=0.5, но trace(sample: 1.0) → логируется всегда
  /// (localSample побеждает config). Error → всегда errorSampleRate.
  bool shouldLog({double? localSample, required bool isError}) {
    final rate = isError ? errorSampleRate : (localSample ?? sampleRate);
    return rate == null || samplePass(rate);
  }

  /// NB: Subclasses (e.g. ISpectDbConfig) MUST override copyWith()
  /// to preserve their additional fields. Without override, copyWith()
  /// returns ISpectTraceConfig and loses DB-specific fields.
  /// `@mustBeOverridden` (package:meta) gives analyzer warning if subclass forgets.
  @mustBeOverridden
  ISpectTraceConfig copyWith({...});
}
```

> **Почему нет `operationFilters`:** YAGNI. `sampleRate` + `errorSampleRate` покрывает 99% кейсов. Если нужен per-operation контроль — пользователь задаёт `sample` параметр при вызове `trace()`.

### 1.4. `ISpectTraceToken`

````dart
/// trace_token.dart

/// Constructor is NOT private: trace_extension.dart needs access from a different file.
/// Class is `final` — cannot be subclassed, so public constructor is safe.
/// NB: `traceStart()` returns `ISpectTraceToken?` (nullable) — null when logger disabled.
/// **Intentional:** `logKey` is NOT stored in the token. traceStart/traceEnd is designed
/// for single-log protocols where `pickLogKey()` is sufficient. For two-log protocols
/// (HTTP request/response) use `trace()` directly with explicit `logKey` override.
///
/// **Lifetime:** ВСЕГДА вызывайте `traceEnd()` после `traceStart()`.
/// Если `traceEnd()` не вызван — Stopwatch продолжает работать до GC (bytes-level leak).
/// `traceStart()` возвращает `null` если logger disabled → `traceEnd(null)` — no-op.
/// Best practice:
/// ```dart
/// final token = logger.traceStart(...);
/// // token может быть null если logger disabled — traceEnd(null) безопасен
/// try {
///   final result = await doWork();
///   logger.traceEnd(token, value: result, success: true);
/// } catch (e, st) {
///   logger.traceEnd(token, error: e, errorStackTrace: st);
///   rethrow;
/// }
/// ```
final class ISpectTraceToken {
  ISpectTraceToken({
    required Stopwatch stopwatch,
    required this.category,
    required this.source,
    required this.operation,
    this.target,
    this.key,
    this.meta,
    this.config,
    this.correlationId,
  }) : _stopwatch = stopwatch;

  final Stopwatch _stopwatch;
  final ISpectTraceCategory category;
  final String source;
  final String operation;
  final String? target;
  final String? key;
  final Map<String, Object?>? meta;
  final ISpectTraceConfig? config;
  final String? correlationId;

  void stopTiming() => _stopwatch.stop();
  Duration get elapsed => _stopwatch.elapsed;
}
````

### 1.5. `TraceKeys`

````dart
/// trace_keys.dart

/// Ключи TRACE ENVELOPE — top-level поля в `additionalData`.
/// НЕ путать с `NetworkJsonKeys` — те используются ВНУТРИ `meta` для domain payload.
///
/// Структура additionalData:
/// ```
/// {
///   TraceKeys.category: 'network',      // ← envelope (TraceKeys)
///   TraceKeys.source: 'dio',            // ← envelope
///   TraceKeys.operation: 'GET',         // ← envelope (= HTTP method)
///   TraceKeys.target: '/api/users',     // ← envelope (= URL)
///   TraceKeys.meta: {                   // ← envelope
///     'requestId': 'abc123',            // ← domain payload
///     'statusCode': 200,               // ← domain payload
///     'requestData': { ... },          // ← domain payload (uses NetworkJsonKeys internally)
///   },
/// }
/// ```
/// `TraceKeys.operation` и `NetworkJsonKeys.method` семантически связаны,
/// но живут на РАЗНЫХ уровнях: `operation` = trace envelope (top-level),
/// `method` = domain detail внутри requestData (nested в meta).
abstract final class TraceKeys {
  static const category = 'category';
  static const source = 'source';
  static const operation = 'operation';
  static const target = 'target';
  static const key = 'key';
  static const value = 'value';
  static const durationMs = 'durationMs';
  static const slow = 'slow';
  static const success = 'success';
  static const error = 'error';
  static const meta = 'meta';
  static const transactionId = 'transactionId';
  static const correlationId = 'correlationId';  // links related traces (request↔response, stream events)
}
````

### 1.6. `ISpectTrace` extension на `ISpectLogger`

````dart
/// trace_extension.dart

/// File-private zone key — prevents external code from reading/spoofing txnId.
/// Symbol literals like #ispectTxnId are public and accessible from any file.
final _txnZoneKey = Object();

extension ISpectTrace on ISpectLogger {

  // ── Fire-and-forget ─────────────────────────────────
  void trace({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    Object? value,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Duration? duration,
    Map<String, Object?>? meta,
    double? sample,
    ISpectTraceConfig? config,
    String? logKey,  // ← overrides category.pickLogKey() if provided
    String? correlationId,  // ← links related traces (e.g. gRPC request↔response, stream events)
    LogLevel? logLevel,  // ← overrides default (error→LogLevel.error, success→LogLevel.info)
  }) {
    if (!options.enabled) return;  // ← zero overhead в production

    final cfg = config ?? const ISpectTraceConfig();
    final isError = error != null || success == false;

    if (!cfg.shouldLog(localSample: sample, isError: isError)) return;

    final resolvedLogKey = logKey ?? category.pickLogKey(isError: isError, operation: operation);

    // NB: safeTrace — top-level function из trace_helpers.dart.
    // ВСЯ логика (message, redaction, zone, map, constructor) — внутри lazy builder.
    // Если что-то бросит исключение (redactByKeys, buildTraceMessage, etc.) —
    // safeTrace() поймает и предотвратит propagation. Ни один trace не может
    // сломать приложение.
    safeTrace(this, () {
      // Auto-redaction target (URLs с pre-signed tokens, query params с credentials)
      // NB: target попадает в buildTraceMessage() output → виден в UI списке.
      // Pre-signed URLs (S3, GCS) содержат tokens в query params.
      // Без auto-redaction target — PII утечка в message и additionalData.
      final safeTarget = cfg.redact && target != null
          ? RedactionService.redactTarget(target, cfg.redactKeys)
          : target;

      // Единый формат: [source] operation → target (duration)
      final message = buildTraceMessage(
        source: source, operation: operation,
        target: safeTarget, key: key, duration: duration,
        success: !isError,
      );

      // Auto-redaction meta по config.redactKeys
      // NB: v5.0 breaking change — redactByKeys API меняется на Iterable<String>.
      // До миграции API — используем cfg.redactKeys.toList() как fallback.
      // После миграции — убрать .toList() (Set совместим с Iterable напрямую).
      final safeMeta = cfg.redact
          ? RedactionService.redactByKeys(meta, cfg.redactKeys.toList())
          : meta;

      // Auto-inject transaction ID from zone (set by traceTransaction)
      // Defensive cast: avoids CastException if zone value is non-String.
      final rawTxnId = Zone.current[_txnZoneKey];
      final zoneTxnId = rawTxnId is String ? rawTxnId : null;

      final additionalData = <String, Object?>{
        TraceKeys.category: category.id,
        TraceKeys.source: source,
        TraceKeys.operation: operation,
        if (safeTarget != null) TraceKeys.target: safeTarget,
        if (key != null) TraceKeys.key: key,
        if (value != null) TraceKeys.value: truncateValue(value, cfg.maxValueLength),
        if (duration != null) TraceKeys.durationMs: duration.inMilliseconds,
        if (duration != null && cfg.slowThreshold != null)
          TraceKeys.slow: duration > cfg.slowThreshold!,
        TraceKeys.success: !isError,
        if (error != null) TraceKeys.error: '$error',
        if (zoneTxnId != null) TraceKeys.transactionId: zoneTxnId,
        if (correlationId != null) TraceKeys.correlationId: correlationId,
        if (safeMeta != null) TraceKeys.meta: safeMeta,
      };

      return ISpectLogData(
        message,
        key: resolvedLogKey,
        // logLevel override allows custom severity (e.g., LogLevel.warning for deprecation traces).
        // Default: error→LogLevel.error, success→LogLevel.info (covers 99% of cases).
        logLevel: logLevel ?? (isError ? LogLevel.error : LogLevel.info),
        additionalData: additionalData,
        exception: error is Exception ? error : null,
        error: error is Error ? error : null,
        stackTrace: isError && cfg.attachStackOnError ? errorStackTrace : null,
      );
    });
  }

  // ── Async wrapper с auto-timing ─────────────────────
  Future<T> traceAsync<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectResult,
    double? sample,
    ISpectTraceConfig? config,
    String? logKey,
    LogLevel? logLevel,
    String? correlationId,
  }) async {
    if (!options.enabled) return run();  // zero overhead

    final cfg = config ?? const ISpectTraceConfig();
    // Не проверяем sample до run() — всегда выполняем операцию, только лог может быть пропущен

    final sw = Stopwatch()..start();
    try {
      final result = await run();
      sw.stop();

      Object? projected;
      if (projectResult != null) {
        try { projected = projectResult(result); } catch (_) {}
      }

      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, value: projected,
        success: true, duration: sw.elapsed,
        meta: meta, config: cfg, sample: sample, logKey: logKey,
        correlationId: correlationId, logLevel: logLevel,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, error: e, errorStackTrace: st,
        success: false, duration: sw.elapsed,
        meta: meta, config: cfg, sample: sample, logKey: logKey,
        correlationId: correlationId, logLevel: logLevel,
      );
      rethrow;
    }
  }

  // ── Sync wrapper ────────────────────────────────────
  T traceSync<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required T Function() run,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectResult,
    double? sample,
    ISpectTraceConfig? config,
    String? logKey,
    String? correlationId,
    LogLevel? logLevel,
  }) {
    if (!options.enabled) return run();  // zero overhead

    final sw = Stopwatch()..start();
    try {
      final result = run();
      sw.stop();

      Object? projected;
      if (projectResult != null) {
        try { projected = projectResult(result); } catch (_) {}
      }

      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, value: projected,
        success: true, duration: sw.elapsed,
        meta: meta, config: config, sample: sample, logKey: logKey,
        correlationId: correlationId, logLevel: logLevel,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, error: e, errorStackTrace: st,
        success: false, duration: sw.elapsed,
        meta: meta, config: config, sample: sample, logKey: logKey,
        correlationId: correlationId, logLevel: logLevel,
      );
      rethrow;
    }
  }

  // ── Manual span (request → response) ────────────────
  /// Returns `null` if logger is disabled — caller MUST check:
  /// ```dart
  /// final token = logger.traceStart(...);
  /// if (token == null) { /* just do the work without tracing */ }
  /// ```
  /// Alternatively, use traceAsync/traceSync which handle this automatically.
  ISpectTraceToken? traceStart({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return null;  // ← zero overhead when disabled
    return ISpectTraceToken(
      stopwatch: Stopwatch()..start(),
      category: category, source: source, operation: operation,
      target: target, key: key, meta: meta, config: config,
      correlationId: correlationId,
    );
  }

  /// `token` is nullable — if `traceStart()` returned null (logger disabled), this is a no-op.
  void traceEnd(
    ISpectTraceToken? token, {
    Object? value,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
  }) {
    if (token == null) return;  // ← logger was disabled at traceStart
    token.stopTiming();
    trace(
      category: token.category,
      source: token.source,
      operation: token.operation,
      target: token.target,
      key: token.key,
      value: value,
      success: success ?? (error == null),
      error: error,
      errorStackTrace: errorStackTrace,
      duration: token.elapsed,
      // NB: End-time meta overrides start-time meta on key collision (last-write-wins).
      // Intentional: traceEnd may update fields set at traceStart
      // (e.g., updating 'request' with actual data not available at start).
      meta: {...?token.meta, ...?meta},
      config: token.config,
      correlationId: token.correlationId,
    );
  }

  // ── Stream tracing ──────────────────────────────────
  Stream<T> traceStream<T>({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    required Stream<T> stream,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    Object? Function(T value)? projectEvent,
    double? sample,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return stream;  // zero overhead

    // Auto-generate correlationId if not provided — links all stream events
    final corrId = correlationId ?? generateTraceId();

    // Pure Dart StreamTransformer (см. 1.7 ниже)
    return stream.transform(TraceStreamTransformer<T>(
      onListen: () => trace(
        category: category, source: source,
        operation: '$operation.subscribe', target: target,
        success: true, config: config, correlationId: corrId,
      ),
      onData: (data) {
        Object? projected;
        if (projectEvent != null) {
          try { projected = projectEvent(data); } catch (_) {}
        }
        trace(
          category: category, source: source,
          operation: '$operation.event', target: target,
          value: projected, success: true,
          sample: sample, config: config, correlationId: corrId,
        );
      },
      onError: (e, st) => trace(
        category: category, source: source,
        operation: '$operation.error', target: target,
        error: e, errorStackTrace: st, success: false,
        config: config, correlationId: corrId,
      ),
      onCancel: () => trace(
        category: category, source: source,
        operation: '$operation.unsubscribe', target: target,
        success: true, config: config, correlationId: corrId,
      ),
    ));
  }

  // ── Transaction (zone-based ID, auto-injected into all inner trace() calls) ──
  // NB: Zone values do NOT cross isolate boundaries. If you spawn isolates
  // inside a transaction, inner traces in the isolate won't have txnId.
  // Use explicit correlationId parameter for cross-isolate correlation.
  // Zone key: _txnZoneKey (file-private Object, not public Symbol #ispectTxnId).
  Future<T> traceTransaction<T>({
    required ISpectTraceCategory category,
    required String source,
    required Future<T> Function() run,
    bool logMarkers = false,
  }) async {
    final txnId = generateTraceId();
    return runZoned(
      () async {
        // NB: txnId NOT passed in meta — auto-injected by trace() from zone.
        // No redundancy: additionalData['transactionId'] appears once (top-level).
        //
        // logMarkers=false НЕ влияет на transactionId injection.
        // false = не логировать transaction-begin/commit/rollback маркеры.
        // transactionId всё равно auto-inject'ится во ВСЕ inner trace() вызовы через zone.
        // Маркеры — опциональная визуальная помощь для отделения начала/конца транзакции в UI.
        if (logMarkers) {
          trace(category: category, source: source,
            operation: 'transaction-begin', success: true);
        }
        try {
          final result = await run();
          if (logMarkers) {
            trace(category: category, source: source,
              operation: 'transaction-commit', success: true);
          }
          return result;
        } catch (e, st) {
          if (logMarkers) {
            trace(category: category, source: source,
              operation: 'transaction-rollback', error: e,
              errorStackTrace: st, success: false);
          }
          rethrow;
        }
      },
      zoneValues: {_txnZoneKey: txnId},
    );
  }
}
````

### 1.7. `TraceStreamTransformer` — pure Dart, без rxdart

```dart
/// trace_stream_transformer.dart
///
/// **Lifecycle & cleanup guarantees:**
/// - `onListen` → вызывается при первом subscribe
/// - `onData` → для каждого события (не блокирует downstream)
/// - `onError` → для каждой ошибки, ошибка ПРОПАГИРУЕТСЯ дальше (не глотается)
/// - `onCancel` → вызывается при cancel subscription ИЛИ при onDone upstream
/// - Если onData/onError/onCancel/onListen бросят — исключение НЕ ломает stream,
///   а ловится через safeCall() wrapper (логируется через logger, не propagate)
///
/// **Memory safety:**
/// - StreamController closed при onDone или onCancel → нет утечек
/// - StreamSubscription cancelled при onCancel → upstream cleanup
/// - sync: true → нет micro-task queue overhead

class TraceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  TraceStreamTransformer({
    required this.onListen,
    required this.onData,
    required this.onError,
    required this.onCancel,
  });

  final void Function() onListen;
  final void Function(T data) onData;
  final void Function(Object error, StackTrace stackTrace) onError;
  final void Function() onCancel;

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamSubscription<T> sub;
    late StreamController<T> controller;
    var _cancelCalled = false; // guard against double-call

    controller = StreamController<T>(
      onListen: () {
        try { onListen(); } catch (_) {}
        sub = stream.listen(
          (data) {
            try { onData(data); } catch (_) {}
            if (!controller.isClosed) controller.add(data);
          },
          onError: (Object e, StackTrace st) {
            try { onError(e, st); } catch (_) {}
            if (!controller.isClosed) controller.addError(e, st);
          },
          onDone: () {
            // Stream ended normally. Call onCancel ONCE.
            if (!_cancelCalled) {
              _cancelCalled = true;
              try { onCancel(); } catch (_) {}
            }
            controller.close();
          },
        );
      },
      onPause: () => sub.pause(),
      onResume: () => sub.resume(),
      onCancel: () {
        // User cancelled subscription. Call onCancel ONCE.
        // NB: sub.cancel() may trigger onDone on some stream types.
        // _cancelCalled guard prevents double logging.
        if (!_cancelCalled) {
          _cancelCalled = true;
          try { onCancel(); } catch (_) {}
        }
        return sub.cancel();
      },
      sync: true,
    );

    return controller.stream;
  }
}
```

> **Cleanup гарантии:**
>
> - `onCancel` вызывается РОВНО ОДИН РАЗ — либо при `subscription.cancel()`, либо при `onDone` upstream (кто первый)
> - `_cancelCalled` guard предотвращает double-call: `sub.cancel()` может trigger `onDone` на некоторых stream types → без guard были бы 2 trace лога "unsubscribe"
> - Если stream = broadcast, `onDone` НЕ вызывается при cancel одного listener → `onCancel` в controller обработает
> - Все trace callbacks обёрнуты в try/catch — исключение в логировании НИКОГДА не ломает data stream
> - `sub.cancel()` возвращает Future → controller ждёт cleanup upstream

### 1.8. Default message formatter

```dart
/// trace_message.dart

/// Единый формат для всех категорий.
/// Детали — в JSON viewer. Message — только summary для списка.
String buildTraceMessage({
  required String source,
  required String operation,
  String? target,
  String? key,
  Duration? duration,
  required bool success,
}) {
  final buffer = StringBuffer()
    ..write('[$source] ')
    ..write(operation);

  if (target != null) buffer.write(' → $target');
  if (key != null) buffer.write(' ($key)');
  if (duration != null) buffer.write(' ${duration.inMilliseconds}ms');
  if (!success) buffer.write(' FAILED');

  return buffer.toString();
}
```

> **Один формат для всех.** Не нужен per-category message builder — message это summary, детали в JSON.

---

## Part 2: Domain Extensions (в `ispectify` core)

Pure Dart, zero deps, tree-shakeable. Каждый ~15-25 строк. Задают category + именованные параметры.

> **Performance pattern:** Все domain extensions делают early bail `if (!options.enabled)` ПЕРЕД
> построением meta Map. Это гарантирует zero overhead в production (disabled ISpect).
> Async extensions возвращают `run()` напрямую, fire-and-forget просто return.

### 2.1. Auth

```dart
extension ISpectLoggerAuth on ISpectLogger {
  /// **Security:** `userId` передаётся в `meta` (не в `key`), чтобы:
  /// 1. Не попадать в `buildTraceMessage()` output (message видна в UI списке)
  /// 2. Быть redacted через Layer 2 если 'userId' добавлен в `config.redactKeys`
  /// По-умолчанию 'userId' НЕ в `defaultSensitiveKeys` — добавьте явно если нужно.
  Future<T> authTrace<T>({
    required String source,     // 'firebase', 'supabase', 'appwrite'
    required String operation,  // 'signIn', 'signOut', 'signUp', 'tokenRefresh'
    required Future<T> Function() run,
    String? userId,
    String? provider,           // 'google', 'apple', 'email', 'phone'
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();  // ← zero overhead when disabled
    return traceAsync(
      category: authCategory,
      source: source,
      operation: operation,
      // NB: userId НЕ в key (key попадает в message string — PII leak risk).
      // userId в meta — redactable через config.redactKeys.
      meta: {
        if (userId != null) 'userId': userId,
        if (provider != null) 'provider': provider,
        ...?meta,
      },
      run: run,
      projectResult: projectResult,
      config: config,
      correlationId: correlationId,
    );
  }

  void auth({
    required String source,
    required String operation,
    String? userId,
    String? provider,
    bool? success,
    Object? error,
    Duration? duration,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;  // ← zero overhead when disabled
    trace(
      category: authCategory,
      source: source,
      operation: operation,
      success: success,
      error: error,
      duration: duration,
      meta: {
        if (userId != null) 'userId': userId,
        if (provider != null) 'provider': provider,
        ...?meta,
      },
      config: config,
      correlationId: correlationId,
    );
  }
}
```

> **Pattern для ВСЕХ domain extensions:** async → `if (!options.enabled) return run();`,
> fire-and-forget → `if (!options.enabled) return;`. Применить в 2.2-2.8 аналогично.

### 2.2. Storage

```dart
extension ISpectLoggerStorage on ISpectLogger {
  Future<T> storageTrace<T>({
    required String source,
    required String operation,  // 'upload', 'download', 'delete', 'list'
    required Future<T> Function() run,
    String? bucket,
    String? path,
    int? sizeBytes,
    String? contentType,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();  // ← zero overhead when disabled
    return traceAsync(
      category: storageCategory,
      source: source, operation: operation,
      target: path,
      config: config,
      correlationId: correlationId,
      meta: {
        if (bucket != null) 'bucket': bucket,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        if (contentType != null) 'contentType': contentType,
        ...?meta,
      },
      run: run, projectResult: projectResult,
    );
  }
}
```

### 2.3. Push

```dart
extension ISpectLoggerPush on ISpectLogger {
  void push({
    required String source,     // 'fcm', 'onesignal', 'local'
    required String operation,  // 'received', 'opened', 'dismissed', 'sent'
    String? title,
    String? topic,
    String? messageId,
    Map<String, Object?>? data,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;  // ← zero overhead when disabled
    trace(
      category: pushCategory,
      source: source, operation: operation,
      key: messageId,
      meta: {
        if (title != null) 'title': title,
        if (topic != null) 'topic': topic,
        if (data != null) 'data': data,
        ...?meta,
      },
      config: config,
      // Auto-correlation: если correlationId не задан, используем messageId.
      // Это позволяет связать lifecycle одной нотификации (received → opened → dismissed)
      // без необходимости вручную передавать correlationId.
      correlationId: correlationId ?? messageId,
    );
  }
}
```

> **NB: Push auto-correlation.** `push()` автоматически использует `messageId` как `correlationId`
> если `correlationId` не задан явно. Это устраняет дублирование и предотвращает ошибки:
> `logger.push(source: 'fcm', operation: 'received', messageId: id);`
> `logger.push(source: 'fcm', operation: 'opened', messageId: id);`
> Все события одного push-уведомления автоматически связаны через generic correlation banner.
> Если нужен другой correlationId — передать явно (override auto-fallback).

### 2.4. Analytics

```dart
extension ISpectLoggerAnalytics on ISpectLogger {
  void analyticsEvent({
    required String source,     // 'firebase', 'mixpanel', 'amplitude'
    required String event,
    Map<String, Object?>? parameters,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;  // ← zero overhead when disabled
    trace(
      category: analyticsCategory,
      source: source, operation: event,
      meta: parameters, success: true,
      config: config,
      correlationId: correlationId,
    );
  }
}
```

### 2.5. Payment

```dart
extension ISpectLoggerPayment on ISpectLogger {
  Future<T> paymentTrace<T>({
    required String source,
    required String operation,
    required Future<T> Function() run,
    String? productId,
    double? amount,
    String? currency,
    Map<String, Object?>? meta,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();  // ← zero overhead when disabled
    return traceAsync(
      category: paymentCategory,
      source: source, operation: operation,
      key: productId,
      meta: {
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
        ...?meta,
      },
      run: run, projectResult: projectResult,
      config: config, correlationId: correlationId,
    );
  }
}
```

### 2.6. SSE

```dart
extension ISpectLoggerSSE on ISpectLogger {
  void sse({
    required String source,
    required String operation,  // 'connected', 'event', 'disconnected', 'error'
    String? url,
    String? eventType,
    String? eventId,
    Object? error,              // ← для proper error handling
    StackTrace? errorStackTrace,
    Map<String, Object?>? data,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return;  // ← zero overhead when disabled
    trace(
      category: sseCategory,
      source: source, operation: operation,
      target: url, key: eventId,
      error: error,
      errorStackTrace: errorStackTrace,
      success: error == null,  // ← success определяется по наличию error, не по operation string
      meta: {
        if (eventType != null) 'eventType': eventType,
        if (data != null) 'data': data,
      },
      correlationId: correlationId,
      config: config,
    );
  }
}
```

> **NB: SSE auto-correlation pattern.** SSE interceptor (в `ispectify_sse` пакете) должен генерировать
> `connectionId = generateTraceId()` при `connected` и передавать его как `correlationId` во все
> последующие `sse()` вызовы (event, disconnected, error). Аналогично WS (Part 4.2).
> Если пользователь вызывает `sse()` напрямую — ответственность на нём.

### 2.7. gRPC

> **NB:** `grpcTrace()` — для unary и server-streaming calls (Future-based).
> Для client-streaming и bidi-streaming используйте `traceStream()` напрямую
> с `category: grpcCategory`. Streaming протоколы не моделируются как Future.

```dart
extension ISpectLoggerGrpc on ISpectLogger {
  /// For unary and server-streaming gRPC calls.
  /// For client-streaming / bidi-streaming → use `traceStream(category: grpcCategory)` directly.
  Future<T> grpcTrace<T>({
    required String source,
    required String operation,  // 'unary', 'serverStreaming'
    required Future<T> Function() run,
    String? service,
    String? method,
    Map<String, Object?>? grpcMetadata,  // renamed: 'metadata' → 'grpcMetadata' for clarity
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();  // ← zero overhead when disabled
    return traceAsync(
      category: grpcCategory,
      source: source, operation: operation,
      target: service != null && method != null ? '$service/$method' : null,
      meta: {
        if (service != null) 'service': service,
        if (method != null) 'method': method,
        if (grpcMetadata != null) 'grpcMetadata': grpcMetadata,
      },
      run: run, projectResult: projectResult,
      config: config, correlationId: correlationId,
    );
  }
}
```

### 2.8. GraphQL

```dart
extension ISpectLoggerGraphQL on ISpectLogger {
  Future<T> graphqlTrace<T>({
    required String source,
    required String operation,  // 'query', 'mutation', 'subscription'
    required Future<T> Function() run,
    String? operationName,
    String? document,
    Map<String, Object?>? variables,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    if (!options.enabled) return run();  // ← zero overhead when disabled
    return traceAsync(
      category: graphqlCategory,
      source: source, operation: operation,
      target: operationName,
      meta: {
        if (document != null) 'document': document,
        if (variables != null) 'variables': variables,
      },
      run: run, projectResult: projectResult,
      config: config, correlationId: correlationId,
    );
  }
}
```

---

## Part 3: Log Entity — конвертация и экспорт

### 3.1. `ISpectLogData` — расширение для экспорта

> **`toJson()` уже существует** как extension в `history/serialization.dart` (`ISpectLogDataSerialization`).
> Новые методы `toText()` и `toMarkdown()` добавляются в **тот же** extension, чтобы избежать
> конфликта двух extensions с одинаковыми сигнатурами и держать всю сериализацию в одном месте.

````dart
/// Расширяем существующий extension в history/serialization.dart:

extension ISpectLogDataSerialization on ISpectLogData {

  /// JSON — УЖЕ СУЩЕСТВУЕТ (не трогаем):
  // Map<String, dynamic> toJson({bool truncated = false}) => { ... };
  //
  // NB: toJson() НЕ имеет Layer 3 redaction (redactKeys).
  // Это осознанное решение: JSON — diagnostic/raw формат.
  // Для redacted export использовать toText(redactKeys:), toMarkdown(redactKeys:),
  // или LogExporter.toJsonLines(logs, redactKeys:).
  // toJsonLines() включает Layer 3 (redacts exception/error strings).

  /// Plain text — для шаринга, копирования, чтения человеком.
  ///
  /// **Security:** `message` и `exception.toString()` могут содержать sensitive данные
  /// (URL с токенами, SQL с literals, credentials в error messages).
  /// Слой 2 (trace pipeline) редактирует только `meta` через `config.redactKeys`.
  /// `message` формируется из `buildTraceMessage()` (без sensitive данных по-дизайну),
  /// но `exception.toString()` — raw.
  /// Поэтому `toText()`/`toMarkdown()` принимают optional `redactKeys` для
  /// финальной редакции при экспорте (Layer 3).
  String toText({Set<String>? redactKeys}) {
    final buffer = StringBuffer()
      ..writeln('[$formattedTime] [$key] $message');

    if (additionalData != null && additionalData!.isNotEmpty) {
      for (final entry in additionalData!.entries) {
        // Nested maps (e.g. meta) — formatted as indented JSON for readability.
        // Raw Dart toString() для Map выглядит как {a: b, c: d} — нечитаемо.
        final value = entry.value;
        if (value is Map || value is List) {
          try {
            final json = JsonEncoder.withIndent('  ').convert(value);
            buffer.writeln('  ${entry.key}: $json');
          } catch (_) {
            buffer.writeln('  ${entry.key}: $value');
          }
        } else {
          buffer.writeln('  ${entry.key}: $value');
        }
      }
    }

    // Layer 3: redact exception/error — могут содержать URLs, credentials
    if (exception != null) {
      final exStr = '$exception';
      buffer.writeln('  Exception: ${RedactionService.redactExportString(exStr, redactKeys)}');
    }
    if (error != null) {
      final errStr = '$error';
      buffer.writeln('  Error: ${RedactionService.redactExportString(errStr, redactKeys)}');
    }
    if (stackTrace != null) buffer.writeln('  StackTrace:\n$stackTrace');

    return buffer.toString();
  }

  /// Markdown — для вставки в issue tracker, документацию.
  /// `redactKeys` — optional Layer 3 redaction для exception/error strings.
  String toMarkdown({Set<String>? redactKeys}) {
    final buffer = StringBuffer()
      ..writeln('### ${_logLevelIndicator(logLevel)} `$key` — $message')
      ..writeln()
      ..writeln('| Field | Value |')
      ..writeln('|-------|-------|')
      ..writeln('| Time | `$formattedTime` |')
      ..writeln('| Level | `${logLevel?.name ?? 'unknown'}` |');

    if (additionalData != null) {
      final category = additionalData![TraceKeys.category];
      final source = additionalData![TraceKeys.source];
      final operation = additionalData![TraceKeys.operation];
      final duration = additionalData![TraceKeys.durationMs];

      if (category != null) buffer.writeln('| Category | `$category` |');
      if (source != null) buffer.writeln('| Source | `$source` |');
      if (operation != null) buffer.writeln('| Operation | `$operation` |');
      if (duration != null) buffer.writeln('| Duration | `${duration}ms` |');
    }

    if (additionalData != null && additionalData!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('**Details:**')
        ..writeln('```json');
      // Guard: additionalData может содержать non-JSON-serializable types
      // (Color, Uint8List, custom objects). Fallback на toString().
      try {
        buffer.writeln(JsonEncoder.withIndent('  ').convert(additionalData));
      } catch (_) {
        buffer.writeln(additionalData.toString());
      }
      buffer.writeln('```');
    }

    // Layer 3: redact exception/error strings при экспорте
    if (exception != null) {
      final exStr = '$exception';
      buffer.writeln('\n**Exception:** `${RedactionService.redactExportString(exStr, redactKeys)}`');
    }
    if (error != null) {
      final errStr = '$error';
      buffer.writeln('\n**Error:** `${RedactionService.redactExportString(errStr, redactKeys)}`');
    }
    if (stackTrace != null) {
      buffer.writeln('\n**Stack trace:**\n```\n$stackTrace\n```');
    }

    return buffer.toString();
  }

  /// Indicator for markdown headings (not emoji — ASCII markers for readability).
  String _logLevelIndicator(LogLevel? level) => switch (level) {
    LogLevel.error || LogLevel.critical => '[ERROR]',
    LogLevel.warning => '[WARN]',
    LogLevel.info => '[INFO]',
    LogLevel.debug => '[DEBUG]',
    _ => '[-]',
  };

  /// Layer 3 export redaction: ищет known sensitive patterns в строках.
  /// `exception.toString()` и `error.toString()` могут содержать URL с токенами,
  /// SQL literals, или credentials в error messages.
  /// Если `redactKeys` == null — не редактирует (backward compat).
  ///
  // NB: Реализация Layer 3 redaction — в RedactionService.redactExportString() (static).
  // Extension НЕ дублирует логику, а вызывает RedactionService напрямую (см. строки выше).
  // Покрывает: URL credentials, Bearer/Basic tokens, query params, JSON patterns.
  // Реализация regex — в Part 9.1, RedactionService.redactExportString().
}
````

### 3.2. Batch export — список логов

> **NB:** Utility class вместо extension на `List<ISpectLogData>` — extension был бы доступен
> на ЛЮБОМ `List<ISpectLogData>`, что приводит к случайным вызовам на больших наборах.
> Явный вызов `LogExporter.toText(logs)` безопаснее.
> Для bulk export в UI — использовать существующий `LogsJsonService` с chunked processing,
> расширив его поддержкой text/markdown форматов (yield каждые 50 items).

```dart
/// log_exporter.dart — utility для batch export.
///
/// **Safety:** При передаче > maxLogs записей — берёт последние maxLogs.
/// Это предотвращает OOM при случайном вызове на полной истории.
/// Для bulk экспорта (50K+ логов) — использовать LogsJsonService с chunked/stream processing.

abstract final class LogExporter {

  /// Default safety limit. UI может передать явный limit при вызове.
  static const defaultMaxLogs = 5000;

  /// Export as JSON Lines (одна строка = один лог).
  /// `maxLogs` — максимум записей (берёт последние). `null` — без лимита (осторожно!).
  /// **Security:** `redactKeys` необходим — `toJson()` может включать `exception.toString()`
  /// который содержит raw URLs с credentials. Layer 2 не редактирует exception.
  /// Если `redactKeys` == null — без редакции (backward compat).
  static String toJsonLines(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    return capped.map((log) {
      try {
        final json = log.toJson();
        // Layer 3: redact exception/error strings в JSON output
        if (redactKeys != null && redactKeys.isNotEmpty) {
          final ex = json['exception'];
          if (ex is String) json['exception'] = RedactionService.redactExportString(ex, redactKeys);
          final err = json['error'];
          if (err is String) json['error'] = RedactionService.redactExportString(err, redactKeys);
        }
        return jsonEncode(json);
      } catch (_) {
        // Guard: non-serializable types в additionalData (Color, custom objects).
        // Fallback: minimal JSON с message и key.
        return jsonEncode({'message': '${log.message}', 'key': log.key, 'time': log.formattedTime});
      }
    }).join('\n');
  }

  /// Layer 3 redaction — делегация к единому RedactionService.
  /// Нет отдельного файла export_redaction.dart — всё в RedactionService.

  /// Export as plain text.
  static String toText(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln('=== ISpect Log Report ===')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Total entries: ${capped.length}${capped.length < logs.length ? ' (capped from ${logs.length})' : ''}')
      ..writeln('---');
    for (final log in capped) {
      buffer.writeln(log.toText(redactKeys: redactKeys));
    }
    return buffer.toString();
  }

  /// Export as Markdown.
  static String toMarkdown(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln('# ISpect Log Report')
      ..writeln()
      ..writeln('> Generated: ${DateTime.now().toIso8601String()} | Entries: ${capped.length}${capped.length < logs.length ? ' (capped from ${logs.length})' : ''}')
      ..writeln();
    for (final log in capped) {
      buffer
        ..writeln(log.toMarkdown(redactKeys: redactKeys))
        ..writeln('---');
    }
    return buffer.toString();
  }

  /// Export as CSV (для анализа в Excel/Google Sheets).
  /// **Security:** Все колонки проходят через `_csvEscape` (formula injection protection).
  /// **Security:** `message` колонка может содержать PII из non-trace логов
  /// (например, `logger.info('User email: user@mail.com')`). `redactKeys` применяет
  /// Layer 3 redaction через `RedactionService.redactExportString()` к `message`.
  /// **NB:** CSV — overview формат. `exception`, `error`, `stackTrace` и nested `meta`
  /// НЕ включены в колонки (слишком длинные для табличного формата).
  /// Для полных деталей используйте JSON Lines (`toJsonLines()`) или Text (`toText()`).
  static String toCsv(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln('time,level,key,category,source,operation,target,durationMs,success,message');
    for (final log in capped) {
      final ad = log.additionalData;
      // Layer 3: redact message column (non-trace logs may contain PII in message)
      final rawMessage = log.message?.toString() ?? '';
      final safeMessage = redactKeys != null
          ? RedactionService.redactExportString(rawMessage, redactKeys)
          : rawMessage;
      buffer.writeln([
        _csvEscape(log.formattedTime),
        _csvEscape(log.logLevel?.name ?? ''),
        _csvEscape(log.key ?? ''),
        _csvEscape(ad?[TraceKeys.category]?.toString() ?? ''),
        _csvEscape(ad?[TraceKeys.source]?.toString() ?? ''),
        _csvEscape(ad?[TraceKeys.operation]?.toString() ?? ''),
        _csvEscape(ad?[TraceKeys.target]?.toString() ?? ''),
        _csvEscape(ad?[TraceKeys.durationMs]?.toString() ?? ''),
        _csvEscape(ad?[TraceKeys.success]?.toString() ?? ''),
        _csvEscape(safeMessage),
      ].join(','));
    }
    return buffer.toString();
  }

  /// Safety cap: берёт последние maxLogs записей.
  static List<ISpectLogData> _cap(List<ISpectLogData> logs, int? maxLogs) {
    if (maxLogs == null || logs.length <= maxLogs) return logs;
    return logs.sublist(logs.length - maxLogs);
  }

  /// CSV escape + formula injection protection.
  /// Prefixes cells starting with dangerous characters with a tab character.
  /// **Security (XLS Injection):** cells starting with `=`, `+`, `-`, `@` are prefixed
  /// to prevent formula injection in Excel/Google Sheets/LibreOffice.
  static String _csvEscape(String value) {
    var result = value;
    // Formula injection protection: prefix dangerous chars with tab
    if (result.isNotEmpty && '=+-@'.contains(result[0])) {
      result = '\t$result';
    }
    // Handle quotes and commas
    if (result.contains(',') || result.contains('"') || result.contains('\n') || result.contains('\t')) {
      return '"${result.replaceAll('"', '""')}"';
    }
    return result;
  }
}
```

### 3.3. Share/Export в UI

```dart
/// В ispect Flutter UI:

// ── Single log export (detail view / long press) ──
// - Copy as JSON (clipboard)
// - Copy as text (clipboard)
// - Share as markdown

// ── Batch export (log list AppBar) ──
// - Export ALL logs → bottom sheet с выбором формата:
//   • JSON Lines (.jsonl)
//   • Plain Text (.txt)
//   • Markdown (.md)
//   • CSV (.csv) — для анализа в Excel/Google Sheets
// - Export FILTERED logs (текущий фильтр) → тот же sheet
// - Share file (через share_plus или path_provider)

// ── Safety ──
// - LogExporter.maxLogs = 5000 по-умолчанию
// - Для > 5000 логов — показать предупреждение: "Exporting last 5000 of N logs"
// - Bulk export (50K+) — LogsJsonService с chunked processing + progress indicator
// - redactKeys: UI export sheet передаёт `defaultSensitiveKeys` ПО УМОЛЧАНИЮ.
//   Пользователь НЕ должен явно задавать redactKeys — safe by default.
//   Opt-out: toggle "Include sensitive data" в export sheet (default: OFF).
//   Если ON — redactKeys=null (без Layer 3 redaction). WARNING: "Exported logs may contain sensitive data."

// ── UI flow ──
// [Share icon] в AppBar → LogExportSheet (bottom sheet)
// → выбор формата → прогресс (для больших наборов) → share/save

// ── ВАЖНО: TXT backend ──
// В текущем UI кнопка "Share Logs (txt)" уже существует (share_all_logs_sheet.dart),
// но backend (LogsJsonService) НЕ конвертирует — просто пишет JSON с расширением .txt.
// При имплементации: обновить LogsJsonService.shareFilteredLogsAsFile() чтобы при
// fileType='txt' вызывал LogExporter.toText() вместо JSON сериализации.
// Аналогично добавить fileType='md' и fileType='csv'.
```

---

## Part 4: Рефакторинг существующих пакетов

### 4.1. `ispectify_db` → delegates to core trace

```dart
// ISpectDbConfig extends ISpectTraceConfig
// NB: текущий ISpectDbConfig.slowQueryThreshold → super.slowThreshold (unified naming).
// Breaking change для пользователей DB config — задокументировать в migration guide.
class ISpectDbConfig extends ISpectTraceConfig {
  const ISpectDbConfig({
    super.sampleRate,
    super.errorSampleRate,
    super.redact,
    super.redactKeys,
    super.maxValueLength,
    super.attachStackOnError,
    super.slowThreshold,       // was: slowQueryThreshold
    this.maxStatementLength = 2000,
    this.maxArgsLength = 500,
    this.enableTransactionMarkers = false,
  });
  final int maxStatementLength;
  final int maxArgsLength;
  final bool enableTransactionMarkers;
}

// db() → preprocess then delegate to trace()
// dbTrace() → preprocess then delegate to traceAsync()
// dbStart/End → ISpectDbToken wraps ISpectTraceToken + DB fields
// dbTransaction() → delegates to traceTransaction()
// Все существующие публичные API сохраняются.
//
// ── DB correlation ──
// 1. Transaction: zone-based txnId auto-inject'ится во ВСЕ inner queries
//    → "Show Transaction" в UI покажет все queries одной транзакции
// 2. dbStart/dbEnd (manual span): один лог с duration
//    → correlationId из ISpectDbToken пробрасывается в traceEnd()
// 3. Migration/batch: пользователь оборачивает в dbTransaction()
//    → все queries автоматически связаны
// 4. Related queries вне транзакции: explicit correlationId
//    → dbTrace(correlationId: batchId, ...) для группировки
//
// Покрытие: single query, multi-query transaction, manual span, batch — всё корреляцируется.
```

### 4.2. Network interceptors → ДВА лога (request + response)

> **Почему НЕ traceStart/traceEnd:** HTTP нуждается в двух отдельных логах:
>
> 1. Request log (при отправке) — чтобы видеть in-flight запросы
> 2. Response log (при получении) — с результатом и duration
>    `NetworkTransaction` коррелирует их по `requestId`. `traceStart/traceEnd` создаёт только один лог.

**`ispectify_dio`:**

```dart
// NB: DioRequestData, DioResponseData, DioErrorData — data helper classes.
// Они НЕ удаляются. Удаляются только typed LOG subclasses (DioRequestLog, DioResponseLog, DioErrorLog).
// Data classes содержат toJson() с 20+ полей и встроенную redaction.

void onRequest(RequestOptions options, ...) {
  final requestId = generateTraceId();
  options.extra['requestId'] = requestId;
  options.extra['_sw'] = Stopwatch()..start();

  logger.trace(
    category: networkCategory,
    source: 'dio',
    operation: options.method,
    target: redactUrl(options.uri.toString()),
    logKey: ISpectLogType.httpRequest.key,
    correlationId: requestId,  // ← links request↔response logs
    meta: {
      'requestId': requestId,
      // Rich request data via toJson() — preserves 20+ fields for JSON viewer & cURL
      'requestData': DioRequestData(options).toJson(
        redactor: useRedaction ? redactor : null,
      ),
    },
  );
}

void onResponse(Response response, ...) {
  final requestId = response.requestOptions.extra['requestId'] as String?;
  final sw = response.requestOptions.extra['_sw'] as Stopwatch?;
  sw?.stop();
  final requestData = DioRequestData(response.requestOptions);

  logger.trace(
    category: networkCategory,
    source: 'dio',
    operation: response.requestOptions.method,
    target: redactUrl(response.requestOptions.uri.toString()),
    logKey: ISpectLogType.httpResponse.key,
    correlationId: requestId,  // ← same ID as request → correlated
    success: true,
    duration: sw?.elapsed,
    meta: {
      if (requestId != null) 'requestId': requestId,
      'statusCode': response.statusCode,
      // Rich response data — preserves all fields for JSON viewer
      'responseData': DioResponseData(
        response,
        requestData: requestData,
      ).toJson(redactor: useRedaction ? redactor : null),
    },
  );
}

void onError(DioException err, ...) {
  // Similar, with logKey: ISpectLogType.httpError.key
}
```

- `BaseNetworkInterceptor` mixin сохраняется (redaction logic)
- **Два лога** per HTTP call, коррелируемые через `requestId` в meta
- `NetworkTransaction` продолжает работать
- Dio interceptor должен класть `'requestOptions'` в meta (method, uri, headers, queryParameters, body) для cURL backward compat. `data_extensions.dart:curlCommand` читает `traceMeta?['requestOptions']` с fallback на `additionalData?['request-options']` (v4 imported logs)

**`ispectify_http`:** аналогично, `Expando<String>` для requestId + `Expando<Stopwatch>` для timing.

**`traceStart/traceEnd`** используется для протоколов с ОДНИМ логом (gRPC unary, GraphQL query/mutation).
Для gRPC streaming и GraphQL subscription — `traceStream()`.
`traceAsync()`, `traceSync()` — тоже поддерживают `logKey` override (пробрасывают в `trace()`).
`traceEnd()` — НЕ нуждается в `logKey` (используется только для one-log протоколов, `pickLogKey` достаточен).
**NB:** Для one-log протоколов `pickLogKey()` определяет log key по `isError` + `operation`. Если дефолтный
выбор не подходит (например, хочется всегда `grpc-response` для завершённых unary calls) — interceptor
может вызвать `trace()` напрямую с explicit `logKey` override вместо `traceEnd()`.

**Пример: gRPC unary call с traceStart/traceEnd:**

```dart
// В gRPC interceptor:
// ⚠️ ВАЖНО: '$request' и '$response' — raw protobuf.
// Если содержат sensitive данные (API keys, user data) — применяйте domain redaction:
//   meta: {'request': redactProto(request)}
// Layer 2 (trace pipeline) редактирует meta по config.redactKeys,
// но не знает протокольную структуру protobuf.
Future<R> interceptUnary<Q, R>(ClientMethod<Q, R> method, Q request, ...) async {
  final token = logger.traceStart(
    category: grpcCategory,
    source: 'grpc',
    operation: 'unary',
    target: '${method.serviceName}/${method.name}',
    meta: {'request': '$request'},  // ← consider domain redaction!
  );
  // NB: token может быть null если logger disabled. traceEnd(null) — no-op.

  try {
    final response = await call.response;
    logger.traceEnd(token, value: '$response', success: true);
    return response;
  } catch (e, st) {
    logger.traceEnd(token, error: e, errorStackTrace: st);
    rethrow;
  }
}
// Результат: ОДИН лог с duration, success/error, meta.
// pickLogKey() выбирает 'grpc-request' (для unary → secondary) или 'grpc-response'/'grpc-error'.
```

**`ispectify_ws`:**

```dart
// WS interceptor: trace() per event с полной meta структурой
logger.trace(
  category: wsCategory,
  source: 'ws',
  operation: 'send',  // or 'receive'
  target: redactedUrl,
  correlationId: connectionId,  // ← auto-generated при connect
  meta: {
    if (includeData) 'data': safeData,       // ← payload (redacted)
    'metrics': metricsMap,                    // ← _processMetrics() result
    'url': url,
    'path': path,
  },
);
```

`wsCategory.pickLogKey()` returns `ws-sent` for send, `ws-received` for receive, `ws-error` for errors.
**NB: auto-correlationId для WS.** Interceptor генерирует `connectionId = generateTraceId()` при connect и передаёт его как `correlationId` во все последующие `trace()` вызовы (send, receive, error, disconnect). Все события одного WebSocket соединения связаны через один `correlationId`. Пользователь может увидеть все сообщения одного WS через generic correlation banner в detail view.

**WS миграция pattern matching:**

```dart
// БЫЛО (Dart 3.0+ pattern matching на typed subclasses):
bool _shouldLog(ISpectLogData log) => switch (log) {
  WSSentLog() => settings.sentFilter?.call(log) ?? true,
  WSReceivedLog() => settings.receivedFilter?.call(log) ?? true,
  WSErrorLog() => settings.errorFilter?.call(log) ?? true,
  _ => true,
};

// СТАЛО (key-based matching):
bool _shouldLog(ISpectLogData log) => switch (log.key) {
  ISpectLogType.wsSent.key => settings.sentFilter?.call(log) ?? true,
  ISpectLogType.wsReceived.key => settings.receivedFilter?.call(log) ?? true,
  ISpectLogType.wsError.key => settings.errorFilter?.call(log) ?? true,
  _ => true,
};
```

**WS settings filter types:**

```dart
// БЫЛО:
final bool Function(WSSentLog request)? sentFilter;
final bool Function(WSReceivedLog response)? receivedFilter;
final bool Function(WSErrorLog response)? errorFilter;

// СТАЛО (v5.0 breaking change):
final bool Function(ISpectLogData log)? sentFilter;
final bool Function(ISpectLogData log)? receivedFilter;
final bool Function(ISpectLogData log)? errorFilter;
// Пользователь: sentFilter: (log) => log.traceMeta?['url'] != '/healthcheck'
// Тот же API, но тип аргумента — ISpectLogData, не typed subclass.
```

Аналогично обновить `ISpectWSInterceptorSettingsBuilder` (settings_builder.dart:38-40, 46, 56, 66):

```dart
// БЫЛО (settings_builder.dart):
ISpectWSInterceptorSettingsBuilder sentFilter(bool Function(WSSentLog request)? filter) =>
    _set((s) => s.copyWith(sentFilter: filter));
ISpectWSInterceptorSettingsBuilder receivedFilter(bool Function(WSReceivedLog response)? filter) =>
    _set((s) => s.copyWith(receivedFilter: filter));
ISpectWSInterceptorSettingsBuilder errorFilter(bool Function(WSErrorLog response)? filter) =>
    _set((s) => s.copyWith(errorFilter: filter));

// СТАЛО (v5.0 breaking change):
ISpectWSInterceptorSettingsBuilder sentFilter(bool Function(ISpectLogData log)? filter) =>
    _set((s) => s.copyWith(sentFilter: filter));
ISpectWSInterceptorSettingsBuilder receivedFilter(bool Function(ISpectLogData log)? filter) =>
    _set((s) => s.copyWith(receivedFilter: filter));
ISpectWSInterceptorSettingsBuilder errorFilter(bool Function(ISpectLogData log)? filter) =>
    _set((s) => s.copyWith(errorFilter: filter));
```

### 4.3. `ispectify_bloc` → uses trace()

```dart
// ISpectBlocSettings — НЕ наследует BaseStateObserverSettings.
// Каждый state observer (BLoC, Riverpod, MobX) имеет свои lifecycle.
// Общий base class — преждевременная абстракция.
// BLoC settings остаётся standalone, но observer использует trace():

@override
void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
  super.onEvent(bloc, event);
  if (!_shouldLog(toggle: settings.printEvents, candidate: bloc)) return;

  // NB: генерируем eventId для корреляции event → transition → state
  final eventId = generateTraceId();

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'event',
    target: bloc.runtimeType.toString(),
    meta: {
      'blocType': '${bloc.runtimeType}',
      'eventType': '${event.runtimeType}',
      if (settings.printEventFullData) 'event': '$event',
    },
    correlationId: eventId,
    success: true,
  );

  // Сохраняем eventId для передачи в onTransition/onChange
  // NB: Queue вместо single String — для корректной корреляции при concurrent events.
  // Если BLoC получает event A, затем event B ДО завершения onTransition event A,
  // single value перезаписался бы, и transition A получил бы eventId от B.
  // Queue гарантирует FIFO: transition/onChange забирают eventId в порядке добавления.
  (_pendingEventIds[bloc] ??= Queue<String>()).add(eventId);
}

// Хранение pending eventIds для корреляции event → transition → state.
// Queue<String> вместо String — поддержка concurrent events (BLoC с concurrent transformer).
// Expando — автоматическая очистка при GC блока (нет утечек памяти).
final Expando<Queue<String>> _pendingEventIds = Expando<Queue<String>>('bloc_event_ids');

@override
void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
  super.onTransition(bloc, transition);
  if (!_shouldLog(toggle: settings.printTransitions, candidate: bloc)) return;

  final eventId = _pendingEventIds[bloc]?.firstOrNull; // ← FIFO: первый в очереди

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'transition',
    target: bloc.runtimeType.toString(),
    meta: {
      'blocType': '${bloc.runtimeType}',
      'eventType': '${transition.event.runtimeType}',
      'currentState': '${transition.currentState}',
      'nextState': '${transition.nextState}',
      if (settings.printTransitionFullData) 'event': '${transition.event}',
    },
    correlationId: eventId,
    success: true,
  );
}

@override
void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
  super.onChange(bloc, change);
  if (!_shouldLog(toggle: settings.printChanges, candidate: bloc)) return;

  final eventId = _pendingEventIds[bloc]?.firstOrNull;
  // NB: НЕ делаем removeFirst() здесь. Pop происходит в onDone() — единственной
  // финальной точке lifecycle event'а. onChange вызывается ДО onDone, поэтому
  // eventId ещё нужен для корреляции в onDone.
  // Если pop был бы здесь, то onDone потерял бы correlationId.
  // Flow: onEvent → onTransition → onChange → onDone (pop).
  // Error flow: onEvent → onError → onDone (pop). onChange НЕ вызывается.

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'state',
    target: bloc.runtimeType.toString(),
    meta: {
      'blocType': '${bloc.runtimeType}',
      'currentState': '${change.currentState}',
      'nextState': '${change.nextState}',
    },
    correlationId: eventId,
    success: true,
  );
}

// ── onCreate ──────────────────────────────────────
@override
void onCreate(BlocBase<dynamic> bloc) {
  super.onCreate(bloc);
  if (!_shouldLog(toggle: settings.printCreations, candidate: bloc)) return;
  try { onBlocCreate?.call(bloc); } catch (e) { _logCallbackError('onBlocCreate', e); }

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'create',
    target: bloc.runtimeType.toString(),
    meta: {'blocType': '${bloc.runtimeType}'},
    success: true,
  );
}

// ── onClose ───────────────────────────────────────
@override
void onClose(BlocBase<dynamic> bloc) {
  super.onClose(bloc);
  if (!_shouldLog(toggle: settings.printClosings, candidate: bloc)) return;
  try { onBlocClose?.call(bloc); } catch (e) { _logCallbackError('onBlocClose', e); }

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'close',
    target: bloc.runtimeType.toString(),
    meta: {'blocType': '${bloc.runtimeType}'},
    success: true,
  );
}

// ── onDone ────────────────────────────────────────
@override
void onDone(
  Bloc<dynamic, dynamic> bloc,
  Object? event, [
  Object? error,
  StackTrace? stackTrace,
]) {
  super.onDone(bloc, event, error, stackTrace);
  final isEnabled = settings.enabled && !_isFiltered(bloc);
  if (!isEnabled) return;
  final shouldLog = (settings.printCompletions && error == null) ||
      (settings.printErrors && error != null);
  if (!shouldLog) return;

  // onDone — ЕДИНСТВЕННАЯ финальная точка lifecycle event'а.
  // Pop eventId здесь, а не в onChange:
  // - Happy flow: onEvent → onTransition → onChange → onDone (pop)
  // - Error flow: onEvent → onError → onDone (pop). onChange НЕ вызывается.
  // Если бы pop был в onChange, error flow оставлял бы stale eventId в очереди.
  final queue = _pendingEventIds[bloc];
  final eventId = queue?.firstOrNull;
  if (queue != null && queue.isNotEmpty) queue.removeFirst();

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'done',
    target: bloc.runtimeType.toString(),
    error: error,
    errorStackTrace: stackTrace,
    success: error == null,
    meta: {
      'blocType': '${bloc.runtimeType}',
      'eventType': '${event.runtimeType}',
      if (settings.printEventFullData) 'event': '$event',
      'hasError': error != null,
    },
    correlationId: eventId,
  );
}

// ── onError ───────────────────────────────────────
@override
void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
  super.onError(bloc, error, stackTrace);
  if (!_shouldLog(toggle: settings.printErrors, candidate: error)) return;
  try { onBlocError?.call(bloc, error, stackTrace); } catch (e) { _logCallbackError('onBlocError', e); }

  logger.trace(
    category: stateCategory,
    source: 'bloc',
    operation: 'error',
    target: bloc.runtimeType.toString(),
    error: error,
    errorStackTrace: stackTrace,
    success: false,
    meta: {'blocType': '${bloc.runtimeType}'},
  );
}
```

> **NB:** Все user callbacks (`onBlocEvent`, `onBlocTransition`, `onBlocChange`, `onBlocError`, `onBlocCreate`, `onBlocClose`) и все filter callbacks (`eventFilter`, `transitionFilter`, `changeFilter`) СОХРАНЯЮТСЯ. Они часть public API. `_logCallbackError()` и `_safeLogData()` → trace pipeline через safeTrace().

**BLoC event → transition → state → done correlation:**

- `onEvent()` генерирует `eventId = generateTraceId()` и добавляет в `Expando<Queue<String>>`
- `onTransition()` и `onChange()` получают `eventId` из очереди (FIFO) и передают как `correlationId` (без pop)
- `onDone()` получает `eventId` из очереди и делает `removeFirst()` — это **единственная точка pop'а**
- **Почему pop в onDone, а не в onChange:**
  - Happy flow: `onEvent → onTransition → onChange → onDone (pop)` — все 4 лога получают один eventId
  - Error flow: `onEvent → onError → onDone (pop)` — onChange НЕ вызывается
  - Если бы pop был в onChange, то при error flow eventId остался бы в очереди (stale),
    и следующий event получил бы чужой correlationId
- **Concurrent events:** Queue гарантирует корректную корреляцию при `add(eventA); add(eventB);` подряд.
  Без Queue: `onEvent(A)` → `onEvent(B)` перезаписывает eventId → `onTransition(A)` получает eventId от B (баг).
  С Queue: eventId A и B в очереди → onDone(A) забирает первый, onDone(B) — второй (корректно).
- Пользователь может нажать "Show Related" на любом логе и увидеть всю цепочку (event, transition, state, done)
- `Expando` используется вместо `Map<BlocBase, Queue>` — автоматически очищается GC при уничтожении BLoC
- **Cubit:** У Cubit нет events, поэтому `onChange()` без `eventId` — ok, correlationId = null. `onDone` не вызывается для Cubit

> **Почему нет BaseStateObserverSettings:** BLoC имеет event/transition/change/create/close/done. Riverpod имеет add/update/dispose. MobX имеет reaction/spy. Разные lifecycle — общий base class будет или слишком general (бесполезный) или слишком restrictive. Каждый observer остаётся standalone.

### 4.4. Backward compatibility — clean break (v5.0)

**Удалить typed subclasses сразу:**

- `NetworkRequestLog`, `NetworkResponseLog`, `NetworkErrorLog`, `BaseNetworkLog` (`packages/ispectify/lib/src/network/network_logs.dart`)
- `DioRequestLog`, `DioResponseLog`, `DioErrorLog` (`packages/ispectify_dio/lib/src/models/`)
- HTTP-specific: `packages/ispectify_http/lib/src/models/`
- `WSSentLog`, `WSReceivedLog`, `WSErrorLog`, `WSLogFields` (`packages/ispectify_ws/lib/src/models/`)
- `BlocLifecycleLog` (sealed), `BlocEventLog`, `BlocTransitionLog`, `BlocStateLog`, `BlocCreateLog`, `BlocCloseLog`, `BlocDoneLog`, `BlocErrorLog` (`packages/ispectify_bloc/lib/src/models/`)

**Почему clean break:**

- UI (`NetworkTransaction`) уже работает через `additionalData` fallback
- Нет смысла поддерживать два паттерна одновременно
- Один breaking change (v5.0) вместо двух (v5 deprecate + v6 remove)

**Что оставить:**

- `ISpectLogData` — единственный log entity
- `logs.dart` convenience subclasses: `GoodLog`, `AnalyticsLog`, `RouteLog`, `ProviderLog`, `PrintLog` — используются в `ISpectLogger` core методах (`good()`, `analytics()`, `route()`, `provider()`, `print()`). Простые key+title wrappers. `RouteLog` имеет `transitionId` для `ISpectNavigationFlowScreen`.
  - **v5.0:** При создании `RouteLog` в `ISpectLogger.route()` — класть `transitionId` в `additionalData[TraceKeys.correlationId]`. Generic correlation banner покажет "Show Related" для push↔pop одного route.
  - **ISpectNavigatorObserver** — генерирует `routeId = generateTraceId()` при push, хранит в `Map<Route, String>`. При pop/replace/remove — находит routeId и передаёт как `correlationId`. Все events одного route связаны.
  ```dart
  // Пример корреляции навигации:
  final _routeIds = <Route<dynamic>, String>{};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeId = generateTraceId();
    _routeIds[route] = routeId;
    logger.trace(
      category: navigationCategory,
      source: 'navigator', operation: 'push',
      target: route.settings.name,
      correlationId: routeId,
      meta: {'routeName': route.settings.name, 'arguments': '${route.settings.arguments}'},
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeId = _routeIds.remove(route);
    logger.trace(
      category: navigationCategory,
      source: 'navigator', operation: 'pop',
      target: route.settings.name,
      correlationId: routeId,  // ← same ID as push → correlated
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final routeId = oldRoute != null ? _routeIds.remove(oldRoute) : null;
    if (newRoute != null) _routeIds[newRoute] = routeId ?? generateTraceId();
    logger.trace(
      category: navigationCategory,
      source: 'navigator', operation: 'replace',
      target: newRoute?.settings.name,
      correlationId: routeId,
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeId = _routeIds.remove(route);
    logger.trace(
      category: navigationCategory,
      source: 'navigator', operation: 'remove',
      target: route.settings.name,
      correlationId: routeId,
    );
  }
  ```
- `BaseNetworkInterceptor` mixin — redaction logic
- `NetworkTransaction` — корреляция request/response через `meta['requestId']`
  - **NB: ключ меняется:** текущий `kRequestIdKey = 'request-id'` (kebab-case, в удаляемом `network_logs.dart`) → `'requestId'` (camelCase, в meta). `kRequestIdKey` удаляется вместе с `network_logs.dart`.
  - **ВАЖНО: fallback getters нужно обновить** — текущие читают `additionalData['method']`, `['url']`, `['statusCode']` на top-level. После рефакторинга:
    - `method` → `additionalData[TraceKeys.operation]` (top-level 'operation')
    - `url` → `additionalData[TraceKeys.target]` (top-level 'target')
    - `statusCode` → `(additionalData[TraceKeys.meta] as Map?)?['statusCode']` (nested в meta)
    - `requestId` → `(additionalData[TraceKeys.meta] as Map?)?['requestId']` (nested в meta)
  - **Обновлённый NetworkTransaction:**

  ```dart
  int? get statusCode {
    // NB: Defensive `is` checks — consistent с ISpectLogDataX.
    // `as Map?` бросает CastException если value не Map.
    final rawResp = response?.additionalData?[TraceKeys.meta];
    final respMeta = rawResp is Map<String, dynamic> ? rawResp : null;
    final rawErr = error?.additionalData?[TraceKeys.meta];
    final errMeta = rawErr is Map<String, dynamic> ? rawErr : null;
    final respCode = respMeta?['statusCode'];
    final errCode = errMeta?['statusCode'];
    return (respCode is int ? respCode : null) ?? (errCode is int ? errCode : null);
  }

  String? get method {
    final v = request.additionalData?[TraceKeys.operation];
    return v is String ? v : null;
  }

  String? get url {
    final v = request.additionalData?[TraceKeys.target];
    return v is String ? v : null;
  }
  ```

- `data_extensions.dart:ISpectDataX` — обновить:
  - `isHttpLog`: добавить `|| key == ISpectLogType.httpError.key` (баг в текущем коде). Deprecate в пользу `isNetwork` из `ISpectLogDataX`.
  - `curlCommand`: `additionalData?['request-options']` → `traceMeta?['requestData'] ?? additionalData?['request-options']` (backward compat с v4 imported logs)
  - **Разграничение extensions:**
    - `ISpectDataX` = UI/display helpers (httpLogText, curlCommand, copyWith, generateText, stackTraceLogText, typeText)
    - `ISpectLogDataX` = trace field access (traceCategory, traceSource, httpStatusCode, isNetwork, etc.)
    - Не объединять — разные ответственности.
    - **Overlap: `isHttpLog` → `isNetwork`**: `ISpectDataX.isHttpLog` проверяет `key == httpRequest || httpResponse`. `ISpectLogDataX.isNetwork` проверяет `traceCategory == 'network'` (покрывает request + response + error). `isHttpLog` помечается `@Deprecated('Use isNetwork from ISpectLogDataX')`. Код в `ispect` UI мигрирует на `isNetwork`. `isHttpLog` остаётся для backward compat с third-party кодом.
- Convenience extensions для доступа к trace данным:

```dart
extension ISpectLogDataX on ISpectLogData {
  // ── Structured trace field access ──────────────────
  // NB: Defensive `is` checks вместо `as` casts.
  // additionalData может содержать unexpected types (v4 logs, custom data, deserialized JSON).
  // `as Map<String, dynamic>?` бросает CastException если value — не Map.
  // `is` check безопасно возвращает null.
  String? get traceCategory {
    final v = additionalData?[TraceKeys.category];
    return v is String ? v : null;
  }
  String? get traceSource {
    final v = additionalData?[TraceKeys.source];
    return v is String ? v : null;
  }
  String? get traceOperation {
    final v = additionalData?[TraceKeys.operation];
    return v is String ? v : null;
  }
  String? get traceTarget {
    final v = additionalData?[TraceKeys.target];
    return v is String ? v : null;
  }
  Map<String, dynamic>? get traceMeta {
    final v = additionalData?[TraceKeys.meta];
    return v is Map<String, dynamic> ? v : null;
  }
  int? get traceDurationMs {
    final v = additionalData?[TraceKeys.durationMs];
    return v is int ? v : null;
  }
  bool? get traceSuccess {
    final v = additionalData?[TraceKeys.success];
    return v is bool ? v : null;
  }
  bool? get traceSlow {
    final v = additionalData?[TraceKeys.slow];
    return v is bool ? v : null;
  }
  String? get traceTransactionId {
    final v = additionalData?[TraceKeys.transactionId];
    return v is String ? v : null;
  }
  String? get traceCorrelationId {
    final v = additionalData?[TraceKeys.correlationId];
    return v is String ? v : null;
  }

  // ── Category checks (ALL 13 built-in categories) ───
  bool get isNetwork => traceCategory == TraceCategoryIds.network;
  bool get isWs => traceCategory == TraceCategoryIds.ws;
  bool get isSse => traceCategory == TraceCategoryIds.sse;
  bool get isGrpc => traceCategory == TraceCategoryIds.grpc;
  bool get isGraphql => traceCategory == TraceCategoryIds.graphql;
  bool get isDb => traceCategory == TraceCategoryIds.db;
  bool get isState => traceCategory == TraceCategoryIds.state;
  bool get isAuth => traceCategory == TraceCategoryIds.auth;
  bool get isStorage => traceCategory == TraceCategoryIds.storage;
  bool get isPush => traceCategory == TraceCategoryIds.push;
  bool get isAnalytics => traceCategory == TraceCategoryIds.analytics;
  bool get isPayment => traceCategory == TraceCategoryIds.payment;
  bool get isNavigation => traceCategory == TraceCategoryIds.navigation;

  // ── Network convenience (from nested meta) ─────────
  // NB: Все convenience getters используют defensive `is` checks (не `as` casts).
  // traceMeta уже safe (returns null если не Map), но values внутри meta
  // тоже могут быть wrong type (deserialized JSON, v4 logs, custom data).
  // `as int?` бросит TypeError если value — String "200".
  // `is int` безопасно вернёт null.
  // Для числовых типов: `num` check + `.toInt()`/`.toDouble()` покрывает
  // случай когда JSON deserializer вернул int вместо double или наоборот.
  int? get httpStatusCode {
    final v = traceMeta?['statusCode'];
    return v is int ? v : null;
  }
  String? get requestId {
    final v = traceMeta?['requestId'];
    return v is String ? v : null;
  }
  Map<String, dynamic>? get httpHeaders {
    final v = traceMeta?['headers'];
    return v is Map<String, dynamic> ? v : null;
  }

  // ── DB convenience ─────────────────────────────────
  String? get dbStatement {
    final v = traceMeta?['statement'];
    return v is String ? v : null;
  }
  String? get dbStatementDigest {
    final v = traceMeta?['statementDigest'];
    return v is String ? v : null;
  }
  List<Object?>? get dbArgs {
    final v = traceMeta?['args'];
    return v is List<Object?> ? v : null;
  }

  // ── Auth convenience ───────────────────────────────
  String? get authProvider {
    final v = traceMeta?['provider'];
    return v is String ? v : null;
  }

  // ── Storage convenience ────────────────────────────
  String? get storageBucket {
    final v = traceMeta?['bucket'];
    return v is String ? v : null;
  }
  int? get storageSizeBytes {
    final v = traceMeta?['sizeBytes'];
    return v is int ? v : null;
  }

  // ── State convenience ──────────────────────────────
  String? get blocType {
    final v = traceMeta?['blocType'];
    return v is String ? v : null;
  }
  String? get eventType {
    final v = traceMeta?['eventType'];
    return v is String ? v : null;
  }

  // ── Push convenience ───────────────────────────────
  String? get pushTitle {
    final v = traceMeta?['title'];
    return v is String ? v : null;
  }
  String? get pushTopic {
    final v = traceMeta?['topic'];
    return v is String ? v : null;
  }

  // ── Payment convenience ────────────────────────────
  // NB: `num` check для amount — JSON может вернуть int (100) вместо double (100.0).
  // В Dart `100 is double` == false, поэтому `is double` пропустит целые числа.
  double? get paymentAmount {
    final v = traceMeta?['amount'];
    return v is num ? v.toDouble() : null;
  }
  String? get paymentCurrency {
    final v = traceMeta?['currency'];
    return v is String ? v : null;
  }

  // ── Generic ────────────────────────────────────────
  /// Check any custom category: log.hasCategory('my-service')
  bool hasCategory(String categoryId) => traceCategory == categoryId;
}
```

---

## Part 5: `ISpectLogType` расширение

> **BREAKING CHANGE:** Добавление новых enum values ломает exhaustive switch.
> Задокументировать в CHANGELOG. В migration guide рекомендовать `_` default case.
> Добавить `category` field и новые values в ОДНОМ PR.
>
> **Best practice для пользователей:** Всегда используйте `_` wildcard в switch на `ISpectLogType`.
> Для группировки используйте `logType.category` (не switch по каждому value):
>
> ```dart
> // DON'T: fragile, breaks on new values
> switch (logType) { case ISpectLogType.httpRequest: ... }
>
> // DO: stable, handles future values
> if (logType.category == TraceCategoryIds.network) { ... }
> ```

### 5.1. Добавить `category` field

```dart
/// Category ID — всегда через TraceCategoryIds (SSOT).
/// Log key — строковый литерал (SSOT для ключей — enum IS the source of truth).
/// trace_categories.dart ссылается на ISpectLogType.*.key → нет дублирования.

enum ISpectLogType {
  // ── Network ───────────────────────────────────
  httpRequest('http-request', category: TraceCategoryIds.network),
  httpResponse('http-response', category: TraceCategoryIds.network),
  httpError('http-error', category: TraceCategoryIds.network),
  // ── WebSocket (own category, NOT network) ──────
  wsSent('ws-sent', category: TraceCategoryIds.ws),
  wsReceived('ws-received', category: TraceCategoryIds.ws),
  wsError('ws-error', category: TraceCategoryIds.ws),

  // ── State management ──────────────────────────
  blocEvent('bloc-event', category: TraceCategoryIds.state),
  blocTransition('bloc-transition', category: TraceCategoryIds.state),
  blocState('bloc-state', category: TraceCategoryIds.state),
  blocCreate('bloc-create', category: TraceCategoryIds.state),
  blocClose('bloc-close', category: TraceCategoryIds.state),
  blocDone('bloc-done', category: TraceCategoryIds.state),
  blocError('bloc-error', category: TraceCategoryIds.state),
  riverpodAdd('riverpod-add', category: TraceCategoryIds.state),
  riverpodUpdate('riverpod-update', category: TraceCategoryIds.state),
  riverpodDispose('riverpod-dispose', category: TraceCategoryIds.state),
  riverpodFail('riverpod-fail', category: TraceCategoryIds.state),
  stateChange('state-change', category: TraceCategoryIds.state),
  stateError('state-error', category: TraceCategoryIds.state),

  // ── Database ──────────────────────────────────
  dbQuery('db-query', category: TraceCategoryIds.db),
  dbResult('db-result', category: TraceCategoryIds.db),
  dbError('db-error', category: TraceCategoryIds.db),

  // ── Auth ──────────────────────────────────────
  authSuccess('auth-success', category: TraceCategoryIds.auth),
  authError('auth-error', category: TraceCategoryIds.auth),

  // ── Storage ───────────────────────────────────
  storageResult('storage-result', category: TraceCategoryIds.storage),
  storageQuery('storage-query', category: TraceCategoryIds.storage),
  storageError('storage-error', category: TraceCategoryIds.storage),

  // ── Push ──────────────────────────────────────
  pushReceived('push-received', category: TraceCategoryIds.push),
  pushSent('push-sent', category: TraceCategoryIds.push),
  pushError('push-error', category: TraceCategoryIds.push),

  // ── Payment ───────────────────────────────────
  paymentSuccess('payment-success', category: TraceCategoryIds.payment),
  paymentError('payment-error', category: TraceCategoryIds.payment),

  // ── SSE ───────────────────────────────────────
  sseReceived('sse-received', category: TraceCategoryIds.sse),
  sseError('sse-error', category: TraceCategoryIds.sse),

  // ── gRPC ──────────────────────────────────────
  grpcRequest('grpc-request', category: TraceCategoryIds.grpc),
  grpcResponse('grpc-response', category: TraceCategoryIds.grpc),
  grpcError('grpc-error', category: TraceCategoryIds.grpc),

  // ── GraphQL ───────────────────────────────────
  graphqlRequest('graphql-request', category: TraceCategoryIds.graphql),
  graphqlResponse('graphql-response', category: TraceCategoryIds.graphql),
  graphqlError('graphql-error', category: TraceCategoryIds.graphql),

  // ── Navigation ────────────────────────────────
  route('route', category: TraceCategoryIds.navigation),

  // ── Analytics ─────────────────────────────────
  analytics('analytics', category: TraceCategoryIds.analytics),

  // ── General (no specific category — explicit default) ──
  error('error', category: TraceCategoryIds.general),
  critical('critical', category: TraceCategoryIds.general),
  info('info', category: TraceCategoryIds.general),
  debug('debug', category: TraceCategoryIds.general),
  verbose('verbose', category: TraceCategoryIds.general),
  warning('warning', category: TraceCategoryIds.general),
  exception('exception', category: TraceCategoryIds.general),
  good('good', category: TraceCategoryIds.general),
  print('print', category: TraceCategoryIds.general),
  provider('provider', category: TraceCategoryIds.general),
  ;

  const ISpectLogType(this.key, {this.category = TraceCategoryIds.general});
  final String key;
  final String category;
}
```

### 5.1b. Обновление `isErrorType`, `level`, `_defaultPens`

```dart
// isErrorType — добавить ВСЕ error types (включая текущий баг: blocError отсутствует):
bool get isErrorType => switch (this) {
  ISpectLogType.error ||
  ISpectLogType.critical ||
  ISpectLogType.exception ||
  ISpectLogType.httpError ||
  ISpectLogType.blocError ||       // ← FIX: отсутствовал в текущем коде!
  ISpectLogType.riverpodFail ||
  ISpectLogType.dbError ||
  ISpectLogType.wsError ||         // ← NEW
  ISpectLogType.authError ||       // ← NEW
  ISpectLogType.storageError ||    // ← NEW
  ISpectLogType.pushError ||       // ← NEW
  ISpectLogType.paymentError ||    // ← NEW
  ISpectLogType.stateError ||      // ← NEW
  ISpectLogType.sseError ||        // ← NEW
  ISpectLogType.grpcError ||       // ← NEW
  ISpectLogType.graphqlError =>    // ← NEW
    true,
  _ => false,
};

// level — добавить маппинг для новых error types:
LogLevel get level => switch (this) {
  // ... existing mappings ...
  ISpectLogType.wsError ||
  ISpectLogType.authError ||
  ISpectLogType.storageError ||
  ISpectLogType.pushError ||
  ISpectLogType.paymentError ||
  ISpectLogType.stateError ||
  ISpectLogType.sseError ||
  ISpectLogType.grpcError ||
  ISpectLogType.graphqlError => LogLevel.error,
  _ => LogLevel.info,
};

// _defaultPens — добавить для ВСЕХ 21 новых types:
// Error types → red:
ISpectLogType.wsError: AnsiPen()..red(),
ISpectLogType.authError: AnsiPen()..red(),
ISpectLogType.storageError: AnsiPen()..red(),
ISpectLogType.pushError: AnsiPen()..red(),
ISpectLogType.paymentError: AnsiPen()..red(),
ISpectLogType.stateError: AnsiPen()..red(),
ISpectLogType.sseError: AnsiPen()..red(),
ISpectLogType.grpcError: AnsiPen()..red(),
ISpectLogType.graphqlError: AnsiPen()..red(),
// Success/info types:
ISpectLogType.authSuccess: AnsiPen()..green(),
ISpectLogType.storageResult: AnsiPen()..green(),
ISpectLogType.storageQuery: AnsiPen()..blue(),
ISpectLogType.pushReceived: AnsiPen()..xterm(208),
ISpectLogType.pushSent: AnsiPen()..xterm(207),
ISpectLogType.paymentSuccess: AnsiPen()..green(),
ISpectLogType.stateChange: AnsiPen()..xterm(49),
ISpectLogType.sseReceived: AnsiPen()..xterm(35),
ISpectLogType.grpcRequest: AnsiPen()..xterm(207),
ISpectLogType.grpcResponse: AnsiPen()..xterm(35),
ISpectLogType.graphqlRequest: AnsiPen()..xterm(141),
ISpectLogType.graphqlResponse: AnsiPen()..xterm(35),
```

### 5.2. Icons и Colors для новых типов

```dart
// В ISpectConstants.typeIcons:
'ws-sent': Icons.upload_rounded,
'ws-received': Icons.download_rounded,
'ws-error': Icons.error_outline_rounded,
'auth-success': Icons.verified_user_rounded,
'auth-error': Icons.no_accounts_rounded,
'storage-result': Icons.cloud_done_rounded,
'storage-query': Icons.cloud_download_rounded,
'storage-error': Icons.cloud_off_rounded,
'push-received': Icons.notifications_active_rounded,
'push-sent': Icons.send_rounded,
'push-error': Icons.notifications_off_rounded,
'payment-success': Icons.payment_rounded,
'payment-error': Icons.money_off_rounded,
'state-change': Icons.change_circle_rounded,
'state-error': Icons.error_outline_rounded,
'sse-received': Icons.stream_rounded,
'sse-error': Icons.error_outline_rounded,
'grpc-request': Icons.call_made_rounded,
'grpc-response': Icons.call_received_rounded,
'grpc-error': Icons.error_outline_rounded,
'graphql-request': Icons.hub_rounded,
'graphql-response': Icons.hub_rounded,
'graphql-error': Icons.error_outline_rounded,

// lightTypeColors и darkTypeColors — аналогично, consistent palette
```

---

## Part 6: UI без хардкода (`ispect` package)

### 6.1. Динамическая группировка фильтров

**Вместо:**

```dart
// БЫЛО (хардкод):
if (key.startsWith('http-')) group = 'HTTP';
else if (key.startsWith('bloc-')) group = 'Bloc';
```

**Теперь:**

```dart
// СТАЛО (dynamic):
Map<String, List<LogDescription>> _groupLogTypes(BuildContext context, List<LogDescription> descriptions) {
  final theme = context.iSpect.theme;
  final groups = <String, List<LogDescription>>{};

  for (final desc in descriptions) {
    final categoryId = _resolveCategory(desc.key, theme);
    final label = _categoryLabel(context, categoryId);
    (groups[label] ??= []).add(desc);
  }
  return groups;
}

/// Кеш для _resolveCategory — предотвращает повторный lookup для одинаковых ключей.
/// При 10K+ unique log keys четырехуровневый lookup может быть заметен в UI.
///
/// **⚠️ ВАЖНО:** Кеш привязан к identity конкретного ISpectTheme.
/// Если пользователь меняет `logCategories` (через hot reload, settings, или theme switch),
/// кеш автоматически инвалидируется при несовпадении theme identity.
/// Реализация: в State виджета фильтров, НЕ как file-level variable.
///
/// ```dart
/// // В State виджета LogTypeFilterSection:
/// Map<String, String> _categoryCache = {};
/// ISpectTheme? _lastTheme;
/// ```
Map<String, String> _categoryCache = {};
ISpectTheme? _lastTheme;

/// Определяет категорию log key. Четыре источника (приоритет):
/// 1. ISpectTheme.logCategories — кастомные mappings от пользователя
/// 2. ISpectLogType enum — built-in log types
/// 3. Prefix heuristic — backward compat для кастомных keys
/// 4. 'general' — fallback
String _resolveCategory(String key, ISpectTheme theme) {
  // Invalidate cache on theme change (logCategories could differ)
  if (!identical(theme, _lastTheme)) {
    _categoryCache = {};
    _lastTheme = theme;
  }
  final cached = _categoryCache[key];
  if (cached != null) return cached;
  // 1. User-defined: кастомные log keys → category
  final custom = theme.logCategories?[key];
  if (custom != null) return _categoryCache[key] = custom;

  // 2. Built-in: ISpectLogType enum
  final logType = ISpectLogType.fromKey(key);
  if (logType != null) return _categoryCache[key] = logType.category;

  // 3. Prefix heuristic (backward compat for custom keys like 'http-custom')
  // Keys with built-in prefix (e.g. 'db-custom') auto-group into that category.
  // To override: use theme.logCategories (priority 1) for explicit mapping.
  final dash = key.indexOf('-');
  if (dash > 0) {
    final prefix = key.substring(0, dash);
    if (TraceCategoryIds.builtIn.contains(prefix)) return _categoryCache[key] = prefix;
  }

  // 4. Fallback
  return _categoryCache[key] = TraceCategoryIds.general;
}

String _categoryLabel(BuildContext context, String category) {
  // 1. User overrides
  final custom = context.iSpect.theme.categoryLabels?[category];
  if (custom != null) return custom;

  // 2. Built-in l10n
  final l10n = context.ispectL10n;
  return switch (category) {
    TraceCategoryIds.network => l10n.categoryNetwork,
    TraceCategoryIds.ws => l10n.categoryWebSocket,
    TraceCategoryIds.state => l10n.categoryState,
    TraceCategoryIds.db => l10n.categoryDb,
    TraceCategoryIds.auth => l10n.categoryAuth,
    TraceCategoryIds.storage => l10n.categoryStorage,
    TraceCategoryIds.push => l10n.categoryPush,
    TraceCategoryIds.analytics => l10n.categoryAnalytics,
    TraceCategoryIds.payment => l10n.categoryPayment,
    TraceCategoryIds.navigation => l10n.categoryNavigation,
    TraceCategoryIds.sse => l10n.categorySse,
    TraceCategoryIds.grpc => l10n.categoryGrpc,
    TraceCategoryIds.graphql => l10n.categoryGraphql,
    _ => category[0].toUpperCase() + category.substring(1),  // fallback: capitalize
  };
}
```

### 6.2. `ISpectTheme` — расширение

```dart
class ISpectTheme {
  const ISpectTheme({
    // ── Existing fields (не изменяются) ──────────────
    this.pageTitle,
    this.background,                   // existing: ISpectDynamicColor?
    this.foreground,                   // existing: ISpectDynamicColor?
    this.divider,                      // existing: ISpectDynamicColor?
    this.primary,                      // existing: ISpectDynamicColor?
    this.card,                         // existing: ISpectDynamicColor?
    this.logColors = const {},         // existing: log key → Color
    this.logIcons = const {},          // existing: log key → IconData
    this.logDescriptions = const {},   // existing: log key → human-readable description
    this.panelTheme,                   // existing: DraggablePanelTheme?
    // ── NEW fields (v5.0) ────────────────────────────
    this.categoryLabels,               // NEW: category id → display name
    this.logCategories,                // NEW: log key → category id
  });

  final String? pageTitle;
  final ISpectDynamicColor? background;
  final ISpectDynamicColor? foreground;
  final ISpectDynamicColor? divider;
  final ISpectDynamicColor? primary;
  final ISpectDynamicColor? card;
  final Map<String, Color> logColors;
  final Map<String, IconData> logIcons;
  final Map<String, String> logDescriptions;
  final DraggablePanelTheme? panelTheme;

  /// Custom category display labels: {'my-service': 'My Service Name'}
  /// Используется в UI фильтрах для группировки.
  /// Если не задан для built-in категорий — берётся l10n строка.
  /// Если не задан для custom категорий — capitalize(category id).
  final Map<String, String>? categoryLabels;

  /// Custom log key → category mapping: {'my-success': 'my-service', 'my-error': 'my-service'}
  /// Позволяет кастомным log keys группироваться в нужную категорию.
  /// Приоритет: logCategories > ISpectLogType.category > prefix heuristic > 'general'.
  /// НЕ обязательно если log keys следуют конвенции `<category>-<operation>` —
  /// prefix heuristic сгруппирует автом��тически.
  final Map<String, String>? logCategories;

  // NB: ОБЯЗАТЕЛЬНО обновить при имплементации:
  // - copyWith() — добавить categoryLabels и logCategories
  // - operator == / hashCode — включить новые поля
  // - toMap() / fromMap() — сериализация/десериализация новых полей
  //   fromMap() должен gracefully handle missing keys (backward compat с stored JSON)
  // - toString() — включить новые поля
  // Без этого copyWith() будет молча терять categoryLabels/logCategories.
}
```

> **Полная кастомизация для пользователя:**
>
> ```dart
> ISpect(theme: ISpectTheme(
>   logColors: {'my-success': Colors.teal, 'my-error': Colors.red},
>   logIcons: {'my-success': Icons.check, 'my-error': Icons.close},
>   logCategories: {'my-success': 'my-service', 'my-error': 'my-service'},
>   categoryLabels: {'my-service': 'My Custom Service'},
> ))
> ```
>
> Результат: кастомные log types группируются в "My Custom Service" с правильными иконками/цветами.

> **Почему нет `detailRenderers`:** JSON viewer — единственный detail view. Универсальный, не требует поддержки per-category renderers. KISS.

### 6.3. Detail view — JSON viewer + generic correlation

```dart
// LogDetailView — JSON viewer для всех типов.
// Correlation banner — GENERIC, работает для ЛЮБОГО типа с correlationId или transactionId.
// Никакого per-category рендеринга. Простота > красота.
//
// ── Correlation banner (generic) ──
// Если лог имеет correlationId → показать banner: "View related traces" + чип с количеством
// → При нажатии: вызывается `context.iSpect.filterByCorrelationId(id)`
//
// ── Correlation Priority (Heuristic) ──
// Если это сетевой лог (httpRequest/Response/Error) → показываем ПРИОРУТЕТНЫЙ HTTP-баннер
// (с длительностью, статус-кодом и кнопкой "View Request/Response").
// Если это ЛЮБОЙ другой лог (WS, DB, BLoC, Push) → показываем GENERIC баннер корреляции.
// Это позволяет не перегружать интерфейс, но сохранять связь событий.
//
// ── Severity visual hierarchy ──
// Error/critical логи должны визуально выделяться в списке:
// - Красная полоска слева (4px) для error/critical уровней
// - Оранжевая полоска для warning
// - Без полоски для info/debug/verbose
// Quick-filter "Errors only" в AppBar — показать только error/critical/exception логи.
// Это помогает быстро находить проблемы в потоке из тысяч логов.
//
// ── Slow trace indicator ──
// Если additionalData['slow'] == true → показать warning badge/chip на log card:
// "Slow: {durationMs}ms" с оранжевым цветом (только для DB/Network/Storage).
// Помогает быстро находить медленные операции без открытия JSON detail.
//
// ── Implementation: _findCorrelation() обобщение ──
// Текущий: `if (!activeLog.isHttpLog) return null;` (HTTP-only)
// Новый: проверяет correlationId → ищет ВСЕ логи с тем же correlationId в history
//         проверяет transactionId → ищет ВСЕ логи с тем же transactionId
//         HTTP fallback → NetworkTransaction correlation (backward compat)
```

### 6.4. Новые фильтры

```dart
// CategoryFilter и SourceFilter — в ispectify core
class CategoryFilter implements Filter<ISpectLogData> {
  const CategoryFilter(this.categories);
  final Set<String> categories;

  @override
  bool apply(ISpectLogData item) {
    // Defensive `is` check — consistent с ISpectLogDataX pattern.
    final cat = item.additionalData?[TraceKeys.category];
    return cat is String && categories.contains(cat);
  }
}

class SourceFilter implements Filter<ISpectLogData> {
  const SourceFilter(this.sources);
  final Set<String> sources;

  @override
  bool apply(ISpectLogData item) {
    final src = item.additionalData?[TraceKeys.source];
    return src is String && sources.contains(src);
  }
}

/// Фильтр по correlationId — для "Show All Related" в correlation banner.
class CorrelationFilter implements Filter<ISpectLogData> {
  const CorrelationFilter(this.correlationId);
  final String correlationId;

  @override
  bool apply(ISpectLogData item) {
    final cid = item.additionalData?[TraceKeys.correlationId];
    return cid is String && cid == correlationId;
  }
}

/// Фильтр по transactionId — для "Show Transaction" в correlation banner.
class TransactionFilter implements Filter<ISpectLogData> {
  const TransactionFilter(this.transactionId);
  final String transactionId;

  @override
  bool apply(ISpectLogData item) {
    final tid = item.additionalData?[TraceKeys.transactionId];
    return tid is String && tid == transactionId;
  }
}
```

### 6.5. Share / Export в UI

```dart
// Добавить в AppBar или detail view:
// - Copy as JSON (clipboard)
// - Copy as text (clipboard)
// - Export all logs → выбор формата (JSON Lines / Text / Markdown)
// - Share log file
//
// Использует ISpectLogDataSerialization extensions (toText, toMarkdown) и LogExporter из Part 3.
```

---

## Part 7: Testing Utilities

```dart
/// packages/ispectify/lib/src/testing/fake_logger.dart

/// Test double для ISpectLogger. Захватывает все логи для assertions.
///
/// **Memory safety:** `maxTraces` ограничивает размер буфера (default: 10000).
/// При длительных тестовых сессиях FIFO-ротация предотвращает OOM.
///
/// **Performance:** Используется `Queue<T>` (doubly-linked list) вместо `List<T>`.
/// `Queue.removeFirst()` = O(1), `List.removeAt(0)` = O(n).
/// При maxTraces=10000 и 1M логов: Queue ~1M ops vs List ~10^9 ops.
///
/// **NB: Double-memory awareness:** `super.logData(data)` также пишет в base
/// `ISpectLogger.history`. Для тестов это обычно не проблема, но для длительных
/// интеграционных тестов рекомендуется передавать `maxHistoryItems: 0`
/// в `ISpectLoggerOptions` для отключения base history в тестах.
/// NB: `maxHistoryItems` уже реализован в `DefaultISpectLoggerHistory._addEntry()`.
class FakeISpectLogger extends ISpectLogger {
  FakeISpectLogger({
    this.maxTraces = 10000,
  }) : super(options: ISpectLoggerOptions(
    useConsoleLogs: false,
    maxHistoryItems: 0,  // ← отключаем base history (double-memory prevention)
  ));

  final int maxTraces;
  final _queue = Queue<ISpectLogData>();

  /// Read-only snapshot as List (для тестов, where(), firstWhere(), etc.)
  /// NB: Создает копию. Для внутренних queries используем _traces (no-copy).
  List<ISpectLogData> get traces => _queue.toList();

  /// Internal iterable — без копирования, для query-методов.
  Iterable<ISpectLogData> get _traces => _queue;

  @override
  void logData(ISpectLogData data) {
    _queue.add(data);
    while (_queue.length > maxTraces) {
      _queue.removeFirst(); // O(1) vs List.removeAt(0) which is O(n)
    }
    super.logData(data);
  }

  // ── Query by structured trace fields ─────────────────

  // NB: Все query-методы используют _traces (no-copy Iterable) вместо traces (List copy).
  // Это O(n) filter без O(n) copy — значительно быстрее при maxTraces=10000.

  List<ISpectLogData> byCategory(String category) =>
      _traces.where((t) => t.additionalData?[TraceKeys.category] == category).toList();

  List<ISpectLogData> bySource(String source) =>
      _traces.where((t) => t.additionalData?[TraceKeys.source] == source).toList();

  List<ISpectLogData> byOperation(String operation) =>
      _traces.where((t) => t.additionalData?[TraceKeys.operation] == operation).toList();

  List<ISpectLogData> byCorrelationId(String correlationId) =>
      _traces.where((t) => t.additionalData?[TraceKeys.correlationId] == correlationId).toList();

  List<ISpectLogData> byTransactionId(String transactionId) =>
      _traces.where((t) => t.additionalData?[TraceKeys.transactionId] == transactionId).toList();

  List<ISpectLogData> byLogKey(String logKey) =>
      _traces.where((t) => t.key == logKey).toList();

  List<ISpectLogData> errors() =>
      _traces.where((t) => t.additionalData?[TraceKeys.success] == false).toList();

  List<ISpectLogData> slow() =>
      _traces.where((t) => t.additionalData?[TraceKeys.slow] == true).toList();

  /// Query by LogLevel — для non-trace логов (logger.error(), logger.info(), etc.)
  /// которые не имеют TraceKeys.success field.
  List<ISpectLogData> byLogLevel(LogLevel level) =>
      _traces.where((t) => t.logLevel == level).toList();

  // ── Convenience last-accessors ────────────────────────

  ISpectLogData? lastByCategory(String category) {
    final list = byCategory(category);
    return list.isEmpty ? null : list.last;
  }

  ISpectLogData? get lastTrace => traces.isEmpty ? null : traces.last;

  // ── Lifecycle ──────────────────────────────────────────

  void reset() => _queue.clear();
}
```

**Использование:**

```dart
test('Firestore add is traced', () async {
  final logger = FakeISpectLogger();
  final collection = ISpectFirestoreCollection(delegate: fake, logger: logger);

  await collection.add({'name': 'test'});

  final log = logger.lastByCategory('db');
  expect(log, isNotNull);
  expect(log!.additionalData![TraceKeys.operation], 'add');
  expect(log.additionalData![TraceKeys.success], true);
});

test('NetworkTransaction works with pure ISpectLogData (no typed subclasses)', () {
  // Verifies clean break: after removing NetworkRequestLog/NetworkResponseLog,
  // NetworkTransaction resolves statusCode/method/url via new trace additionalData layout.
  // method → TraceKeys.operation (top-level)
  // url → TraceKeys.target (top-level)
  // statusCode → TraceKeys.meta['statusCode'] (nested)
  // requestId → TraceKeys.meta['requestId'] (nested)
  final request = ISpectLogData(
    '[dio] GET → /api/users',
    key: ISpectLogType.httpRequest.key,
    additionalData: {
      TraceKeys.category: TraceCategoryIds.network,
      TraceKeys.source: 'dio',
      TraceKeys.operation: 'GET',
      TraceKeys.target: '/api/users',
      TraceKeys.success: true,
      TraceKeys.meta: {
        'requestId': 'abc123',
        'headers': {'Content-Type': 'application/json'},
      },
    },
  );

  final response = ISpectLogData(
    '[dio] GET → /api/users 50ms',
    key: ISpectLogType.httpResponse.key,
    additionalData: {
      TraceKeys.category: TraceCategoryIds.network,
      TraceKeys.source: 'dio',
      TraceKeys.operation: 'GET',
      TraceKeys.target: '/api/users',
      TraceKeys.durationMs: 50,
      TraceKeys.success: true,
      TraceKeys.meta: {
        'requestId': 'abc123',
        'statusCode': 200,
        'body': {'users': []},
      },
    },
  );

  final txn = NetworkTransaction(requestId: 'abc123', request: request, response: response);
  expect(txn.statusCode, 200);
  expect(txn.method, 'GET');
  expect(txn.url, '/api/users');
  expect(txn.isSuccess, true);
});

test('traceTransaction auto-injects txnId into inner traces', () async {
  final logger = FakeISpectLogger();

  await logger.traceTransaction(
    category: dbCategory,
    source: 'drift',
    logMarkers: true,
    run: () async {
      // Inner trace — should auto-get txnId from zone
      logger.trace(
        category: dbCategory,
        source: 'drift',
        operation: 'insert',
        target: 'users',
        success: true,
      );
    },
  );

  final innerLog = logger.traces.firstWhere(
    (l) => l.additionalData?[TraceKeys.operation] == 'insert',
  );
  // Zone-injected txnId should be present
  expect(innerLog.additionalData?[TraceKeys.transactionId], isNotNull);

  // Markers also get txnId from zone auto-inject (same zone)
  final beginLog = logger.traces.firstWhere(
    (l) => l.additionalData?[TraceKeys.operation] == 'transaction-begin',
  );
  // Both inner trace and markers should have the SAME txnId (from zone)
  expect(
    innerLog.additionalData?[TraceKeys.transactionId],
    beginLog.additionalData?[TraceKeys.transactionId],
  );
});
```

---

## Part 8: Package Structure

```
packages/
  ispectify/                          # Core (pure Dart, zero external deps)
    lib/src/
      trace/
        trace_category.dart           # ISpectTraceCategory
        trace_category_ids.dart       # TraceCategoryIds — SSOT for category ID strings
        trace_categories.dart         # Predefined const categories
        trace_config.dart             # ISpectTraceConfig
        trace_token.dart              # ISpectTraceToken
        trace_keys.dart               # TraceKeys
        trace_extension.dart          # trace(), traceAsync(), traceSync(), traceStart/End, traceStream(), traceTransaction()
        trace_message.dart            # buildTraceMessage() — единый formatter
        trace_helpers.dart            # truncateValue(), safeTrace() — top-level helpers
        trace_stream_transformer.dart # TraceStreamTransformer (pure Dart)
        extensions/
          auth_extension.dart
          storage_extension.dart
          push_extension.dart
          analytics_extension.dart
          payment_extension.dart
          sse_extension.dart
          grpc_extension.dart
          graphql_extension.dart
      redaction/
        redaction_service.dart        # ЕДИНЫЙ RedactionService (SSOT) — redactByKeys, redactTarget, redactExportString, redactPositionalArgs + instance methods
        constants/
          key_defaults.dart           # defaultSensitiveKeys (СУЩЕСТВУЕТ)
      filter/
        category_filter.dart          # CategoryFilter, SourceFilter, CorrelationFilter, TransactionFilter
      models/
        log_type.dart                 # ISpectLogType + category field + new values
        log_data_x.dart              # ISpectLogDataX convenience extension (NEW)
        data.dart                     # ISpectLogData (unchanged)
      history/
        serialization.dart            # + toText(), toMarkdown() (added to existing extension)
      export/
        log_exporter.dart             # LogExporter — batch export utility (static methods)
      testing/
        fake_logger.dart              # FakeISpectLogger for tests

  # ── Barrel export: packages/ispectify/lib/ispectify.dart ──
  # ВАЖНО: добавить ВСЕ новые файлы в barrel, иначе пользователи
  # не смогут импортировать predefined categories, TraceKeys, etc.
  # Добавить в barrel:
  #   export 'src/trace/trace_category.dart';
  #   export 'src/trace/trace_category_ids.dart';
  #   export 'src/trace/trace_categories.dart';      # ← predefined categories!
  #   export 'src/trace/trace_config.dart';
  #   export 'src/trace/trace_token.dart';
  #   export 'src/trace/trace_keys.dart';
  #   export 'src/trace/trace_extension.dart';
  #   export 'src/trace/trace_stream_transformer.dart';
  #   export 'src/trace/extensions/auth_extension.dart';
  #   export 'src/trace/extensions/storage_extension.dart';
  #   export 'src/trace/extensions/push_extension.dart';
  #   export 'src/trace/extensions/analytics_extension.dart';
  #   export 'src/trace/extensions/payment_extension.dart';
  #   export 'src/trace/extensions/sse_extension.dart';
  #   export 'src/trace/extensions/grpc_extension.dart';
  #   export 'src/trace/extensions/graphql_extension.dart';
  #   export 'src/models/log_data_x.dart';          # ← ISpectLogDataX convenience extension!
  #   export 'src/filter/category_filter.dart';
  #   export 'src/export/log_exporter.dart';
  #   export 'src/testing/fake_logger.dart';
  # НЕ экспортировать: trace_message.dart, trace_helpers.dart (internal)

  ispectify_db/                       # DB-specific (delegates to core trace)
  ispectify_dio/                      # Dio → two trace() + logKey
  ispectify_http/                     # http → two trace() + logKey
  ispectify_ws/                       # WS → trace() per event
  ispectify_bloc/                     # BLoC → trace() in observer

  ispect/                             # Flutter UI
    lib/src/
      core/res/
        constants/ispect_constants.dart  # icons/colors (+ new)
        ispect_theme.dart               # + categoryLabels
      features/ispect/presentation/
        widgets/
          settings/log_type_filter_section.dart  # dynamic grouping
          log_detail_view.dart                   # JSON viewer (unchanged)
          export/log_export_sheet.dart           # Share/export UI

  # Future packages:
  ispectify_riverpod/
  ispectify_firebase/
  ispectify_supabase/
  ispectify_appwrite/
  ispectify_pocketbase/
  ispectify_graphql/
  ispectify_grpc/
  ispectify_chopper/
  ispectify_sse/
  ispectify_onesignal/
  ispectify_sentry/
  ispectify_mobx/
  ispectify_redux/
  ispectify_getx/
```

---

## Part 9: Как добавить новый сервис (чеклист)

### Для мейнтейнера ISpect:

1. Category ID в `TraceCategoryIds` (если built-in)
2. `final myCategory = ISpectTraceCategory(id: TraceCategoryIds.my, ...)` в `trace_categories.dart`
3. Extension method в `trace/extensions/my_extension.dart`
4. `ISpectLogType` enum values с `category: TraceCategoryIds.my`
5. Icons/colors в `ISpectConstants` (в `typeIcons`, `lightTypeColors`, `darkTypeColors`)
6. L10n label в `_categoryLabel` (switch case через `TraceCategoryIds.my`) + строки в `.arb` файлы
7. Export barrel в `ispectify.dart`
8. Обновить `ISpectTheme` если добавляются новые поля в тему: `copyWith()`, `==`, `hashCode`, `toMap()`, `fromMap()`
9. Тесты

### Для пользователя библиотеки:

```dart
// 1. Определить категорию:
final myCategory = ISpectTraceCategory(
  id: 'my-service',
  successKey: 'my-success',
  errorKey: 'my-error',
);

// 2. Использовать:
logger.traceAsync(
  category: myCategory,
  source: 'my-sdk',
  operation: 'doWork',
  run: () => sdk.doWork(),
);

// 3. (Optional) Настроить UI:
// NB: logCategories ОБЯЗАТЕЛЬНО если хотите группировку в UI.
// Без logCategories — categoryLabels не будет работать (resolveCategory не найдёт category).
ISpect(theme: ISpectTheme(
  logColors: {'my-success': Colors.teal, 'my-error': Colors.red},
  logIcons: {'my-success': Icons.check, 'my-error': Icons.close},
  logCategories: {'my-success': 'my-service', 'my-error': 'my-service'},  // ← REQUIRED for grouping
  categoryLabels: {'my-service': 'My Service'},
))

// 4. (Optional) Корреляция связанных операций:
final corrId = generateTraceId();
logger.trace(category: myCategory, source: 'my-sdk',
  operation: 'request', correlationId: corrId);
// ... later ...
logger.trace(category: myCategory, source: 'my-sdk',
  operation: 'response', correlationId: corrId);
// UI может группировать по correlationId
```

> **Meta guidelines:**
>
> - `meta` — open `Map<String, Object?>`, без жёсткой schema. JSON viewer покажет всё.
> - Используйте descriptive keys: `'statusCode'`, `'bucket'`, `'provider'` — не `'sc'`, `'b'`, `'p'`.
> - Избегайте конфликтов с TraceKeys: не используйте `'category'`, `'source'`, `'operation'` как meta keys.
> - Для cross-isolate корреляции передавайте `correlationId` явно (zone values не пересекают isolate boundaries).
> - **Для large payloads** (GraphQL response, file content, protobuf) — НЕ кладите полный payload в `meta`.
>   Используйте `projectResult` в traceAsync/traceSync для проекции на нужные поля:
>   `projectResult: (resp) => {'count': resp.items.length, 'firstId': resp.items.first.id}`
>
> **Custom categories — known limitations:**
>
> - `ISpectLogType` — **enum (closed)**. Third-party НЕ может добавить новые enum values.
>   Workaround: использовать raw string keys (`logKey: 'crash-report'`) + `ISpectTheme.logCategories` для UI группировки.
>   Потеря: нет compile-time type safety и IDE autocomplete для custom log keys. Это trade-off за KISS.
> - **Prefix heuristic** в UI группирует `'crash-report'` → prefix `'crash'` → проверяет `TraceCategoryIds.builtIn`.
>   Если `'crash'` НЕ в `builtIn` → fallback на `'general'`. Чтобы custom category группировалась —
>   **ОБЯЗАТЕЛЬНО** задать `ISpectTheme(logCategories: {'crash-report': 'crash'})`.
>   Prefix heuristic работает только для built-in категорий (network, db, ws, etc.).

---

## Part 9.1: Ответственности — кто за что отвечает (Responsibility Map)

### Redaction — единый `RedactionService`, три слоя

**Архитектура:** ВСЕ redaction-функции живут в `RedactionService` (`packages/ispectify/lib/src/redaction/redaction_service.dart`). Domain interceptors и trace pipeline вызывают `RedactionService.*` — единая точка входа. Нет разбросанных helper-функций в разных файлах.

```dart
/// RedactionService — единственный SSOT для всей редакции в ISpect.
/// Все слои (domain, pipeline, export) вызывают методы этого класса.
///
/// Instance methods: domain-specific redaction с состоянием (ignoredKeys/Values).
/// Static methods: stateless utility без side effects.
class RedactionService {
  // ── Instance methods (СУЩЕСТВУЮТ, domain-specific) ───────────────
  // Используются в BaseNetworkInterceptor через composition.
  // Имеют состояние: ignoredKeys, ignoredValues — настраиваемые per-interceptor.

  Object? redact(Object? data, {String? keyName, ...});     // generic Map/List/scalar
  Map<String, Object?> redactHeaders(Map<String, Object?> headers, {...});  // HTTP headers
  String redactUrl(String url);                              // URL query params + userInfo
  String redactUrlsInText(String text);                      // URLs в строках текста

  void ignoreKey(String keyName);    // add to ignore list
  void ignoreValue(String value);    // add to ignore list
  void unignoreKey(String keyName);  // remove from ignore list
  // ... и другие ignore/unignore методы

  // ── Static methods (СУЩЕСТВУЮТ + НОВЫЕ) ──────────────────────────
  // Stateless pure functions. Единая точка входа для pipeline и export.

  /// СУЩЕСТВУЕТ: Рекурсивная редакция Map по ключам (Layer 2 — trace pipeline meta).
  static Object? redactByKeys(Object? data, List<String> keys, {
    int maxDepth = 50,
    String placeholder = redactedMask,
  });

  /// НОВЫЙ: Редакция URL target field (Layer 2 — trace pipeline target).
  /// URL credentials (user:pass@host) + query params с sensitive keys.
  /// Вызывается из trace() pipeline для auto-redaction target.
  static String redactTarget(String target, Set<String> redactKeys) {
    // 1. URL credentials: ://user:pass@host → ://***:***@host
    var result = target.replaceAllMapped(
      RegExp(r'://([^:/@\s]+)(?::([^/@\s]*))?@'),
      (m) => m[2] != null ? '://***:***@' : '://***@',
    );
    // 2. Query params с sensitive keys
    if (result.contains('?')) {
      for (final key in redactKeys) {
        final escaped = RegExp.escape(key);
        result = result.replaceAllMapped(
          RegExp('([?&])($escaped)=([^&\\s]*)', caseSensitive: false),
          (m) => '${m[1]}${m[2]}=***',
        );
      }
    }
    return result;
  }

  /// НОВЫЙ: Regex-based редакция строк (Layer 3 — export).
  /// Покрывает URL credentials, Bearer/Basic tokens, query params, JSON patterns.
  /// Вызывается из toText(), toMarkdown(), LogExporter.toJsonLines(), LogExporter.toCsv().
  ///
  /// **Порядок regex:** от самых специфичных к общим, чтобы не было double-replacement.
  /// Каждый regex идемпотентен (повторный вызов на уже redacted строке безопасен).
  /// `RegExp.escape(key)` используется для ключей с спецсимволами (e.g., 'x-csrf-token').
  ///
  /// **Ограничения:**
  /// - Regex НЕ покрывает custom binary encodings или non-URL formats
  /// - JSON pattern ловит только `"key": "value"`, не `"key": 123` (numbers не redact'ятся)
  /// - Designed for common patterns; domain-specific redaction — на Layer 1 (interceptor)
  static String redactExportString(String value, Set<String>? redactKeys) {
    if (redactKeys == null || redactKeys.isEmpty) return value;
    var result = value;

    // 1. URL credentials: ://user:pass@host → ://***:***@host
    // Covers: https://admin:secret@api.example.com, ftp://user@host
    // Idempotent: ://***:***@ does not re-match (*** doesn't contain @-invalid chars before @)
    result = result.replaceAllMapped(
      RegExp(r'://([^:/@\s]+)(?::([^/@\s]*))?@'),
      (m) => m[2] != null ? '://***:***@' : '://***@',
    );

    // 2. Bearer/Basic tokens: "Authorization: Bearer eyJhbG..." → "Authorization: Bearer ***"
    // Covers: Bearer, Basic, Token prefixes (case-insensitive)
    // Token pattern: alphanumeric + common token chars (+/=._~-)
    // Idempotent: "Bearer ***" re-matches but *** → *** (same result)
    result = result.replaceAllMapped(
      RegExp(r'(Bearer|Basic|Token)\s+[A-Za-z0-9+/=._~-]+', caseSensitive: false),
      (m) => '${m[1]} ***',
    );

    // 3. Query params with sensitive keys: ?token=abc&name=test → ?token=***&name=test
    // RegExp.escape(key) handles keys like 'x-csrf-token' (contains '-')
    // Case-insensitive matching for keys
    // Idempotent: token=*** re-matches but *** → *** (same result)
    for (final key in redactKeys) {
      final escaped = RegExp.escape(key);
      result = result.replaceAllMapped(
        RegExp('([?&])($escaped)=([^&\\s]*)', caseSensitive: false),
        (m) => '${m[1]}${m[2]}=***',
      );
    }

    // 4. JSON patterns in strings: "password": "secret123" → "password": "***"
    // Catches exception.toString() output containing JSON fragments
    // Only redacts string values ("key": "value"), not numbers ("key": 123)
    // RegExp.escape(key) for safe matching
    // Idempotent: "password": "***" re-matches but *** → *** (same result)
    for (final key in redactKeys) {
      final escaped = RegExp.escape(key);
      result = result.replaceAllMapped(
        RegExp('"($escaped)"\\s*:\\s*"[^"]*"', caseSensitive: false),
        (m) => '"${m[1]}": "***"',
      );
    }

    return result;
  }

  /// СУЩЕСТВУЕТ в ISpectDbCore, ПЕРЕНОСИТСЯ сюда:
  /// Редакция позиционных SQL args по ключам колонок.
  static List<Object?> redactPositionalArgs(
    List<Object?> args, List<String> keys, String? statement,
  );
}
```

**Кто что вызывает:**

```
Слой 1: Domain preprocessing (ПЕРЕД вызовом trace)
  ├── Network: BaseNetworkInterceptor
  │   → composition: содержит RedactionService instance
  │   → redactHeaders(), redactUrl(), redact() — instance methods
  │   → domain-specific: знает про HTTP patterns
  ├── DB: ISpectDbCore
  │   → RedactionService.redactByKeys() — static (generic Map)
  │   → RedactionService.redactPositionalArgs() — static (SQL args)
  │   → domain-specific: знает про SQL statements
  └── Others: domain extensions НЕ делают redaction
      → передают raw data, полагаются на слой 2

Слой 2: trace() pipeline (ОБЩИЙ safety net)
  → RedactionService.redactByKeys(meta, config.redactKeys) — recursive Map
  → RedactionService.redactTarget(target, config.redactKeys) — URL query params
  → generic: не знает про HTTP/SQL, ловит common patterns
  → idempotent: если domain уже redacted — повторная обработка безопасна

Слой 3: Export (ПРИ ВЫВОДЕ)
  → RedactionService.redactExportString(exception, redactKeys) — regex для строк
  → toText/toMarkdown/toJsonLines — все делегируют к RedactionService
  → LogExporter — передаёт redactKeys + capped по maxLogs
```

**Миграция из текущего кода:**
- `_redactTarget()` из `trace_helpers.dart` → `RedactionService.redactTarget()` (static)
- `redactExportString()` из `export_redaction.dart` → `RedactionService.redactExportString()` (static)
- `ISpectDbCore.redactPositionalArgs()` → `RedactionService.redactPositionalArgs()` (static)
- `ISpectDbCore.redact()` и `ISpectDbCore.redactIfNeeded()` → уже делегируют к `RedactionService.redactByKeys()`
- `BaseNetworkInterceptor.redactUrl()` → уже делегирует к `RedactionService.redactUrl()` (instance)
- `export_redaction.dart` — **УДАЛИТЬ** (функция переехала в RedactionService)

**Результат:**
- `export_redaction.dart` — **удаляется** (больше не нужен отдельный файл)
- `trace_helpers.dart` — остаётся, но без `_redactTarget` (перенесён)
- `ISpectDbCore` — остаётся, но `redactPositionalArgs` делегирует к `RedactionService`
- `BaseNetworkInterceptor` — без изменений (уже делегирует)

**⚠️ ВАЖНО: `exception.toString()` — единственное место, где raw данные могут утечь через export.**
Слой 1 и 2 не могут защитить exception.toString() — exception создаётся ДО вызова trace().
Поэтому Слой 3 добавляет `RedactionService.redactExportString()` для URL credentials и query params.

**⚠️ In-app JSON viewer:** `TraceKeys.error` (= `'$error'`) хранится на top-level additionalData, НЕ в meta.
Слой 2 редактирует только `meta` по `config.redactKeys` — `TraceKeys.error` НЕ редактируется.
В JSON viewer (in-app) raw error string **виден без редакции**. Это **by-design**: ISpect — debugging tool
для разработчика, in-app просмотр предназначен для dev-режима. Для production-safe вывода —
использовать export с `redactKeys` (Layer 3). Если нужна in-app редакция — передавать
`error: RedactionService.redactExportString('$error', config.redactKeys)` в `trace()`.

**Правило:** ВСЯ редакция проходит через `RedactionService`. Domain interceptors, trace pipeline, export — все вызывают его методы. Один класс, один import, один SSOT. `redactByKeys` идемпотентен.

### Preprocessing — без дублирования

```
dbTrace() {
  // 1. Preprocessing (SQL digest, truncation, arg redaction)
  final dbMeta = _preprocessDb(statement, args, ...);
  // 2. Delegate to traceAsync — НЕ повторяет preprocessing
  return traceAsync(category: dbCategory, meta: dbMeta, ...);
}

db() {
  // 1. Same preprocessing
  final dbMeta = _preprocessDb(statement, args, ...);
  // 2. Delegate to trace — НЕ повторяет preprocessing
  trace(category: dbCategory, meta: dbMeta, ...);
}

// _preprocessDb — единственное место где живёт DB preprocessing
// NB: key строки — plain string literals (не отдельный DbLogKeys class).
// SSOT: ISpectLogDataX convenience getters (dbStatement, dbStatementDigest, dbArgs)
// используют те же строки. Нет смысла в отдельном const class для 3 ключей.
Map<String, Object?> _preprocessDb({...}) {
  return {
    'statement': ISpectDbCore.truncateValue(statement, cfg.maxStatementLength),
    'statementDigest': ISpectDbCore.sqlDigest(statement),
    'args': ISpectDbCore.redactPositionalArgs(args, ...),
    ...
  };
}
```

### Helper функции — где живут

Dart 3.1+ поддерживает private members в extensions. Однако trace helpers используются из НЕСКОЛЬКИХ extension-файлов, поэтому реализуются как shared top-level functions:

```dart
// packages/ispectify/lib/src/trace/trace_message.dart
String buildTraceMessage({...}) { ... }

// packages/ispectify/lib/src/trace/trace_helpers.dart
//
// NB: truncateValue — NEW top-level function в ispectify core.
// НЕ путать с ISpectDbCore.truncateValue из ispectify_db.
// ISpectDbCore.truncateValue делегирует к этой функции (единая реализация).
// Перенос из ispectify_db в ispectify core необходим, т.к. trace_extension.dart
// живёт в ispectify и не может импортировать ispectify_db (circular dependency).
//
// ⚠️ ВАЖНО: truncateValue обрезает только String values.
// Map и List НЕ обрезаются (возвращаются as-is).
// Для large payloads (1MB+ GraphQL response, file content) — использовать
// `projectResult` callback в traceAsync/traceSync чтобы проектировать
// только нужные поля ПЕРЕД записью в лог:
//   traceAsync(
//     ...,
//     projectResult: (response) => {'id': response.id, 'count': response.items.length},
//   );
// Полный response НЕ должен попадать в meta — это приведёт к OOM
// при высокочастотном логировании.
/// ⚠️ ОГРАНИЧЕНИЕ: обрезает ТОЛЬКО String. Map и List возвращаются as-is.
/// Для large payloads (1MB+ response, file content) — использовать `projectResult`
/// в traceAsync/traceSync. Для fire-and-forget `trace(value:)` — ответственность
/// на вызывающем коде не передавать huge Maps/Lists.
/// Unicode: substring по code units (UTF-16). Emoji могут быть разрезаны.
/// Для diagnostic logging это приемлемо.
Object? truncateValue(Object? value, int maxLen) {
  if (value == null) return null;
  if (value is String && value.length > maxLen) {
    return '${value.substring(0, maxLen)}… [truncated]';
  }
  return value;
}

// NB: _redactTarget ПЕРЕНЕСЁН в RedactionService.redactTarget() (static).
// trace_helpers.dart больше не содержит redaction-логику — вся в RedactionService.

// NB: safeTrace — НЕ safeLogData. Существующий extension method SafeLogExtension.safeLogData()
// на ISpectLogger имеет другую сигнатуру (принимает ISpectLogData, не builder).
// safeTrace — новая top-level функция с lazy builder pattern.
//
// ⚠️ ВАЖНО: safeTrace НЕ глотает исключения молча.
// Если builder бросает — safeTrace пытается залогировать warning через logger.
// Если и логирование warning бросает — тогда игнорируется (последний resort).
// Это позволяет отлаживать проблемы в trace pipeline без crash'а приложения.
void safeTrace(ISpectLogger logger, ISpectLogData Function() builder) {
  try {
    final data = builder();
    logger.logData(data);
  } catch (e, st) {
    // Попытка залогировать ошибку trace pipeline через warning.
    // NB: НЕ используем '$e' — exception.toString() может содержать sensitive данные.
    // Логируем только тип ошибки. Stack trace — для debugging pipeline, не содержит PII.
    // Если даже это бросает — молчим (не ломаем приложение).
    try {
      logger.warning('Trace builder threw: ${e.runtimeType}\n$st');
    } catch (_) {}
  }
}
```

Extension вызывает их как обычные функции:

```dart
extension ISpectTrace on ISpectLogger {
  void trace({...}) {
    // NB: ВСЯ логика внутри safeTrace builder.
    // buildTraceMessage, redaction, map construction — всё внутри closure.
    safeTrace(this, () {
      final message = buildTraceMessage(source: source, ...);
      // ... redaction, zone, map construction ...
      return ISpectLogData(message, ...);
    });
  }
}
```

### Безопасность — чеклист

| Аспект                        | Решение                                                                                                                                                                                                                                                                              |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| PII в логах                   | `ISpectTraceConfig.redactKeys` — auto-redaction в trace(). Default: token, password, secret, authorization, cookie, etc.                                                                                                                                                             |
| PII: userId                   | `userId` передаётся в `meta` (не в `key`/message). Добавить `'userId'` в custom `redactKeys` если нужно.                                                                                                                                                                             |
| Sensitive headers             | `BaseNetworkInterceptor.redactHeaders()` — маскирует Authorization, Cookie, Set-Cookie                                                                                                                                                                                               |
| Sensitive URLs                | `BaseNetworkInterceptor.redactUrl()` — маскирует query params с sensitive keys                                                                                                                                                                                                       |
| target field (URLs)           | Auto-redaction в trace() pipeline: `RedactionService.redactTarget()` убирает URL credentials и query params с sensitive keys. Pre-signed URLs (S3, GCS) автоматически очищаются. Domain-layer дополнительно может redact protocol-specific patterns.                                                 |
| SQL injection в логах         | `ISpectDbCore.sqlDigest()` — нормализует SQL, заменяет литералы на `?`                                                                                                                                                                                                               |
| BLoC event toString()         | `settings.printEventFullData` может содержать PII. НЕ включать в production. Документировать risk.                                                                                                                                                                                   |
| Файлы логов на диске          | App-sandboxed directory. Redaction применяется ДО записи. `FileLogHistory` пишет уже redacted данные. **Рекомендация:** писать в non-iCloud-backed directory (iOS: `NSCachesDirectory`).                                                                                             |
| Export/Share: additionalData  | Уже redacted на слое 2 (trace pipeline). Safe.                                                                                                                                                                                                                                       |
| Export/Share: message         | Формируется через `buildTraceMessage()` — НЕ содержит raw данных по-дизайну. Safe.                                                                                                                                                                                                   |
| Export/Share: exception/error | **Layer 3 redaction**: `toText/toMarkdown/toJsonLines(redactKeys:)` — regex-based: URL credentials, Bearer/Basic tokens, query params с sensitive keys, JSON patterns. `LogExporter` пробрасывает `redactKeys`.                                                                      |
| Export/Share: CSV injection   | `_csvEscape()` — formula injection protection (tab prefix для `=`, `+`, `-`, `@`). ВСЕ колонки экранируются.                                                                                                                                                                         |
| Export/Share: OOM protection  | `LogExporter` — `maxLogs` safety cap (default: 5000). Для bulk — `LogsJsonService` с chunked/stream processing.                                                                                                                                                                      |
| Production builds             | `if (!options.enabled) return;` — zero overhead. Никакие данные не обрабатываются когда ISpect отключён.                                                                                                                                                                             |
| Custom redaction keys         | Пользователь расширяет: `ISpectTraceConfig(redactKeys: {...defaultSensitiveKeys, 'ssn', 'credit_card'})`                                                                                                                                                                             |
| defaultSensitiveKeys gaps     | **FIXED:** Added `email`, `otp`, `device_token`, `fcm_token`, `apns_token`, `session_id`, `username`, `phone_number`, `cvv`, `card_number` to `defaultSensitiveKeys` (102 → ~115 entries).                                                                                           |
| Zone txnId isolation          | `_txnZoneKey` — file-private Object (не public Symbol). Нельзя спуфить из внешнего кода. Zone values НЕ пересекают isolate boundaries — документировано.                                                                                                                             |
| Rate limiting                 | **УЖЕ РЕАЛИЗОВАНО:** `ISpectLoggerOptions.maxHistoryItems` (default: 10000) с FIFO-ротацией в `DefaultISpectLoggerHistory._addEntry()`. Предотвращает OOM при высокочастотных WS/SSE/stream событиях. Проверить naming consistency с планом (`maxHistorySize` vs `maxHistoryItems`). |
| ISpectTraceToken lifetime     | `final class`, lightweight (Stopwatch). Если `traceEnd()` не вызван — leak minimal (~bytes). Документировать как best practice: всегда вызывать `traceEnd()`.                                                                                                                        |
| Log rotation                  | `FileLogHistory` — рекомендация: max file size / max age policy. Out of scope для v5.0, но задокументировать как future improvement.                                                                                                                                                 |

---

## Part 10: SOLID / Design Patterns

| Принцип             | Как соблюдается                                                                                                                                                                                                      |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SRP**             | Каждый файл — одна ответственность: Category, Config, Token, Extension, Formatter, CategoryIds                                                                                                                       |
| **OCP**             | Новая категория = const + extension. Core не меняется. UI не меняется. Enum — inherently closed, но extensible через custom categories                                                                               |
| **LSP**             | ISpectDbConfig extends ISpectTraceConfig — подставляется везде                                                                                                                                                       |
| **ISP**             | Domain extensions — отдельные, tree-shakeable. Пользователь видит только нужные                                                                                                                                      |
| **DIP**             | Interceptors зависят от ISpectLogger + ISpectTraceCategory (абстракции). RedactionService.redactByKeys — static utility (pure function, не нарушает DIP)                                                             |
| **SSOT**            | Category IDs → `TraceCategoryIds`. Log keys → `ISpectLogType.*.key`. Config → один `ISpectTraceConfig`. Message format → один `buildTraceMessage()`. Correlation → `correlationId` + `transactionId` (zone)          |
| **Strategy**        | pickLogKey() — стратегия выбора log key                                                                                                                                                                              |
| **Template Method** | traceAsync — template: check enabled → start timer → run → project → log                                                                                                                                             |
| **Decorator**       | BaaS wrappers: implement SDK interface, delegate, trace terminal ops                                                                                                                                                 |
| **Observer**        | BLoC/Riverpod observers                                                                                                                                                                                              |
| **DRY**             | Один trace() pipeline. Domain extensions ~20 строк, не copy-paste. Нет дублирования строковых литералов — category IDs через `TraceCategoryIds`, log keys через `ISpectLogType.*.key`, field names через `TraceKeys` |
| **KISS**            | JSON viewer для всех. Один message format для всех. Минимум абстракций                                                                                                                                               |
| **YAGNI**           | Нет BaseStateObserverSettings. Нет detailRenderers. Нет operationFilters. Нет messageBuilder                                                                                                                         |

---

## Part 11: Полная таблица покрытия

| Сервис                 | Паттерн                        | Категория       | Пакет                |
| ---------------------- | ------------------------------ | --------------- | -------------------- |
| Dio                    | two trace() + logKey           | network         | ispectify_dio        |
| http                   | two trace() + logKey           | network         | ispectify_http       |
| Chopper                | two trace() + logKey           | network         | ispectify_chopper    |
| Retrofit               | через ispectify_dio            | network         | —                    |
| WebSocket              | trace() per event              | ws              | ispectify_ws         |
| SSE                    | trace() per event              | sse             | ispectify_sse        |
| gRPC                   | traceStart/traceEnd            | grpc            | ispectify_grpc       |
| GraphQL                | traceStart/traceEnd            | graphql         | ispectify_graphql    |
| Drift/sqflite          | dbTrace()                      | db              | ispectify_db         |
| Hive/Isar/ObjectBox    | dbTrace()                      | db              | ispectify_db         |
| Realm/GetStorage       | dbTrace()                      | db              | ispectify_db         |
| Postgres/MongoDB/Redis | dbTrace()                      | db              | ispectify_db         |
| Firestore              | dbTrace() decorator            | db              | ispectify_firebase   |
| Firebase Auth          | authTrace() decorator          | auth            | ispectify_firebase   |
| Firebase Storage       | storageTrace() decorator       | storage         | ispectify_firebase   |
| Firebase Messaging     | push()                         | push            | ispectify_firebase   |
| Firebase Analytics     | analyticsEvent()               | analytics       | ispectify_firebase   |
| Firebase Remote Config | traceAsync()                   | analytics       | ispectify_firebase   |
| Firebase Crashlytics   | trace() error forwarding       | general         | ispectify_firebase   |
| Supabase DB            | dbTrace() decorator            | db              | ispectify_supabase   |
| Supabase Auth          | authTrace() decorator          | auth            | ispectify_supabase   |
| Supabase Storage       | storageTrace() decorator       | storage         | ispectify_supabase   |
| Supabase Realtime      | traceStream()                  | sse             | ispectify_supabase   |
| Appwrite               | decorator pattern              | auth/db/storage | ispectify_appwrite   |
| PocketBase             | decorator pattern              | auth/db         | ispectify_pocketbase |
| PowerSync              | dbTrace()                      | db              | ispectify_db         |
| BLoC                   | trace() in observer            | state           | ispectify_bloc       |
| Riverpod               | trace() in observer            | state           | ispectify_riverpod   |
| MobX                   | trace() in spy                 | state           | ispectify_mobx       |
| Redux                  | trace() in middleware          | state           | ispectify_redux      |
| GetX                   | trace() in observer            | state           | ispectify_getx       |
| Navigator              | trace() in observer            | navigation      | ispect               |
| GoRouter               | trace() in observer            | navigation      | example              |
| AutoRoute              | trace() in observer            | navigation      | example              |
| FCM                    | push()                         | push            | ispectify_firebase   |
| OneSignal              | push()                         | push            | ispectify_onesignal  |
| local_notifications    | push()                         | push            | example              |
| Sentry                 | trace() breadcrumb             | general         | ispectify_sentry     |
| Mixpanel               | analyticsEvent()               | analytics       | example              |
| Amplitude              | analyticsEvent()               | analytics       | example              |
| in_app_purchase        | paymentTrace()                 | payment         | example              |
| RevenueCat             | paymentTrace()                 | payment         | example              |
| WorkManager            | traceAsync() + custom category | custom          | example              |
| cached_network_image   | storageTrace()                 | storage         | example              |

---

## Part 12: Implementation Order

1. **maxHistorySize** — **УЖЕ РЕАЛИЗОВАНО** как `ISpectLoggerOptions.maxHistoryItems` (default: 10000) с FIFO-ротацией в `DefaultISpectLoggerHistory._addEntry()`. Проверить naming consistency: если план использует `maxHistorySize` — решить, переименовывать ли на `maxHistorySize` для единообразия с `FakeISpectLogger.maxTraces`, или оставить `maxHistoryItems`. Не нужна реализация с нуля.
   1.5. **defaultSensitiveKeys update** — **⚠️ SECURITY-CRITICAL:** без этого шага `email`, `otp`, `device_token`, `fcm_token` в URL query params **утекают** через `RedactionService.redactUrl()` в Dio/HTTP interceptors. Добавить в `key_defaults.dart`: `'email'`, `'e-mail'`, `'email_address'`, `'otp'`, `'one_time_password'`, `'device_token'`, `'fcm_token'`, `'apns_token'`, `'push_token'`, `'session_id'`, `'session_token'`, `'username'`, `'user_name'`, `'bearer_token'`, `'csrf'`, `'x-csrf-token'`, `'csrf_token'`, `'mfa_code'`, `'totp'`, `'verification_code'`, `'pin_code'`, `'login'`. Добавить regex pattern: `r'(?:e[-_]?mail|otp|device[-_]?token|push[-_]?token|session[-_]?(?:id|token)|csrf[-_]?token|mfa[-_]?code)'`.
2. **ISpectLogType update FIRST** — enum + category field + new enum values + `isErrorType` + `level` + `_defaultPens`.
   **⚠️ ВАЖНО: Шаг 2 ДОЛЖЕН быть выполнен ПЕРЕД шагом 3.** `trace_categories.dart` ссылается на `ISpectLogType.httpResponse.key` и новые enum values (`authSuccess`, `sseReceived`, etc.). Без них компиляция trace_categories невозможна. `TraceCategoryIds` — standalone (без зависимостей), может быть создан параллельно.
3. **Создать директории** + Core trace primitives:
   - Создать: `packages/ispectify/lib/src/trace/`, `packages/ispectify/lib/src/testing/`, `packages/ispectify/lib/src/export/`
   - Обновить `RedactionService` — добавить static методы: `redactTarget()`, `redactExportString()`, `redactPositionalArgs()`
   - `packages/ispectify/lib/src/filter/` — уже существует ✅
   - Core files: trace_category, trace_category_ids, trace_categories, trace_config, trace_token, trace_keys, trace_extension, trace_message, trace_helpers (`truncateValue`, `safeTrace`), trace_stream_transformer
   - `truncateValue()` в `trace_helpers.dart` — core-level. `ISpectDbCore.truncateValue` делегирует к ней
4. **ISpectLogDataX** convenience extension (`models/log_data_x.dart`) — нужен ДО шагов 12-13 (UI зависит от `data.httpStatusCode` и др.)
5. ISpectLogData serialization extensions (toText, toMarkdown с redactKeys в existing ISpectLogDataSerialization) + LogExporter utility class (с maxLogs, CSV)
6. Domain extensions (auth, storage, push, analytics, payment, sse, grpc, graphql)
7. CategoryFilter, SourceFilter, CorrelationFilter, TransactionFilter
8. FakeISpectLogger testing utility (с maxTraces, extended query methods)
9. Рефакторинг ispectify_db → delegates to core trace
10. Рефакторинг ispectify_bloc → uses trace()
11. Рефакторинг ispectify_dio → two trace() + logKey override
12. Рефакторинг ispectify_http → two trace() + logKey override
13. **Рефакторинг ispectify_ws** → trace() + миграция pattern matching на key-based + обновление ISpectWSInterceptorSettings filter types (breaking change: `WSSentLog` → `ISpectLogData`)
14. **UI update** — dynamic filter grouping (с `_categoryCache`), new icons/colors, categoryLabels + logCategories в ISpectTheme (**⚠️ обязательно обновить copyWith(), ==, hashCode, toMap(), fromMap()**), severity visual hierarchy (цветовая полоска слева + quick-filter "Errors only"), **удалить group* l10n strings → добавить category* strings** (**Маппинг: `groupHttp`→`categoryNetwork`, `groupBloc`→`categoryState`, `groupRiverpod`→`categoryState`, `groupWebSocket`→`categoryWebSocket`, `groupDatabase`→`categoryDb`, `groupNavigation`→`categoryNavigation`, `groupGeneral`→fallback capitalize), regenerate localizations, generic correlation banner (correlationId/transactionId), slow trace badge on log cards. **NB: mobile log_card.dart\*\* — добавить badge area (сейчас нет, desktop имеет statusCode badge). Нужно: slow query badge (оранжевый, "Slow: {ms}ms"), error type badge, statusCode badge (паритет с desktop_log_row.dart). Обновить `data_extensions.dart`: исправить `isHttpLog` (добавить `|| key == ISpectLogType.httpError.key`), обновить `curlCommand` (from `additionalData?['request-options']` → собирать cURL из trace fields: `TraceKeys.operation`, `TraceKeys.target`, `traceMeta?['headers']`, `traceMeta?['body']`; также добавить backward compat fallback: `traceMeta?['requestOptions']` для imported v4 logs). При имплементации generic correlation banner — рассмотреть index `Map<String, List<int>>` по correlationId для O(1) lookup (текущий `_findCorrelation()` O(n) при 10K+ логах)
15. UI: export/share sheet (JSON Lines, Text, Markdown, CSV + redactKeys + maxLogs cap)
16. Barrel exports: добавить ВСЕ новые файлы в `ispectify.dart` (см. Part 8), включая `log_data_x.dart`. **Удалить** из barrel: `export 'src/network/request_id_generator.dart'` (заменён на `generateTraceId()`). `network_json_keys.dart` **оставить** — используется в DioRequestData/ResponseData для domain payload.
17. **Тесты**: standard (13.1/13.1b) + security (13.2) + edge cases (13.3) + **конкретная миграция тестов:**
    - `ispectify_bloc/test/ispect_bloc_observer_test.dart:67,83,100,115`: `whereType<BlocEventLog>()` → `.where((e) => e.key == ISpectLogType.blocEvent.key)`
    - `ispectify_dio/test/formdata_fields_test.dart:107`: `is DioRequestLog` → `e.key == ISpectLogType.httpRequest.key`
    - `ispectify_dio/test/logs_test.dart`: конструкторы → `ISpectLogData(message, key: ISpectLogType.httpRequest.key, additionalData: {...})`
    - `ispectify/test/network_logs_test.dart`: конструкторы → `ISpectLogData` с additionalData
    - `ispectify_ws/test/interceptor_test.dart:112-130`: `sentFilter: (WSSentLog _) => false` → `sentFilter: (ISpectLogData _) => false`
18. Migration guide: CHANGELOG.md + Part 16 содержимое

---

## Part 13: Verification

### 13.1. Стандартные проверки

1. `dart test` / `flutter test` — все пакеты
2. `dart analyze --fatal-infos` / `flutter analyze --fatal-infos` — все пакеты
3. Backward compat: все существующие тесты проходят (после миграции на новый API)
4. Export: JSON/txt/md/csv корректно генерируются
5. UI: dynamic grouping работает, новые иконки отображаются
6. `./bash/check_version_sync.sh` + `./bash/check_dependencies.sh`
7. Example: Firebase Auth decorator → authTrace → лог в UI → фильтр по auth → JSON detail
8. Audit ALL exhaustive switch на `ISpectLogType` в кодовой базе — добавить `_` default case перед добавлением новых enum values
9. Обновить example apps — удалить ссылки на typed subclasses (`NetworkRequestLog`, `BlocEventLog`, etc.)
10. Проверить `web_logs_viewer/` — если парсит JSON из ISpect, обновить для нового `additionalData` layout
11. Обновить `version.config` → `5.0.0`, синхронизировать через `./bash/update_versions.sh`
12. Написать CHANGELOG.md с migration guide для breaking changes
13. Добавить l10n строки в `.arb` файлы и регенерировать:
    - Category labels: `categoryNetwork`, `categoryWebSocket`, `categoryDb`, `categoryState`, `categoryAuth`, `categoryStorage`, `categoryPush`, `categoryAnalytics`, `categoryPayment`, `categoryNavigation`, `categorySse`, `categoryGrpc`, `categoryGraphql`
    - Log type descriptions для ВСЕХ новых enum values: `authSuccess`, `authError`, `storageResult`, `storageQuery`, `storageError`, `pushReceived`, `pushSent`, `pushError`, `paymentSuccess`, `paymentError`, `stateChange`, `stateError`, `sseReceived`, `sseError`, `grpcRequest`, `grpcResponse`, `grpcError`, `graphqlRequest`, `graphqlResponse`, `graphqlError`, `wsError`
    - Export UI strings: format picker labels, progress text, confirmation text
14. Обновить barrel exports `packages/ispectify/lib/ispectify.dart` — добавить ВСЕ новые файлы (см. Part 8 barrel comment)
15. Проверить что predefined categories (`networkCategory`, `dbCategory`, etc.) доступны через `import 'package:ispectify/ispectify.dart'`

### 13.1b. Unit tests для core primitives (обязательные)

16. **`ISpectTraceCategory.pickLogKey`:** 3 ветки — error, secondary match, default success
17. **`ISpectTraceConfig.shouldLog`:** null sampleRate → always log; errorSampleRate override; localSample override
18. **`buildTraceMessage`:** все комбинации optional fields (target, key, duration, success/failure)
19. **`CategoryFilter.apply`:** match, no-match, missing category in additionalData
20. **`SourceFilter.apply`:** match, no-match, missing source in additionalData
21. **`FakeISpectLogger.byLogLevel`:** query non-trace logs by LogLevel
22. **`truncateValue`:** string truncation, non-string passthrough, null handling
23. **`_csvEscape`:** formula injection chars (`=`, `+`, `-`, `@`), commas, quotes, newlines
24. **`RedactionService.redactExportString`:** URL credentials, Bearer tokens, query params, JSON patterns, RegExp.escape for special key chars

### 13.2. Security-specific тесты

25. **Export redaction:** `toText(redactKeys: defaultSensitiveKeys)` — exception с URL credentials (`https://user:pass@host`) редактируется → `https://***:***@host`
26. **Export redaction:** `toText(redactKeys: {'token'})` — exception с `?token=abc123` → `?token=***`
27. **Export redaction: Bearer tokens:** exception с `Authorization: Bearer eyJhbG...` → `Authorization: Bearer ***`
28. **Export redaction:** `toMarkdown(redactKeys: ...)` — аналогичные проверки
29. **Export redaction backward compat:** `toText(redactKeys: null)` — НЕ редактирует (null = no Layer 3)
30. **toJsonLines redaction:** `LogExporter.toJsonLines(logs, redactKeys: {'token'})` — exception с `?token=abc` → `?token=***`
31. **CSV formula injection:** source='=CMD(...)' → escaped с tab prefix, обёрнут в кавычки
32. **CSV all columns escaped:** все 10 колонок проходят через `_csvEscape`
32b. **CSV message redaction:** `LogExporter.toCsv(logs, redactKeys: {'token'})` — message содержащий `?token=abc` → `?token=***` в CSV output
32c. **CSV redaction backward compat:** `LogExporter.toCsv(logs)` без redactKeys → message не редактируется
33. **LogExporter cap:** `LogExporter.toText(logsOf100K)` — берёт последние 5000, header показывает `(capped from 100000)`
34. **LogExporter no-cap:** `LogExporter.toText(logs, maxLogs: null)` — без лимита (осторожно!)
35. **FakeISpectLogger maxTraces:** при 15000 логов с maxTraces=10000 — `traces.length == 10000`, первые 5000 удалены (FIFO)
36. **toMarkdown JsonEncoder guard:** additionalData с non-JSON type (e.g. custom object) → fallback на toString(), не throw
37. **userId not in message:** `authTrace(userId: 'user@email.com')` → message string НЕ содержит email
38. **Zone key private:** `Zone.current[#ispectTxnId]` returns null (public Symbol), only `_txnZoneKey` works

### 13.3. Тесты на edge cases (обязательные)

39. **correlationId propagation:** HTTP request + response с одним correlationId → `logger.byCorrelationId('req-123')` возвращает 2 лога
40. **traceStream lifecycle:** subscribe → 3 events → error → unsubscribe → все 5 логов с одним correlationId
41. **traceStream cleanup:** cancel subscription → onCancel вызван, upstream cancelled, controller closed
42. **traceStream error isolation:** onData callback бросает → data stream НЕ ломается, downstream получает данные
43. **traceTransaction nested:** inner transaction переопределяет txnId → после inner, outer txnId восстанавливается
44. **traceAsync with sampling 0.0:** операция ВЫПОЛНЯЕТСЯ, но лог НЕ создаётся
45. **traceAsync projectResult throws:** result возвращается нормально, projected = null, лог создаётся без value
46. **traceTransaction logMarkers: false + error:** rethrow без marker логов
47. **ISpectTraceToken без traceEnd:** token создан, stopwatch running → GC собирает → нет crash (smoke test)
48. **CSV export:** специальные символы (запятые, кавычки, newlines) в message → правильно экранированы
49. **toText nested meta:** `meta: {'headers': {'Authorization': '***'}}` → readable indented output (не raw Dart toString)

### 13.4. Regression тесты для fixes 110-117

50. **safeTrace catches buildTraceMessage errors:** передать объект с broken `toString()` как `target` → нет exception, trace silently dropped
51. **ISpectLogDataX defensive getters:** `additionalData` содержит `{TraceKeys.meta: "not a map", TraceKeys.durationMs: "not int"}` → все getters возвращают `null`, не бросают TypeError
52. **ISpectLogDataX paymentAmount num→double:** `traceMeta?['amount']` = `100` (int) → `paymentAmount` возвращает `100.0` (double), не null
53. **TraceStreamTransformer controller.isClosed:** subscribe → cancel в первом onData → второй event не бросает StateError
54. **Convenience getters на v4 logs:** `ISpectLogData` без TraceKeys в additionalData → все ISpectLogDataX getters возвращают null

### 13.5. Coverage gap тесты

55. **traceSync happy path:** sync operation → result returned → log created с duration, success=true
56. **traceSync error:** sync operation throws → rethrow → log created с error, success=false, duration
57. **traceStart/traceEnd happy path:** traceStart → do work → traceEnd(value: result) → лог с duration, success=true, value
58. **Domain: storageTrace:** upload operation → log с category='storage', operation='upload', bucket в meta
59. **Domain: push():** push received → log с category='push', operation='received', title/topic в meta
60. **Domain: analyticsEvent():** event fired → log с category='analytics', operation=event name, parameters в meta
61. **Domain: sse():** SSE event → log с category='sse', url в target, eventType в meta
62. **Domain: grpcTrace():** unary call → log с category='grpc', service/method в target
63. **Domain: graphqlTrace():** query → log с category='graphql', operationName в target, document в meta
64. **NetworkTransaction defensive getters:** statusCode/method/url на logs с wrong types в additionalData → null, не CastException
65. **CategoryFilter/SourceFilter defensive:** filter.apply() на log с non-String category → returns false, не throws
66. **trace() happy path:** `logger.trace(category: dbCategory, source: 'drift', operation: 'insert', target: 'users', success: true, duration: Duration(ms: 5))` → log created с key='db-result', logLevel=info, additionalData содержит category='db', source='drift', operation='insert', target='users', durationMs=5, success=true
67. **Domain: paymentTrace():** purchase operation → log с category='payment', operation='purchase', productId в key, amount/currency в meta
68. **CorrelationFilter.apply:** match (same correlationId), no-match (different correlationId), missing correlationId → false
69. **TransactionFilter.apply:** match (same transactionId), no-match, missing transactionId → false
70. **CorrelationFilter/TransactionFilter defensive:** filter.apply() на log с non-String correlationId/transactionId → returns false, не throws
71. **isHttpLog includes httpError:** `ISpectLogData(msg, key: 'http-error').isHttpLog` → `true`
72. **curlCommand v5 layout:** log с `traceMeta: {'requestOptions': {'method': 'POST', 'uri': '...', 'headers': {...}}}` → `curlCommand` returns valid cURL string
73. **curlCommand v4 backward compat:** log с `additionalData: {'request-options': {'method': 'GET', ...}}` → `curlCommand` returns valid cURL string (fallback path)
74. **RouteLog correlation:** `RouteLog` с `transitionId: 'abc'` → `additionalData[TraceKeys.correlationId]` == `'abc'`

### 13.6. Тесты из ревью (добавлены по результатам аудита)

75. **BLoC concurrent events correlation:** `bloc.add(eventA); bloc.add(eventB);` → `onTransition(A)` получает eventId от A, `onTransition(B)` получает eventId от B (Queue-based FIFO, не перезапись). Pop происходит в `onDone`, не в `onChange`
75b. **BLoC error flow — eventId pop in onDone:** `bloc.add(eventA)` → onEvent (push idA) → onError → onDone (pop idA). Далее `bloc.add(eventB)` → onEvent (push idB) → onTransition получает idB (НЕ stale idA). Queue корректно очищена
76. **Push auto-correlation:** `push(messageId: 'msg-1')` без explicit `correlationId` → `correlationId == 'msg-1'` (auto-fallback)
77. **Push explicit correlationId override:** `push(messageId: 'msg-1', correlationId: 'custom')` → `correlationId == 'custom'` (не 'msg-1')
78. **traceStart returns null when disabled:** `logger.options.enabled = false` → `traceStart()` returns null → `traceEnd(null)` is no-op
79. **RedactionService.redactTarget URL credentials:** `target: 'https://user:pass@host/path'` → `'https://***:***@host/path'` в additionalData
80. **RedactionService.redactTarget query params:** `target: '/api?token=abc&name=test'` с `redactKeys: {'token'}` → `'/api?token=***&name=test'`
81. **RedactionService.redactTarget non-URL:** `target: 'users'` (table name, no URL) → unchanged (no `?`, no `://`)
82. **safeTrace error logging:** builder throws → warning logged с `${e.runtimeType}` (не `$e`), stack trace включён
83. **safeTrace no PII in warning:** builder throws `Exception('token=abc123')` → warning содержит `Exception` (runtimeType), НЕ содержит `token=abc123`
84. **TraceStreamTransformer broadcast stream:** broadcast stream → cancel one listener → onCancel called, other listeners unaffected
85. **TraceStreamTransformer pause/resume:** pause → resume → continue receiving events correctly
86. **LogExporter.toJsonLines non-serializable meta:** `meta: {'color': customObject}` → `jsonEncode` throws → handle gracefully (skip or toString fallback)
87. **\_resolveCategory caching:** call twice with same key and same theme → second call returns cached result (no enum lookup)
87b. **\_resolveCategory cache invalidation:** call with themeA → call with themeB (different logCategories) → cache invalidated, new lookup performed
88. **FakeISpectLogger maxHistoryItems:** base `ISpectLoggerOptions.maxHistoryItems == 0` → no double-memory
89. **Navigation push↔pop correlation:** didPush генерирует routeId, didPop использует тот же routeId → `logger.byCorrelationId(routeId)` возвращает 2 лога (push + pop)
90. **Navigation replace correlation:** didReplace → старый routeId переносится на новый route, лог replace имеет correlationId старого route
91. **Navigation _routeIds cleanup:** didPop/didRemove → route удалён из `_routeIds` → нет утечки памяти
92. **DB transaction correlation:** dbTransaction → inner dbTrace → inner log имеет transactionId из zone
93. **DB dbStart/dbEnd correlation:** dbStart с correlationId → dbEnd с тем же correlationId → связаны
94. **Cubit onChange без eventId:** Cubit (не BLoC) → `onChange` вызывается без `onEvent` → `_pendingEventIds[bloc]` == null → Queue не создаётся → `correlationId == null` → лог без correlation (ожидаемо)

---

## Part 14: Critical Files

### New (ispectify core)

- `packages/ispectify/lib/src/redaction/redaction_service.dart` — ОБНОВИТЬ: добавить `redactTarget()`, `redactExportString()`, `redactPositionalArgs()` static методы
- `packages/ispectify/lib/src/trace/trace_category.dart`
- `packages/ispectify/lib/src/trace/trace_category_ids.dart` — SSOT for category ID strings
- `packages/ispectify/lib/src/trace/trace_categories.dart`
- `packages/ispectify/lib/src/trace/trace_config.dart`
- `packages/ispectify/lib/src/trace/trace_token.dart`
- `packages/ispectify/lib/src/trace/trace_keys.dart`
- `packages/ispectify/lib/src/trace/trace_extension.dart`
- `packages/ispectify/lib/src/trace/trace_message.dart` — buildTraceMessage() (internal, not exported)
- `packages/ispectify/lib/src/trace/trace_helpers.dart` — truncateValue(), safeTrace() (internal, not exported)
- `packages/ispectify/lib/src/trace/trace_stream_transformer.dart`
- `packages/ispectify/lib/src/trace/extensions/*.dart` (8 files)
- `packages/ispectify/lib/src/models/log_data_x.dart` — ISpectLogDataX convenience extension
- `packages/ispectify/lib/src/export/log_exporter.dart`
- `packages/ispectify/lib/src/filter/category_filter.dart`
- `packages/ispectify/lib/src/testing/fake_logger.dart`

### New (ispect Flutter UI)

- `packages/ispect/lib/src/features/ispect/presentation/widgets/export/log_export_sheet.dart` — share/export UI с выбором формата

### Modified

- `packages/ispectify/lib/src/models/data_extensions.dart` — update `isHttpLog` (add httpError), update `curlCommand` (from 'request-options' to trace fields), move to ISpectLogDataX or keep synchronized
- `packages/ispectify/lib/src/models/log_type.dart` — category field + new values
- `packages/ispectify/lib/src/history/serialization.dart` — + toText(), toMarkdown() in existing ISpectLogDataSerialization extension
- `packages/ispectify/lib/ispectify.dart` — barrel exports
- `packages/ispectify_db/lib/src/db_logger.dart` — delegate to core trace
- `packages/ispectify_db/lib/src/config.dart` — extends ISpectTraceConfig
- `packages/ispectify_db/lib/src/db_token.dart` — wraps ISpectTraceToken
- `packages/ispectify_bloc/lib/src/observer.dart` — use trace()
- `packages/ispectify_dio/lib/src/interceptor.dart` — two trace() + logKey
- `packages/ispectify_http/lib/src/interceptor.dart` — two trace() + logKey
- `packages/ispectify_ws/lib/src/interceptor.dart` — trace()
- `packages/ispectify/lib/src/network/network_transaction.dart` — update fallback getters (method→operation, url→target, statusCode→meta.statusCode)
- `packages/ispect/lib/src/common/services/network_transaction_service.dart` — update requestId extraction from meta, remove type checks
- `packages/ispect/lib/src/features/ispect/presentation/widgets/log_card/log_card.dart` — statusCode extraction: `additionalData?['statusCode']` → `data.httpStatusCode` (convenience getter from ISpectLogDataX)
- `packages/ispect/lib/src/features/ispect/presentation/widgets/log_card/desktop_log_row.dart` — same: `data.httpStatusCode`
- `packages/ispect/lib/src/common/services/logs_json_service.dart` — extend with text/markdown/csv chunked export methods
- `packages/ispect/lib/src/core/res/constants/ispect_constants.dart` — new icons/colors
- `packages/ispect/lib/src/core/res/ispect_theme.dart` — + categoryLabels, + logCategories, + updated copyWith/==/ hashCode/toMap/fromMap
- `packages/ispect/lib/src/features/ispect/presentation/widgets/settings/log_type_filter_section.dart` — dynamic grouping via \_resolveCategory
- `packages/ispectify/lib/src/filter/search_filter.dart` — SearchFilter уже ищет рекурсивно по `additionalData` (включая вложенные Map/List). v5 trace structure (TraceKeys в top-level, meta nested) поддерживается автоматически — SearchFilter НЕ нужно менять. Но проверить при имплементации что поиск по `'statusCode'` находит значение в `meta.statusCode` (nested), а не только top-level.

### Modified (web_logs_viewer)

- `web_logs_viewer/` — Парсит JSON из ISpect. При обновлении `additionalData` layout нужно проверить:
  - Отображение statusCode: `additionalData['statusCode']` → `additionalData['meta']['statusCode']` (nested)
  - Отображение method/url: `additionalData['method']`/`additionalData['url']` → `additionalData['operation']`/`additionalData['target']`
  - Новые trace keys: `category`, `source`, `correlationId`, `transactionId` — добавить в UI если парсит
  - **Backward compat:** viewer должен поддерживать ОБОИХ форматов (v4 + v5) для импортированных файлов

### Deleted (clean break v5.0) — typed LOG subclasses + obsolete utilities

- `packages/ispectify/lib/src/network/network_logs.dart` — BaseNetworkLog, NetworkRequestLog, NetworkResponseLog, NetworkErrorLog, `kRequestIdKey`
- `packages/ispectify/lib/src/network/request_id_generator.dart` — `RequestIdGenerator` (заменяется на `generateTraceId()` из common_utils). Убрать из barrel export `ispectify.dart`
- `packages/ispectify_dio/lib/src/models/` — DioRequestLog, DioResponseLog, DioErrorLog (log subclasses only)
- `packages/ispectify_http/lib/src/models/` — HttpRequestLog, HttpResponseLog, HttpErrorLog (log subclasses only)
- `packages/ispectify_ws/lib/src/models/` — WSSentLog, WSReceivedLog, WSErrorLog, WSLogFields
- `packages/ispectify_bloc/lib/src/models/` — BlocLifecycleLog (sealed), BlocEventLog, BlocTransitionLog, BlocStateLog, BlocCreateLog, BlocCloseLog, BlocDoneLog, BlocErrorLog

### Modified (network utilities — НЕ удаляются, но обновляются)

- `packages/ispectify/lib/src/network/network_json_keys.dart` — `NetworkJsonKeys` остаётся. Используется в `DioRequestData.toJson()`, `DioResponseData.toJson()`, `network_map_redactor.dart` для структурирования network meta. НЕ конфликтует с `TraceKeys` (разные уровни: `TraceKeys` = trace envelope, `NetworkJsonKeys` = domain payload внутри `meta`). Убедиться при имплементации, что ключи не дублируются.

### НЕ удаляется — data helper classes

- `packages/ispectify_dio/lib/src/data/request.dart` — DioRequestData (data class with toJson())
- `packages/ispectify_dio/lib/src/data/response.dart` — DioResponseData (data class with toJson())
- `packages/ispectify_dio/lib/src/data/error.dart` — DioErrorData (data class with toJson())
- `packages/ispectify_http/lib/src/data/` — аналогичные data classes (HttpRequestData, HttpResponseData)
- Эти классы содержат toJson() с redaction и используются interceptor'ами для сериализации в meta

---

## Part 15: Верификация API и UI совместимости

### API compatibility — все вызовы из плана верифицированы:

| API call в плане                                                | Существует | Файл                                  | Статус                                                                                                                        |
| --------------------------------------------------------------- | ---------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `ISpectLogData(message, key:, logLevel:, additionalData:, ...)` | Да         | models/data.dart                      | OK — positional message, unmodifiable additionalData                                                                          |
| `ISpectLogData.toJson()`                                        | Да         | history/serialization.dart            | OK — **extension** `ISpectLogDataSerialization`, не метод на классе. `toText()`/`toMarkdown()` добавляются в тот же extension |
| `cleanMap(additionalData)`                                      | Да         | utils/common_utils.dart               | OK — убирает null и пустые строки                                                                                             |
| `RedactionService.redactByKeys(meta, keys)`                     | Да         | redaction/redaction_service.dart      | OK — static, case-insensitive, recursive                                                                                      |
| `ISpectLogType.fromKey(key)`                                    | Да         | models/log_type.dart                  | OK — static lookup via `_byKey` map, nullable                                                                                 |
| `LogLevel.error`, `LogLevel.info`                               | Да         | models/log_level.dart                 | OK                                                                                                                            |
| `ISpectLogger.logData(data)`                                    | Да         | ispectify.dart                        | OK — public, can override                                                                                                     |
| `options.enabled`                                               | Да         | ispectify.dart + options.dart         | OK — `ISpectLoggerOptions get options` → `options.enabled`                                                                    |
| `samplePass(rate)`                                              | Да         | utils/common_utils.dart               | OK — null/>=1 → true, <=0 → false, else random                                                                                |
| `generateTraceId()`                                             | Да         | utils/common_utils.dart               | OK — 16-char hex from timestamp+random                                                                                        |
| `ISpectDbCore.truncateValue(value, maxLen)`                     | Да         | db_core.dart:66                       | OK — static                                                                                                                   |
| `ISpectDbCore.sqlDigest(statement)`                             | Да         | db_core.dart:46                       | OK — static                                                                                                                   |
| `ISpectDbCore.redactPositionalArgs(args, keys, stmt)`           | Да         | db_core.dart:97                       | OK — static                                                                                                                   |
| `BaseNetworkInterceptor`                                        | Да         | network/base_interceptor.dart         | OK — **mixin** с `redactHeaders()`, `redactBody()`, `redactUrl()`, `NetworkPayloadSanitizer`                                  |
| `defaultSensitiveKeys`                                          | Да         | redaction/constants/key_defaults.dart | OK — `Set<String>` с 102 записями                                                                                             |
| `Filter<T>` interface                                           | Да         | filter/filter.dart                    | OK — abstract class с `bool apply(T item)`                                                                                    |
| `ISpectLogData.formattedTime`                                   | Да         | models/data.dart:68                   | OK — late final getter                                                                                                        |

### UI clean break — все компоненты проверены:

| Компонент              | Зависит от typed subclasses?                                | Fallback через additionalData?                                                                                                                                                  | Статус       |
| ---------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| LogCard                | Нет (кроме `is RouteLog`)                                   | Да                                                                                                                                                                              | SAFE         |
| CollapsedBody          | Нет — получает statusCode через параметр                    | Да, но вызывающий код (LogCard, DesktopLogRow) читает `additionalData?['statusCode']` на top-level → **ОБНОВИТЬ** на `(additionalData?[TraceKeys.meta] as Map?)?['statusCode']` | NEEDS UPDATE |
| NetworkTransactionCard | Нет напрямую — через NetworkTransaction                     | Да — fallback в getters                                                                                                                                                         | SAFE         |
| NetworkTransaction     | Да — type checks, НО с fallback                             | **ОБНОВИТЬ**: fallback keys не совпадают с trace layout (method→operation, url→target, statusCode→meta.statusCode). Getters нужно переписать                                    | NEEDS UPDATE |
| LogDetailView          | Нет — generic correlationId/transactionId + HTTP fallback   | N/A                                                                                                                                                                             | SAFE         |
| ShareLogBottomSheet    | Нет — работает с Map                                        | N/A                                                                                                                                                                             | SAFE         |
| ShareAllLogsSheet      | Нет — `.toJson()`                                           | N/A                                                                                                                                                                             | SAFE         |
| LogExportService       | Нет — delegates                                             | N/A                                                                                                                                                                             | SAFE         |
| LogsJsonService        | Нет — `.toJson()` / `fromJson()`                            | N/A                                                                                                                                                                             | SAFE         |
| LogTypeFilterSection   | Нет — prefix matching                                       | N/A                                                                                                                                                                             | SAFE         |
| CurlCommand            | Нет — extension на ISpectLogData через additionalData + key | `additionalData?['request-options']` → `traceMeta?['requestOptions']` + fallback                                                                                                | NEEDS UPDATE |
| `message` property     | Нет — поле на ISpectLogData                                 | N/A                                                                                                                                                                             | SAFE         |

### Важные детали:

- `curlCommand` — extension getter на `ISpectLogData` (data_extensions.dart:84), работает через `key` + `additionalData`. НЕ зависит от typed subclasses. **НУЖНО ОБНОВИТЬ:** текущий код читает `additionalData?['request-options']`. В v5 Dio interceptor кладёт `DioRequestData.toJson()` в `meta['requestData']`. Обновить: `traceMeta?['requestData'] ?? additionalData?['request-options']` (backward compat с imported v4 logs). `DioRequestData.toJson()` содержит все поля для cURL: method, url, headers, data, queryParameters.
- `message` — поле `String?` на `ISpectLogData` (data.dart:35). Доступно всегда.
- `NetworkTransaction.statusCode/method/url` — **ОБНОВИТЬ fallback getters:** текущие читают `['method']`, `['url']`, `['statusCode']` на top-level. Trace pipeline кладёт `operation`/`target` на top-level, а `statusCode` в nested `meta`. Новые getters: `method` → `TraceKeys.operation`, `url` → `TraceKeys.target`, `statusCode` → `meta['statusCode']`.
- `network_transaction_service.dart` — hybrid checks: `log is NetworkRequestLog || log.key == ISpectLogType.httpRequest.key`. После удаления subclasses — всегда fallback на key. Работает. `requestId` extraction: обновить на `(log.additionalData?[TraceKeys.meta] as Map?)?['requestId']`.

### Безопасность — подтверждено:

- Redaction в 3 слоя без дублирования (domain → trace pipeline → export redaction)
- `redactByKeys` идемпотентен — повторный вызов на уже замаскированных данных безопасен
- Default sensitive keys: token, password, secret, authorization, cookie, session, apikey, etc.
- Production: `if (!options.enabled) return;` — zero data processing
- File logs: app-sandboxed, данные redacted ДО записи
- Export: additionalData — уже redacted (Layer 2). exception/error — Layer 3 regex redaction через `RedactionService.redactExportString()`
- LogExporter — maxLogs safety cap (default: 5000) предотвращает OOM
- FakeISpectLogger — maxTraces FIFO-ротация (default: 10000) предотвращает OOM в тестах
- TraceStreamTransformer — все trace callbacks в try/catch, не ломают data stream

### Нет дублирования — подтверждено:

- Один `trace()` pipeline для всех доменов
- Domain extensions ~20 строк каждый, делегируют в trace()
- `_preprocessDb()` — единственное место DB preprocessing
- `BaseNetworkInterceptor` — единственное место network redaction
- `buildTraceMessage()` — единственный message formatter

---

## Part 16: Migration Guide v4.x → v5.0

### 16.1. Удалённые typed subclasses — замена на ISpectLogDataX

```dart
// ❌ БЫЛО (v4.x) — typed subclass checks:
if (log is NetworkRequestLog) {
  final url = log.url;
  final method = log.method;
  final statusCode = (log as NetworkResponseLog).statusCode;
}
if (log is BlocEventLog) {
  final blocType = log.blocType;
}

// ✅ СТАЛО (v5.0) — convenience extension getters:
// import 'package:ispectify/ispectify.dart'; // includes ISpectLogDataX
if (log.isNetwork) {
  final url = log.traceTarget;        // was: log.url
  final method = log.traceOperation;   // was: log.method
  final statusCode = log.httpStatusCode; // was: log.statusCode
}
if (log.traceCategory == TraceCategoryIds.state) {
  final blocType = log.traceMeta?['blocType'];
}
```

### 16.2. Key/field renames

| v4.x                                | v5.0                              | Где                              |
| ----------------------------------- | --------------------------------- | -------------------------------- |
| `kRequestIdKey = 'request-id'`      | `'requestId'`                     | `meta['requestId']` (nested)     |
| `additionalData['method']`          | `additionalData['operation']`     | top-level, `TraceKeys.operation` |
| `additionalData['url']`             | `additionalData['target']`        | top-level, `TraceKeys.target`    |
| `additionalData['statusCode']`      | `meta['statusCode']`              | nested в `TraceKeys.meta`        |
| `ISpectDbConfig.slowQueryThreshold` | `ISpectTraceConfig.slowThreshold` | config parameter                 |

### 16.3. Interceptor API — без изменений для пользователей

Пользователи НЕ меняют свой код для Dio/HTTP/WS/BLoC interceptors:

```dart
// Осталось как было:
dio.interceptors.add(ISpectDioInterceptor(logger: logger));
// Внутренне interceptor теперь вызывает trace() вместо создания typed subclasses.
```

### 16.4. ISpectLogType exhaustive switch

```dart
// ❌ БЫЛО — ломается при новых enum values:
switch (logType) {
  case ISpectLogType.httpRequest: ...
  case ISpectLogType.httpResponse: ...
  // compile error: missing 19 new cases!
}

// ✅ СТАЛО — стабильно:
if (logType.category == TraceCategoryIds.network) { ... }
// или с wildcard:
switch (logType) {
  case ISpectLogType.httpRequest: ...
  case ISpectLogType.httpResponse: ...
  _: ... // handles all future values
}
```

### 16.5. Export API — новые параметры

```dart
// v4.x:
log.toJson();
log.toJson(truncated: true);

// v5.0 (backward compat — existing calls work):
log.toJson();                                    // unchanged
log.toJson(truncated: true);                     // unchanged
log.toText();                                    // NEW
log.toText(redactKeys: defaultSensitiveKeys);    // NEW — Layer 3 redaction
log.toMarkdown();                                // NEW
LogExporter.toText(logs);                        // NEW — batch export
LogExporter.toCsv(logs);                         // NEW — CSV export
```

### 16.6. ISpectTheme — новые поля (optional)

```dart
// v4.x:
ISpect(theme: ISpectTheme(logColors: {...}, logIcons: {...}))

// v5.0 (backward compat — existing calls work):
ISpect(theme: ISpectTheme(
  logColors: {...},
  logIcons: {...},
  // NEW (optional):
  categoryLabels: {'my-service': 'My Service'},
  logCategories: {'my-success': 'my-service', 'my-error': 'my-service'},
))
```

### 16.7. Дополнительные breaking changes (не забыть!)

| Что изменилось                                 | Ошибка компиляции                                                                                                     | Миграция                                                                                                                                                                                                                                                                                                                                 |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RedactionService.redactByKeys` signature      | `List<String>` → `Iterable<String>`                                                                                   | Если вызывали напрямую — Set и List оба совместимы с `Iterable`, `.toList()` больше не нужен                                                                                                                                                                                                                                             |
| `kRequestIdKey` удалён                         | `Undefined name 'kRequestIdKey'`                                                                                      | Заменить на строковый литерал `'requestId'` или `ISpectLogDataX.requestId`                                                                                                                                                                                                                                                               |
| `ISpectDbConfig.slowQueryThreshold`            | `The named parameter 'slowQueryThreshold' isn't defined`                                                              | Заменить на `slowThreshold`: `ISpectDbConfig(slowThreshold: Duration(seconds: 1))`                                                                                                                                                                                                                                                       |
| BLoC typed subclasses в тестах                 | `Undefined class 'BlocEventLog'`                                                                                      | Заменить `is BlocEventLog` → `log.key == ISpectLogType.blocEvent.key`. Аналогично для `BlocTransitionLog`, `BlocStateLog`, `BlocCreateLog`, `BlocCloseLog`, `BlocDoneLog`, `BlocErrorLog`                                                                                                                                                |
| WS typed subclasses                            | `Undefined class 'WSSentLog'`                                                                                         | Заменить на `log.key == ISpectLogType.wsSent.key`                                                                                                                                                                                                                                                                                        |
| `ISpectWSInterceptorSettings` filter callbacks | `The argument type 'bool Function(WSSentLog)' can't be assigned to the parameter type 'bool Function(ISpectLogData)'` | Заменить `bool Function(WSSentLog)?` → `bool Function(ISpectLogData)?`. Доступ к полям: `log.additionalData?[TraceKeys.meta]` или convenience getters из `ISpectLogDataX` (e.g., `log.traceOperation`). Аналогично для `receivedFilter`, `errorFilter`.                                                                                  |
| `RequestIdGenerator` format changed            | Нет ошибки компиляции                                                                                                 | Формат requestId меняется: v4 `'net-{sessionHex}-{counter}'` → v5 `generateTraceId()` (16-char hex). `NetworkTransactionService` коррелирует по equality — формат не важен. Импортированные v4 логи с `net-*` requestId корректно группируются. Key: v4 `'request-id'` (kebab, top-level) → v5 `'requestId'` (camelCase, nested в meta). |
| `l10n.group*` → `l10n.category*`               | `The getter 'groupHttp' isn't defined`                                                                                | Маппинг: `groupHttp`→`categoryNetwork`, `groupBloc`→`categoryState`, `groupRiverpod`→`categoryState`, `groupWebSocket`→`categoryWebSocket`, `groupDatabase`→`categoryDb`, `groupNavigation`→`categoryNavigation`, `groupGeneral`→removed (fallback: capitalize category id)                                                              |
| `data_extensions.dart` `curlCommand`           | Runtime: cURL returns null                                                                                            | `additionalData?['request-options']` → `traceMeta?['requestOptions']` (v5 Dio interceptor кладёт в meta). Backward compat для imported v4 logs: fallback to `additionalData?['request-options']`                                                                                                                                         |
| `authTrace(userId:)` теперь в meta             | `userId` больше не в `key` field / message string                                                                     | Если искали userId в `log.key` → теперь в `log.traceMeta?['userId']`                                                                                                                                                                                                                                                                     |

### 16.8. Минимальная миграция (happy path)

Если пользователь НЕ использовал typed subclasses напрямую:

1. Обновить `pubspec.yaml` → `ispect: ^5.0.0`, `ispectify: ^5.0.0`, etc.
2. Добавить `_` default case в switch по `ISpectLogType` (если есть)
3. `RedactionService.redactByKeys` теперь принимает `Iterable<String>` — Set и List совместимы напрямую, `.toList()` не нужен
4. Готово.

Если пользователь ИСПОЛЬЗОВАЛ typed subclasses:

1. Заменить `is NetworkRequestLog` → `log.isNetwork && log.key == ISpectLogType.httpRequest.key`
2. Заменить `log.url` → `log.traceTarget`
3. Заменить `log.method` → `log.traceOperation`
4. Заменить `log.statusCode` → `log.httpStatusCode`
5. Для BLoC: `is BlocEventLog` → `log.key == ISpectLogType.blocEvent.key`
6. Для WS: `is WSSentLog` → `log.key == ISpectLogType.wsSent.key`
7. Обновить **тестовый код** — типизированные subclasses удалены и оттуда тоже

---

## Part 17: Implementation Checklist

Единый чеклист для имплементации. Каждый шаг имеет критерий "done".
Порядок обязателен — каждый следующий шаг зависит от предыдущих.

### Шаг 1: defaultSensitiveKeys update
- [ ] Добавить ~22 новых ключа в `key_defaults.dart` (email, otp, csrf, mfa_code, totp, device_token, fcm_token, apns_token, push_token, session_id, session_token, username, user_name, bearer_token, x-csrf-token, csrf_token, verification_code, pin_code, login, e-mail, email_address, one_time_password)
- **Done when:** `dart analyze packages/ispectify --fatal-infos` чист. Тесты `dart test packages/ispectify` проходят.

### Шаг 2: ISpectLogType update (Part 5)
- [ ] Добавить `category` field в `ISpectLogType` enum
- [ ] Добавить 21 новый enum value (wsError, authSuccess, authError, storageResult, storageQuery, storageError, pushReceived, pushSent, pushError, paymentSuccess, paymentError, stateChange, stateError, sseReceived, sseError, grpcRequest, grpcResponse, grpcError, graphqlRequest, graphqlResponse, graphqlError)
- [ ] Обновить `isErrorType` (добавить blocError + 9 новых error types)
- [ ] Обновить `level` (новые error types → LogLevel.error)
- [ ] Обновить `_defaultPens` (21 новых mappings)
- [ ] Audit ALL exhaustive switch на `ISpectLogType` — добавить `_` default case
- **Done when:** `dart analyze packages/ispectify --fatal-infos` чист. `ISpectLogType.fromKey('auth-success')?.category == 'auth'`.

### Шаг 3: Core trace primitives (Part 1)
- [ ] Создать `packages/ispectify/lib/src/trace/` директорию
- [ ] Создать `packages/ispectify/lib/src/testing/` директорию
- [ ] Создать `packages/ispectify/lib/src/export/` директорию
- [ ] Обновить `RedactionService` — добавить static методы: `redactTarget()`, `redactExportString()`, `redactPositionalArgs()`
- [ ] Реализовать: trace_category.dart, trace_category_ids.dart, trace_categories.dart, trace_config.dart, trace_token.dart, trace_keys.dart, trace_extension.dart, trace_message.dart, trace_helpers.dart (`truncateValue`, `safeTrace` — redaction перенесена в RedactionService), trace_stream_transformer.dart
- [ ] `ISpectDbCore.truncateValue` делегирует к core `truncateValue`
- **Done when:** `dart analyze packages/ispectify --fatal-infos` чист. `ISpectLogger` имеет extension methods `trace()`, `traceAsync()`, `traceSync()`, `traceStart()`, `traceEnd()`, `traceStream()`, `traceTransaction()`.

### Шаг 4: ISpectLogDataX (Part 4.4)
- [ ] Создать `packages/ispectify/lib/src/models/log_data_x.dart`
- [ ] Реализовать все convenience getters (traceCategory, traceSource, traceOperation, traceTarget, traceMeta, traceDurationMs, traceSuccess, traceSlow, traceTransactionId, traceCorrelationId)
- [ ] Реализовать category checks (isNetwork, isWs, isSse, isGrpc, isGraphql, isDb, isState, isAuth, isStorage, isPush, isAnalytics, isPayment, isNavigation)
- [ ] Реализовать domain convenience getters (httpStatusCode, requestId, httpHeaders, dbStatement, dbStatementDigest, dbArgs, authProvider, storageBucket, storageSizeBytes, blocType, eventType, pushTitle, pushTopic, paymentAmount, paymentCurrency, hasCategory)
- **Done when:** `dart analyze packages/ispectify --fatal-infos` чист. `ISpectLogData(..., additionalData: {'category': 'network'}).isNetwork == true`.

### Шаг 5: Serialization + Export (Part 3)
- [ ] Добавить `toText(redactKeys:)` в existing `ISpectLogDataSerialization` extension
- [ ] Добавить `toMarkdown(redactKeys:)` в existing `ISpectLogDataSerialization` extension
- [ ] Создать `LogExporter` в `packages/ispectify/lib/src/export/log_exporter.dart` (toJsonLines, toText, toMarkdown, toCsv с maxLogs, redactKeys, CSV formula injection protection)
- **Done when:** `dart analyze` чист. `ISpectLogData('test', key: 'info').toText()` возвращает строку. `LogExporter.toCsv([log])` содержит header.

### Шаг 6: Domain extensions (Part 2)
- [ ] Создать 8 файлов в `trace/extensions/`: auth, storage, push, analytics, payment, sse, grpc, graphql
- [ ] Каждый: early bail `if (!options.enabled)`, делегация в `trace()`/`traceAsync()`
- [ ] Push: auto-correlation `correlationId ?? messageId`
- **Done when:** `dart analyze` чист. `logger.push(source: 'fcm', operation: 'received', messageId: 'x')` создаёт лог с `correlationId == 'x'`.

### Шаг 7: Filters (Part 6.4)
- [ ] Создать `CategoryFilter`, `SourceFilter`, `CorrelationFilter`, `TransactionFilter` в `filter/category_filter.dart`
- **Done when:** `dart analyze` чист. `CategoryFilter({'network'}).apply(networkLog) == true`.

### Шаг 8: FakeISpectLogger (Part 7)
- [ ] Создать `packages/ispectify/lib/src/testing/fake_logger.dart`
- [ ] `maxHistoryItems: 0` по умолчанию, `_traces` no-copy iterable, Queue-based FIFO
- [ ] Query methods: byCategory, bySource, byOperation, byCorrelationId, byTransactionId, byLogKey, errors, slow, byLogLevel
- **Done when:** `dart analyze` чист. `FakeISpectLogger().traces` возвращает пустой List.

### Шаг 9: Рефакторинг ispectify_db (Part 4.1)
- [ ] `ISpectDbConfig extends ISpectTraceConfig` (`slowQueryThreshold` → `slowThreshold`)
- [ ] `db()` и `dbTrace()` делегируют к `trace()`/`traceAsync()` через `_preprocessDb()`
- [ ] `dbTransaction()` делегирует к `traceTransaction()`
- **Done when:** `dart analyze packages/ispectify_db --fatal-infos` чист. `dart test packages/ispectify_db` проходит.

### Шаг 10: Рефакторинг ispectify_bloc (Part 4.3)
- [ ] Observer: `Expando<Queue<String>>` для event correlation (FIFO)
- [ ] Все lifecycle methods (onEvent, onTransition, onChange, onCreate, onClose, onDone, onError) используют `logger.trace()`
- [ ] Удалить typed subclasses из `packages/ispectify_bloc/lib/src/models/`
- **Done when:** `dart analyze packages/ispectify_bloc --fatal-infos` чист. `flutter test packages/ispectify_bloc` проходит. Pattern matching в тестах мигрирован на key-based.

### Шаг 11: Рефакторинг ispectify_dio (Part 4.2)
- [ ] Interceptor: два `trace()` + explicit `logKey` (request + response)
- [ ] `correlationId: requestId` для корреляции
- [ ] `Stopwatch` в `options.extra['_sw']`
- [ ] Удалить typed subclasses из `packages/ispectify_dio/lib/src/models/` (оставить data classes)
- **Done when:** `dart analyze packages/ispectify_dio --fatal-infos` чист. `flutter test packages/ispectify_dio` проходит.

### Шаг 12: Рефакторинг ispectify_http (Part 4.2)
- [ ] Аналогично Dio: два `trace()` + logKey, `Expando<String>` для requestId, `Expando<Stopwatch>` для timing
- [ ] Удалить typed subclasses
- **Done when:** `dart analyze packages/ispectify_http --fatal-infos` чист. `flutter test packages/ispectify_http` проходит.

### Шаг 13: Рефакторинг ispectify_ws (Part 4.2)
- [ ] `trace()` per event с `wsCategory`
- [ ] Миграция pattern matching на key-based
- [ ] Обновить `ISpectWSInterceptorSettings` filter types (`WSSentLog` → `ISpectLogData`)
- [ ] Удалить typed subclasses
- **Done when:** `dart analyze packages/ispectify_ws --fatal-infos` чист. `flutter test packages/ispectify_ws` проходит.

### Шаг 14: UI update (Part 6)
- [ ] Dynamic filter grouping: `_resolveCategory()` с `_categoryCache` (theme-aware invalidation через `_lastTheme`), `_categoryLabel()`
- [ ] Новые icons/colors в `ISpectConstants` для 21 новых log types
- [ ] `ISpectTheme`: добавить `categoryLabels`, `logCategories`, обновить `copyWith()`, `==`, `hashCode`, `toMap()`, `fromMap()`
- [ ] Удалить `group*` l10n строки, добавить `category*` строки в `.arb` файлы, регенерировать
- [ ] Generic correlation banner (correlationId/transactionId)
- [ ] Slow trace badge на log cards (оранжевый, "Slow: Xms")
- [ ] Severity visual hierarchy (цветовая полоска слева + quick-filter "Errors only")
- [ ] Mobile `log_card.dart`: добавить badge area (паритет с desktop)
- [ ] `data_extensions.dart`: исправить `isHttpLog` (+ httpError), обновить `curlCommand`
- [ ] `NetworkTransaction`: обновить fallback getters (method→operation, url→target, statusCode→meta.statusCode)
- [ ] `ISpectNavigatorObserver`: добавить `_routeIds` Map + correlationId для push↔pop↔replace↔remove корреляции
- [ ] `RouteLog`: класть `transitionId` в `additionalData[TraceKeys.correlationId]`
- [ ] `network_transaction_service.dart`: обновить requestId extraction из meta
- **Done when:** `flutter analyze packages/ispect --fatal-infos` чист. `flutter test packages/ispect` проходит. В UI: фильтры группируются динамически, новые иконки отображаются, slow badge видим.

### Шаг 15: Export/Share UI (Part 3.3)
- [ ] Создать `log_export_sheet.dart` — bottom sheet с выбором формата (JSON Lines, Text, Markdown, CSV)
- [ ] Redaction toggle ("Include sensitive data" — default OFF)
- [ ] Обновить `LogsJsonService` для text/markdown/csv форматов
- [ ] Progress indicator для bulk export
- **Done when:** Кнопка Share → bottom sheet → выбор формата → файл генерируется → share dialog.

### Шаг 16: Barrel exports
- [ ] Добавить ВСЕ новые файлы в `packages/ispectify/lib/ispectify.dart` (см. Part 8)
- [ ] Удалить из barrel: `export 'src/network/request_id_generator.dart'`
- [ ] НЕ экспортировать: trace_message.dart, trace_helpers.dart (internal). `RedactionService` уже экспортируется
- [ ] Проверить: `import 'package:ispectify/ispectify.dart'` даёт доступ к `networkCategory`, `TraceKeys`, `ISpectLogDataX`, `FakeISpectLogger`, `LogExporter`
- **Done when:** `dart analyze` чист. Тест: `import 'package:ispectify/ispectify.dart'; final c = networkCategory;` компилируется.

### Шаг 17: Удаление файлов (Part 14 — Deleted)
- [ ] Удалить `packages/ispectify/lib/src/network/network_logs.dart`
- [ ] Удалить `packages/ispectify/lib/src/network/request_id_generator.dart`
- [ ] Удалить typed subclass files (если не удалены на шагах 10-13):
  - `packages/ispectify_dio/lib/src/models/` (log subclasses only, НЕ data classes)
  - `packages/ispectify_http/lib/src/models/` (log subclasses only)
  - `packages/ispectify_ws/lib/src/models/`
  - `packages/ispectify_bloc/lib/src/models/`
- **Done when:** `dart analyze` и `flutter analyze` чисты для ВСЕХ пакетов. Все тесты проходят.

### Шаг 18: Тесты (Part 13)
- [ ] Написать 94 теста (13.1-13.6)
- [ ] `dart test packages/ispectify` — все проходят
- [ ] `flutter test packages/ispect` — все проходят
- [ ] `flutter test packages/ispectify_dio` — все проходят
- [ ] `flutter test packages/ispectify_http` — все проходят
- [ ] `flutter test packages/ispectify_ws` — все проходят
- [ ] `flutter test packages/ispectify_bloc` — все проходят
- [ ] `dart test packages/ispectify_db` — все проходят
- **Done when:** ВСЕ 94 теста проходят. `./bash/check_version_sync.sh` и `./bash/check_dependencies.sh` чисты.

### Шаг 19: Финализация
- [ ] Обновить `version.config` → `5.0.0`
- [ ] `./bash/update_versions.sh --bump major`
- [ ] Обновить `CHANGELOG.md` с migration guide (Part 16)
- [ ] `./bash/update_changelog.sh`
- [ ] `./bash/sync_readme.sh`
- [ ] Обновить `web_logs_viewer/` для нового additionalData layout (backward compat v4+v5)
- [ ] Обновить example apps — удалить ссылки на typed subclasses
- [ ] `./bash/publish.sh --dry-run` — валидация
- **Done when:** `./bash/check_version_sync.sh` чист. `./bash/publish.sh --dry-run` проходит без ошибок.
