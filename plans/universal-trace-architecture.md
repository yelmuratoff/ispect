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

## Part A: Core Trace Foundation (`packages/ispectify/lib/src/trace/`)

### A1. `ISpectTraceCategory`

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

### A2. SSOT: Category ID и Log Key константы

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

### A2b. Предопределённые категории

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

// NB: analyticsCategory и navigationCategory используют один key для success и error.
// Осознанное решение: analytics events и route changes редко имеют distinct error types.
// Если в будущем нужна дифференциация — добавить ISpectLogType.analyticsError / routeError.
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

final navigationCategory = ISpectTraceCategory(
  id: TraceCategoryIds.navigation,
  successKey: ISpectLogType.route.key,
  errorKey: ISpectLogType.route.key,  // same — intentional (KISS)
);

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

### A3. `ISpectTraceConfig`

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

  bool shouldLog({double? localSample, required bool isError}) {
    final rate = isError ? errorSampleRate : (localSample ?? sampleRate);
    return rate == null || samplePass(rate);
  }

  /// NB: Subclasses (e.g. ISpectDbConfig) MUST override copyWith()
  /// to preserve their additional fields. Without override, copyWith()
  /// returns ISpectTraceConfig and loses DB-specific fields.
  ISpectTraceConfig copyWith({...});
}
```

> **Почему нет `operationFilters`:** YAGNI. `sampleRate` + `errorSampleRate` покрывает 99% кейсов. Если нужен per-operation контроль — пользователь задаёт `sample` параметр при вызове `trace()`.

### A4. `ISpectTraceToken`

```dart
/// trace_token.dart

/// Constructor is NOT private: trace_extension.dart needs access from a different file.
/// Class is `final` — cannot be subclassed, so public constructor is safe.
/// **Intentional:** `logKey` is NOT stored in the token. traceStart/traceEnd is designed
/// for single-log protocols where `pickLogKey()` is sufficient. For two-log protocols
/// (HTTP request/response) use `trace()` directly with explicit `logKey` override.
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
```

### A5. `TraceKeys`

```dart
/// trace_keys.dart

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
```

### A6. `ISpectTrace` extension на `ISpectLogger`

```dart
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
      // Единый формат: [source] operation → target (duration)
      final message = buildTraceMessage(
        source: source, operation: operation,
        target: target, key: key, duration: duration,
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
        if (target != null) TraceKeys.target: target,
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
        logLevel: isError ? LogLevel.error : LogLevel.info,
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
        correlationId: correlationId,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, error: e, errorStackTrace: st,
        success: false, duration: sw.elapsed,
        meta: meta, config: cfg, sample: sample, logKey: logKey,
        correlationId: correlationId,
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
        correlationId: correlationId,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, error: e, errorStackTrace: st,
        success: false, duration: sw.elapsed,
        meta: meta, config: config, sample: sample, logKey: logKey,
        correlationId: correlationId,
      );
      rethrow;
    }
  }

  // ── Manual span (request → response) ────────────────
  ISpectTraceToken traceStart({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) => ISpectTraceToken(
    stopwatch: Stopwatch()..start(),
    category: category, source: source, operation: operation,
    target: target, key: key, meta: meta, config: config,
    correlationId: correlationId,
  );

  void traceEnd(
    ISpectTraceToken token, {
    Object? value,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
  }) {
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

    // Pure Dart StreamTransformer (см. A7 ниже)
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
```

### A7. `TraceStreamTransformer` — pure Dart, без rxdart

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
> - `onCancel` вызывается РОВНО ОДИН РАЗ — либо при `subscription.cancel()`, либо при `onDone` upstream (кто первый)
> - `_cancelCalled` guard предотвращает double-call: `sub.cancel()` может trigger `onDone` на некоторых stream types → без guard были бы 2 trace лога "unsubscribe"
> - Если stream = broadcast, `onDone` НЕ вызывается при cancel одного listener → `onCancel` в controller обработает
> - Все trace callbacks обёрнуты в try/catch — исключение в логировании НИКОГДА не ломает data stream
> - `sub.cancel()` возвращает Future → controller ждёт cleanup upstream

### A8. Default message formatter

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

## Part B: Domain Extensions (в `ispectify` core)

Pure Dart, zero deps, tree-shakeable. Каждый ~15-25 строк. Задают category + именованные параметры.

> **Performance pattern:** Все domain extensions делают early bail `if (!options.enabled)` ПЕРЕД
> построением meta Map. Это гарантирует zero overhead в production (disabled ISpect).
> Async extensions возвращают `run()` напрямую, fire-and-forget просто return.

### B1. Auth

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
> fire-and-forget → `if (!options.enabled) return;`. Применить в B2-B8 аналогично.

### B2. Storage

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

### B3. Push

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
      correlationId: correlationId,
    );
  }
}
```

> **NB: Push auto-correlation.** Для связи lifecycle событий одной нотификации
> (received → opened → dismissed), caller должен передавать `messageId` как `correlationId`:
> `logger.push(source: 'fcm', operation: 'received', messageId: id, correlationId: id);`
> `logger.push(source: 'fcm', operation: 'opened', messageId: id, correlationId: id);`
> Все события одного push-уведомления будут связаны через generic correlation banner.

### B4. Analytics

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

### B5. Payment

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

### B6. SSE

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
> последующие `sse()` вызовы (event, disconnected, error). Аналогично WS (Part D2).
> Если пользователь вызывает `sse()` напрямую — ответственность на нём.

### B7. gRPC

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

### B8. GraphQL

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

## Part C: Log Entity — конвертация и экспорт

### C1. `ISpectLogData` — расширение для экспорта

> **`toJson()` уже существует** как extension в `history/serialization.dart` (`ISpectLogDataSerialization`).
> Новые методы `toText()` и `toMarkdown()` добавляются в **тот же** extension, чтобы избежать
> конфликта двух extensions с одинаковыми сигнатурами и держать всю сериализацию в одном месте.

```dart
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
      buffer.writeln('  Exception: ${_redactExportString(exStr, redactKeys)}');
    }
    if (error != null) {
      final errStr = '$error';
      buffer.writeln('  Error: ${_redactExportString(errStr, redactKeys)}');
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
      buffer.writeln('\n**Exception:** `${_redactExportString(exStr, redactKeys)}`');
    }
    if (error != null) {
      final errStr = '$error';
      buffer.writeln('\n**Error:** `${_redactExportString(errStr, redactKeys)}`');
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
  /// **NB: Реализация — shared top-level функция `redactExportString()`**
  /// **в `packages/ispectify/lib/src/redaction/export_redaction.dart`.**
  /// Extension делегирует к ней. Не дублировать!
  ///
  /// Покрывает:
  /// - URL credentials: `https://user:pass@host:8080` → `https://***:***@host:8080`
  /// - URL credentials без пароля: `https://user@host` → `https://***@host`
  /// - Bearer/Basic tokens: `Authorization: Bearer eyJ...` → `Authorization: Bearer ***`
  /// - Query params с sensitive keys: `?token=abc&key=def` → `?token=***&key=***`
  /// - JSON в exception strings: `{"token": "abc"}` → `{"token": "***"}`
  String _redactExportString(String value, Set<String>? redactKeys) {
    if (redactKeys == null || redactKeys.isEmpty) return value;

    // 1. URL credentials (с/без пароля, с портом):
    //    https://user:pass@host:8080 → https://***:***@host:8080
    //    https://user@host → https://***@host
    var result = value.replaceAllMapped(
      RegExp(r'://([^:/@\s]+)(?::([^/@\s]*))?@'),
      (m) => m[2] != null ? '://***:***@' : '://***@',
    );

    // 2. Bearer/Basic tokens в error messages:
    //    Authorization: Bearer eyJhbGci... → Authorization: Bearer ***
    //    Basic dXNlcjpwYXNz → Basic ***
    result = result.replaceAllMapped(
      RegExp(r'(Bearer|Basic)\s+([A-Za-z0-9._\-/+=]{8,})', caseSensitive: false),
      (m) => '${m[1]} ***',
    );

    // 3. Query params с sensitive keys (URL-encoded values тоже):
    //    ?token=abc%26def&key=xyz → ?token=***&key=***
    //    NB: RegExp.escape(key) — защита от regex metacharacters в key names
    for (final key in redactKeys) {
      final escaped = RegExp.escape(key);
      result = result.replaceAllMapped(
        RegExp('([?&])($escaped)=([^&\\s]*)', caseSensitive: false),
        (m) => '${m[1]}${m[2]}=***',
      );
    }

    // 4. JSON-like patterns в exception strings:
    //    {"token": "abc123"} → {"token": "***"}
    //    {"token": 12345} → {"token": "***"}
    //    {"token": true} → {"token": "***"}
    //    Ищем "key": <any_value> где key — sensitive
    for (final key in redactKeys) {
      final escaped = RegExp.escape(key);
      // String values: "key": "value"
      result = result.replaceAllMapped(
        RegExp('"($escaped)"\\s*:\\s*"([^"]*)"', caseSensitive: false),
        (m) => '"${m[1]}": "***"',
      );
      // Number/boolean values: "key": 12345 or "key": true/false/null
      result = result.replaceAllMapped(
        RegExp('"($escaped)"\\s*:\\s*([0-9.eE+\\-]+|true|false|null)', caseSensitive: false),
        (m) => '"${m[1]}": "***"',
      );
    }

    return result;
  }
}
```

### C2. Batch export — список логов

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
      final json = log.toJson();
      // Layer 3: redact exception/error strings в JSON output
      if (redactKeys != null && redactKeys.isNotEmpty) {
        final ex = json['exception'];
        if (ex is String) json['exception'] = _redactExportString(ex, redactKeys);
        final err = json['error'];
        if (err is String) json['error'] = _redactExportString(err, redactKeys);
      }
      return jsonEncode(json);
    }).join('\n');
  }

  /// Layer 3 redaction для export strings.
  /// **NB: Реализация — ОДНА shared top-level функция `redactExportString()`**
  /// **в `packages/ispectify/lib/src/redaction/export_redaction.dart`.**
  /// Не дублировать! ISpectLogDataSerialization._redactExportString и
  /// LogExporter._redactExportString оба делегируют к ней.
  /// Функция internal (не экспортируется в barrel).
  static String _redactExportString(String value, Set<String>? redactKeys) =>
      redactExportString(value, redactKeys);

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
  /// **NB:** CSV — overview формат. `exception`, `error`, `stackTrace` и nested `meta`
  /// НЕ включены в колонки (слишком длинные для табличного формата).
  /// Для полных деталей используйте JSON Lines (`toJsonLines()`) или Text (`toText()`).
  static String toCsv(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln('time,level,key,category,source,operation,target,durationMs,success,message');
    for (final log in capped) {
      final ad = log.additionalData;
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
        _csvEscape(log.message?.toString() ?? ''),
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
  /// Prefixes cells starting with `=`, `+`, `-`, `@` with a tab character
  /// to prevent formula injection in Excel/Google Sheets/LibreOffice.
  static String _csvEscape(String value) {
    var result = value;
    // Formula injection protection: prefix dangerous chars with tab
    if (result.isNotEmpty && '=+-@'.contains(result[0])) {
      result = '\t$result';
    }
    if (result.contains(',') || result.contains('"') || result.contains('\n') || result.contains('\t')) {
      return '"${result.replaceAll('"', '""')}"';
    }
    return result;
  }
}
```

### C3. Share/Export в UI

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

## Part D: Рефакторинг существующих пакетов

### D1. `ispectify_db` → delegates to core trace

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
```

### D2. Network interceptors → ДВА лога (request + response)

> **Почему НЕ traceStart/traceEnd:** HTTP нуждается в двух отдельных логах:
> 1. Request log (при отправке) — чтобы видеть in-flight запросы
> 2. Response log (при получении) — с результатом и duration
> `NetworkTransaction` коррелирует их по `requestId`. `traceStart/traceEnd` создаёт только один лог.

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
Аналогично обновить `ISpectWSInterceptorSettingsBuilder` (settings_builder.dart:38-40, 46, 56, 66).

### D3. `ispectify_bloc` → uses trace()

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
  _pendingEventIds[bloc] = eventId;
}

// Хранение pending eventId для корреляции event → transition → state
final Expando<String> _pendingEventIds = Expando<String>('bloc_event_id');

@override
void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
  super.onTransition(bloc, transition);
  if (!_shouldLog(toggle: settings.printTransitions, candidate: bloc)) return;

  final eventId = _pendingEventIds[bloc]; // ← получаем correlationId от event

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

  final eventId = _pendingEventIds[bloc];
  // Очищаем после state change (последний в цепочке event → transition → state)
  _pendingEventIds[bloc] = null;

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

  final eventId = _pendingEventIds[bloc];  // ← correlate with event chain

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

**BLoC event → transition → state correlation:**
- `onEvent()` генерирует `eventId = generateTraceId()` и сохраняет в `Expando<String>`
- `onTransition()` и `onChange()` получают `eventId` из `Expando` и передают как `correlationId`
- `onChange()` очищает `Expando` (последний в цепочке)
- Пользователь может нажать "Show Related" на любом из трёх логов и увидеть всю цепочку
- `Expando` используется вместо `Map<BlocBase, String>` — автоматически очищается GC при уничтожении BLoC
- **Cubit:** У Cubit нет events, поэтому `onChange()` без `eventId` — ok, correlationId = null

> **Почему нет BaseStateObserverSettings:** BLoC имеет event/transition/change/create/close/done. Riverpod имеет add/update/dispose. MobX имеет reaction/spy. Разные lifecycle — общий base class будет или слишком general (бесполезный) или слишком restrictive. Каждый observer остаётся standalone.

### D4. Backward compatibility — clean break (v5.0)

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
- `logs.dart` convenience subclasses: `GoodLog`, `AnalyticsLog`, `RouteLog`, `ProviderLog`, `PrintLog` — используются в `ISpectLogger` core методах (`good()`, `analytics()`, `route()`, `provider()`, `print()`). Простые key+title wrappers. `RouteLog` имеет `transitionId` для `ISpectNavigationFlowScreen` — специфичная UI фича, не часть trace pipeline.
  - При создании `RouteLog` в `ISpectLogger.route()` — дополнительно класть `transitionId` в `additionalData[TraceKeys.correlationId]`. Это позволит generic correlation banner показать "Show Related" для связанных route events. Альтернатива: отложить до post-v5 (navigation flow screen — отдельная фича).
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
  - **Разграничение extensions:** `ISpectDataX` = UI/display helpers (httpLogText, curlCommand, copyWith, generateText, stackTraceLogText, typeText). `ISpectLogDataX` = trace field access (traceCategory, traceSource, httpStatusCode, etc.). Не объединять — разные ответственности.
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

## Part E: `ISpectLogType` расширение

> **BREAKING CHANGE:** Добавление новых enum values ломает exhaustive switch.
> Задокументировать в CHANGELOG. В migration guide рекомендовать `_` default case.
> Добавить `category` field и новые values в ОДНОМ PR.
>
> **Best practice для пользователей:** Всегда используйте `_` wildcard в switch на `ISpectLogType`.
> Для группировки используйте `logType.category` (не switch по каждому value):
> ```dart
> // DON'T: fragile, breaks on new values
> switch (logType) { case ISpectLogType.httpRequest: ... }
>
> // DO: stable, handles future values
> if (logType.category == TraceCategoryIds.network) { ... }
> ```

### E1. Добавить `category` field

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

### E1b. Обновление `isErrorType`, `level`, `_defaultPens`

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

### E2. Icons и Colors для новых типов

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

## Part F: UI без хардкода (`ispect` package)

### F1. Динамическая группировка фильтров

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

/// Определяет категорию log key. Четыре источника (приоритет):
/// 1. ISpectTheme.logCategories — кастомные mappings от пользователя
/// 2. ISpectLogType enum — built-in log types
/// 3. Prefix heuristic — backward compat для кастомных keys
/// 4. 'general' — fallback
String _resolveCategory(String key, ISpectTheme theme) {
  // 1. User-defined: кастомные log keys → category
  final custom = theme.logCategories?[key];
  if (custom != null) return custom;

  // 2. Built-in: ISpectLogType enum
  final logType = ISpectLogType.fromKey(key);
  if (logType != null) return logType.category;

  // 3. Prefix heuristic (backward compat for custom keys like 'http-custom')
  // Keys with built-in prefix (e.g. 'db-custom') auto-group into that category.
  // To override: use theme.logCategories (priority 1) for explicit mapping.
  final dash = key.indexOf('-');
  if (dash > 0) {
    final prefix = key.substring(0, dash);
    if (TraceCategoryIds.builtIn.contains(prefix)) return prefix;  // ← SSOT
  }

  // 4. Fallback
  return TraceCategoryIds.general;  // ← SSOT
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

### F2. `ISpectTheme` — расширение

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
> ```dart
> ISpect(theme: ISpectTheme(
>   logColors: {'my-success': Colors.teal, 'my-error': Colors.red},
>   logIcons: {'my-success': Icons.check, 'my-error': Icons.close},
>   logCategories: {'my-success': 'my-service', 'my-error': 'my-service'},
>   categoryLabels: {'my-service': 'My Custom Service'},
> ))
> ```
> Результат: кастомные log types группируются в "My Custom Service" с правильными иконками/цветами.

> **Почему нет `detailRenderers`:** JSON viewer — единственный detail view. Универсальный, не требует поддержки per-category renderers. KISS.

### F3. Detail view — JSON viewer + generic correlation

```dart
// LogDetailView — JSON viewer для всех типов.
// Correlation banner — GENERIC, работает для ЛЮБОГО типа с correlationId или transactionId.
// Никакого per-category рендеринга. Простота > красота.
//
// ── Correlation banner (generic) ──
// Если лог имеет correlationId → показать banner: "N related logs" + кнопка "Show All"
// → "Show All" фильтрует список по correlationId (показывает все связанные логи)
// Если лог имеет transactionId → показать banner: "Part of transaction" + кнопка "Show All"
// → "Show All" фильтрует по transactionId
// HTTP: backward compat — NetworkTransaction по-прежнему коррелирует req↔resp через requestId,
//   banner показывает "View Request"/"View Response" как раньше.
// Для других типов (WS stream, gRPC streaming, DB transaction) — generic banner.
//
// ── Slow trace indicator ──
// Если additionalData['slow'] == true → показать warning badge/chip на log card:
// "Slow: {durationMs}ms" с оранжевым цветом.
// Помогает быстро находить медленные запросы без открытия JSON detail.
//
// ── Implementation: _findCorrelation() обобщение ──
// Текущий: `if (!activeLog.isHttpLog) return null;` (HTTP-only)
// Новый: проверяет correlationId → ищет ВСЕ логи с тем же correlationId в history
//         проверяет transactionId → ищет ВСЕ логи с тем же transactionId
//         HTTP fallback → NetworkTransaction correlation (backward compat)
```

### F4. Новые фильтры

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

### F5. Share / Export в UI

```dart
// Добавить в AppBar или detail view:
// - Copy as JSON (clipboard)
// - Copy as text (clipboard)
// - Export all logs → выбор формата (JSON Lines / Text / Markdown)
// - Share log file
//
// Использует ISpectLogDataSerialization extensions (toText, toMarkdown) и LogExporter из Part C.
```

---

## Part G: Testing Utilities

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
  }) : super(options: ISpectLoggerOptions(useConsoleLogs: false));

  final int maxTraces;
  final _queue = Queue<ISpectLogData>();

  /// Read-only snapshot as List (для тестов, where(), firstWhere(), etc.)
  List<ISpectLogData> get traces => _queue.toList();

  @override
  void logData(ISpectLogData data) {
    _queue.add(data);
    while (_queue.length > maxTraces) {
      _queue.removeFirst(); // O(1) vs List.removeAt(0) which is O(n)
    }
    super.logData(data);
  }

  // ── Query by structured trace fields ─────────────────

  List<ISpectLogData> byCategory(String category) =>
      traces.where((t) => t.additionalData?[TraceKeys.category] == category).toList();

  List<ISpectLogData> bySource(String source) =>
      traces.where((t) => t.additionalData?[TraceKeys.source] == source).toList();

  List<ISpectLogData> byOperation(String operation) =>
      traces.where((t) => t.additionalData?[TraceKeys.operation] == operation).toList();

  List<ISpectLogData> byCorrelationId(String correlationId) =>
      traces.where((t) => t.additionalData?[TraceKeys.correlationId] == correlationId).toList();

  List<ISpectLogData> byTransactionId(String transactionId) =>
      traces.where((t) => t.additionalData?[TraceKeys.transactionId] == transactionId).toList();

  List<ISpectLogData> byLogKey(String logKey) =>
      traces.where((t) => t.key == logKey).toList();

  List<ISpectLogData> errors() =>
      traces.where((t) => t.additionalData?[TraceKeys.success] == false).toList();

  List<ISpectLogData> slow() =>
      traces.where((t) => t.additionalData?[TraceKeys.slow] == true).toList();

  /// Query by LogLevel — для non-trace логов (logger.error(), logger.info(), etc.)
  /// которые не имеют TraceKeys.success field.
  List<ISpectLogData> byLogLevel(LogLevel level) =>
      traces.where((t) => t.logLevel == level).toList();

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

## Part H: Package Structure

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
      filter/
        category_filter.dart          # CategoryFilter, SourceFilter, CorrelationFilter, TransactionFilter
      models/
        log_type.dart                 # ISpectLogType + category field + new values
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

## Part I: Как добавить новый сервис (чеклист)

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
> - `meta` — open `Map<String, Object?>`, без жёсткой schema. JSON viewer покажет всё.
> - Используйте descriptive keys: `'statusCode'`, `'bucket'`, `'provider'` — не `'sc'`, `'b'`, `'p'`.
> - Избегайте конфликтов с TraceKeys: не используйте `'category'`, `'source'`, `'operation'` как meta keys.
> - Для cross-isolate корреляции передавайте `correlationId` явно (zone values не пересекают isolate boundaries).

---

## Part I.1: Ответственности — кто за что отвечает (Responsibility Map)

### Redaction — три слоя, без дублирования

```
Слой 1: Domain preprocessing (ПЕРЕД вызовом trace)
  ├── Network: BaseNetworkInterceptor.redactHeaders/Body/Url()
  │   → redacts URLs, headers (Authorization, Cookie), body fields
  │   → domain-specific: знает про HTTP patterns
  ├── DB: ISpectDbCore.redactPositionalArgs/redactIfNeeded()
  │   → redacts SQL args, named args by key matching
  │   → domain-specific: знает про SQL statements
  └── Others: domain extensions НЕ делают redaction
      → передают raw data, полагаются на слой 2

Слой 2: trace() pipeline (ОБЩИЙ safety net)
  → auto-redacts meta по config.redactKeys
  → generic: не знает про HTTP/SQL, но ловит common patterns (token, password, secret, etc.)
  → НЕ дублирует слой 1: если domain уже redacted — redactByKeys на уже чистых данных безопасен (idempotent)

Слой 3: Export (ПРИ ВЫВОДЕ) — финальная линия защиты
  → toJson(truncated: true) — truncates large values
  → toText(redactKeys:) / toMarkdown(redactKeys:) — Layer 3 redaction:
    → additionalData — уже redacted на слое 2 (safe)
    → message — формируется через buildTraceMessage() (НЕ содержит raw данных по-дизайну)
    → exception.toString() — RAW! Может содержать:
      • URL с credentials (https://user:pass@host)
      • SQL statements с литералами
      • Error messages с API keys
      → toText/toMarkdown редактируют exception/error через _redactExportString()
    → stackTrace — НЕ редактируется (file paths, не sensitive data)
  → LogExporter — передаёт redactKeys в toText/toMarkdown + capped по maxLogs
```

**⚠️ ВАЖНО: `exception.toString()` — единственное место, где raw данные могут утечь через export.**
Слой 1 и 2 не могут защитить exception.toString() — exception создаётся ДО вызова trace().
Поэтому Слой 3 добавляет regex-based redaction для URL credentials и query params с sensitive keys.

**Правило:** Domain слой redacts domain-specific patterns. Trace слой — generic safety net для meta. Export слой — финальная защита для exception/error strings + truncation. Нет двойной redaction — `redactByKeys` идемпотентен (уже замаскированные значения не изменяются повторно).

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
Object? truncateValue(Object? value, int maxLen) { ... }

// NB: safeTrace — НЕ safeLogData. Существующий extension method SafeLogExtension.safeLogData()
// на ISpectLogger имеет другую сигнатуру (принимает ISpectLogData, не builder).
// safeTrace — новая top-level функция с lazy builder pattern.
void safeTrace(ISpectLogger logger, ISpectLogData Function() builder) { ... }
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

| Аспект | Решение |
|---|---|
| PII в логах | `ISpectTraceConfig.redactKeys` — auto-redaction в trace(). Default: token, password, secret, authorization, cookie, etc. |
| PII: userId | `userId` передаётся в `meta` (не в `key`/message). Добавить `'userId'` в custom `redactKeys` если нужно. |
| Sensitive headers | `BaseNetworkInterceptor.redactHeaders()` — маскирует Authorization, Cookie, Set-Cookie |
| Sensitive URLs | `BaseNetworkInterceptor.redactUrl()` — маскирует query params с sensitive keys |
| target field (URLs) | Pre-signed URLs (S3, GCS) могут содержать tokens. Domain-layer (storage interceptor) должен redact target ДО передачи в trace(). Документировать как requirement для storage/SSE extensions. |
| SQL injection в логах | `ISpectDbCore.sqlDigest()` — нормализует SQL, заменяет литералы на `?` |
| BLoC event toString() | `settings.printEventFullData` может содержать PII. НЕ включать в production. Документировать risk. |
| Файлы логов на диске | App-sandboxed directory. Redaction применяется ДО записи. `FileLogHistory` пишет уже redacted данные. **Рекомендация:** писать в non-iCloud-backed directory (iOS: `NSCachesDirectory`). |
| Export/Share: additionalData | Уже redacted на слое 2 (trace pipeline). Safe. |
| Export/Share: message | Формируется через `buildTraceMessage()` — НЕ содержит raw данных по-дизайну. Safe. |
| Export/Share: exception/error | **Layer 3 redaction**: `toText/toMarkdown/toJsonLines(redactKeys:)` — regex-based: URL credentials, Bearer/Basic tokens, query params с sensitive keys, JSON patterns. `LogExporter` пробрасывает `redactKeys`. |
| Export/Share: CSV injection | `_csvEscape()` — formula injection protection (tab prefix для `=`, `+`, `-`, `@`). ВСЕ колонки экранируются. |
| Export/Share: OOM protection | `LogExporter` — `maxLogs` safety cap (default: 5000). Для bulk — `LogsJsonService` с chunked/stream processing. |
| Production builds | `if (!options.enabled) return;` — zero overhead. Никакие данные не обрабатываются когда ISpect отключён. |
| Custom redaction keys | Пользователь расширяет: `ISpectTraceConfig(redactKeys: {...defaultSensitiveKeys, 'ssn', 'credit_card'})` |
| defaultSensitiveKeys gaps | Рекомендация: добавить `email`, `otp`, `device_token`, `fcm_token`, `apns_token`, `session_id`, `username` в `defaultSensitiveKeys` (102 → ~109 entries). |
| Zone txnId isolation | `_txnZoneKey` — file-private Object (не public Symbol). Нельзя спуфить из внешнего кода. Zone values НЕ пересекают isolate boundaries — документировано. |
| Rate limiting | **УЖЕ РЕАЛИЗОВАНО:** `ISpectLoggerOptions.maxHistoryItems` (default: 10000) с FIFO-ротацией в `DefaultISpectLoggerHistory._addEntry()`. Предотвращает OOM при высокочастотных WS/SSE/stream событиях. Проверить naming consistency с планом (`maxHistorySize` vs `maxHistoryItems`). |
| ISpectTraceToken lifetime | `final class`, lightweight (Stopwatch). Если `traceEnd()` не вызван — leak minimal (~bytes). Документировать как best practice: всегда вызывать `traceEnd()`. |
| Log rotation | `FileLogHistory` — рекомендация: max file size / max age policy. Out of scope для v5.0, но задокументировать как future improvement. |

---

## Part J: SOLID / Design Patterns

| Принцип | Как соблюдается |
|---|---|
| **SRP** | Каждый файл — одна ответственность: Category, Config, Token, Extension, Formatter, CategoryIds |
| **OCP** | Новая категория = const + extension. Core не меняется. UI не меняется. Enum — inherently closed, но extensible через custom categories |
| **LSP** | ISpectDbConfig extends ISpectTraceConfig — подставляется везде |
| **ISP** | Domain extensions — отдельные, tree-shakeable. Пользователь видит только нужные |
| **DIP** | Interceptors зависят от ISpectLogger + ISpectTraceCategory (абстракции). RedactionService.redactByKeys — static utility (pure function, не нарушает DIP) |
| **SSOT** | Category IDs → `TraceCategoryIds`. Log keys → `ISpectLogType.*.key`. Config → один `ISpectTraceConfig`. Message format → один `buildTraceMessage()`. Correlation → `correlationId` + `transactionId` (zone) |
| **Strategy** | pickLogKey() — стратегия выбора log key |
| **Template Method** | traceAsync — template: check enabled → start timer → run → project → log |
| **Decorator** | BaaS wrappers: implement SDK interface, delegate, trace terminal ops |
| **Observer** | BLoC/Riverpod observers |
| **DRY** | Один trace() pipeline. Domain extensions ~20 строк, не copy-paste. Нет дублирования строковых литералов — category IDs через `TraceCategoryIds`, log keys через `ISpectLogType.*.key`, field names через `TraceKeys` |
| **KISS** | JSON viewer для всех. Один message format для всех. Минимум абстракций |
| **YAGNI** | Нет BaseStateObserverSettings. Нет detailRenderers. Нет operationFilters. Нет messageBuilder |

---

## Part K: Полная таблица покрытия

| Сервис | Паттерн | Категория | Пакет |
|---|---|---|---|
| Dio | two trace() + logKey | network | ispectify_dio |
| http | two trace() + logKey | network | ispectify_http |
| Chopper | two trace() + logKey | network | ispectify_chopper |
| Retrofit | через ispectify_dio | network | — |
| WebSocket | trace() per event | ws | ispectify_ws |
| SSE | trace() per event | sse | ispectify_sse |
| gRPC | traceStart/traceEnd | grpc | ispectify_grpc |
| GraphQL | traceStart/traceEnd | graphql | ispectify_graphql |
| Drift/sqflite | dbTrace() | db | ispectify_db |
| Hive/Isar/ObjectBox | dbTrace() | db | ispectify_db |
| Realm/GetStorage | dbTrace() | db | ispectify_db |
| Postgres/MongoDB/Redis | dbTrace() | db | ispectify_db |
| Firestore | dbTrace() decorator | db | ispectify_firebase |
| Firebase Auth | authTrace() decorator | auth | ispectify_firebase |
| Firebase Storage | storageTrace() decorator | storage | ispectify_firebase |
| Firebase Messaging | push() | push | ispectify_firebase |
| Firebase Analytics | analyticsEvent() | analytics | ispectify_firebase |
| Firebase Remote Config | traceAsync() | analytics | ispectify_firebase |
| Firebase Crashlytics | trace() error forwarding | general | ispectify_firebase |
| Supabase DB | dbTrace() decorator | db | ispectify_supabase |
| Supabase Auth | authTrace() decorator | auth | ispectify_supabase |
| Supabase Storage | storageTrace() decorator | storage | ispectify_supabase |
| Supabase Realtime | traceStream() | sse | ispectify_supabase |
| Appwrite | decorator pattern | auth/db/storage | ispectify_appwrite |
| PocketBase | decorator pattern | auth/db | ispectify_pocketbase |
| PowerSync | dbTrace() | db | ispectify_db |
| BLoC | trace() in observer | state | ispectify_bloc |
| Riverpod | trace() in observer | state | ispectify_riverpod |
| MobX | trace() in spy | state | ispectify_mobx |
| Redux | trace() in middleware | state | ispectify_redux |
| GetX | trace() in observer | state | ispectify_getx |
| Navigator | trace() in observer | navigation | ispect |
| GoRouter | trace() in observer | navigation | example |
| AutoRoute | trace() in observer | navigation | example |
| FCM | push() | push | ispectify_firebase |
| OneSignal | push() | push | ispectify_onesignal |
| local_notifications | push() | push | example |
| Sentry | trace() breadcrumb | general | ispectify_sentry |
| Mixpanel | analyticsEvent() | analytics | example |
| Amplitude | analyticsEvent() | analytics | example |
| in_app_purchase | paymentTrace() | payment | example |
| RevenueCat | paymentTrace() | payment | example |
| WorkManager | traceAsync() + custom category | custom | example |
| cached_network_image | storageTrace() | storage | example |

---

## Part L: Implementation Order

1. **maxHistorySize** — **УЖЕ РЕАЛИЗОВАНО** как `ISpectLoggerOptions.maxHistoryItems` (default: 10000) с FIFO-ротацией в `DefaultISpectLoggerHistory._addEntry()`. Проверить naming consistency: если план использует `maxHistorySize` — решить, переименовывать ли на `maxHistorySize` для единообразия с `FakeISpectLogger.maxTraces`, или оставить `maxHistoryItems`. Не нужна реализация с нуля.
1.5. **defaultSensitiveKeys update** — добавить в `key_defaults.dart`: `'email'`, `'e-mail'`, `'email_address'`, `'otp'`, `'one_time_password'`, `'device_token'`, `'fcm_token'`, `'apns_token'`, `'push_token'`, `'session_id'`, `'session_token'`, `'username'`, `'user_name'`, `'bearer_token'`. Добавить regex pattern: `r'(?:e[-_]?mail|otp|device[-_]?token|push[-_]?token|session[-_]?(?:id|token))'`.
2. **Создать директории** + Core trace primitive:
   - Создать: `packages/ispectify/lib/src/trace/`, `packages/ispectify/lib/src/testing/`, `packages/ispectify/lib/src/export/`
   - `packages/ispectify/lib/src/filter/` — уже существует ✅
   - Core files: trace_category, trace_category_ids, trace_categories, trace_config, trace_token, trace_keys, trace_extension, trace_message, trace_helpers, trace_stream_transformer
   - `truncateValue()` в `trace_helpers.dart` — core-level. `ISpectDbCore.truncateValue` делегирует к ней
3. **ISpectLogType update** — enum + category field + new enum values + `isErrorType` (добавить blocError + 9 новых error types, см. E1b) + `level` (новые error types → LogLevel.error) + `_defaultPens` (21 новых mappings, см. E1b)
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
14. **UI update** — dynamic filter grouping, new icons/colors, categoryLabels + logCategories в ISpectTheme, **удалить group* l10n strings → добавить category* strings** (**Маппинг: `groupHttp`→`categoryNetwork`, `groupBloc`→`categoryState`, `groupRiverpod`→`categoryState`, `groupWebSocket`→`categoryWebSocket`, `groupDatabase`→`categoryDb`, `groupNavigation`→`categoryNavigation`, `groupGeneral`→fallback capitalize), regenerate localizations, generic correlation banner (correlationId/transactionId), slow trace badge on log cards. **NB: mobile log_card.dart** — добавить badge area (сейчас нет, desktop имеет statusCode badge). Нужно: slow query badge (оранжевый, "Slow: {ms}ms"), error type badge, statusCode badge (паритет с desktop_log_row.dart). Обновить `data_extensions.dart`: исправить `isHttpLog` (добавить `|| key == ISpectLogType.httpError.key`), обновить `curlCommand` (from `additionalData?['request-options']` → собирать cURL из trace fields: `TraceKeys.operation`, `TraceKeys.target`, `traceMeta?['headers']`, `traceMeta?['body']`; также добавить backward compat fallback: `traceMeta?['requestOptions']` для imported v4 logs). При имплементации generic correlation banner — рассмотреть index `Map<String, List<int>>` по correlationId для O(1) lookup (текущий `_findCorrelation()` O(n) при 10K+ логах)
15. UI: export/share sheet (JSON Lines, Text, Markdown, CSV + redactKeys + maxLogs cap)
16. Barrel exports: добавить ВСЕ новые файлы в `ispectify.dart` (см. Part H), включая `log_data_x.dart`
17. **Тесты**: standard (M1/M1b) + security (M2) + edge cases (M3) + **конкретная миграция тестов:**
    - `ispectify_bloc/test/ispect_bloc_observer_test.dart:67,83,100,115`: `whereType<BlocEventLog>()` → `.where((e) => e.key == ISpectLogType.blocEvent.key)`
    - `ispectify_dio/test/formdata_fields_test.dart:107`: `is DioRequestLog` → `e.key == ISpectLogType.httpRequest.key`
    - `ispectify_dio/test/logs_test.dart`: конструкторы → `ISpectLogData(message, key: ISpectLogType.httpRequest.key, additionalData: {...})`
    - `ispectify/test/network_logs_test.dart`: конструкторы → `ISpectLogData` с additionalData
    - `ispectify_ws/test/interceptor_test.dart:112-130`: `sentFilter: (WSSentLog _) => false` → `sentFilter: (ISpectLogData _) => false`
18. Migration guide: CHANGELOG.md + Part P содержимое

---

## Part M: Verification

### M1. Стандартные проверки

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
14. Обновить barrel exports `packages/ispectify/lib/ispectify.dart` — добавить ВСЕ новые файлы (см. Part H barrel comment)
15. Проверить что predefined categories (`networkCategory`, `dbCategory`, etc.) доступны через `import 'package:ispectify/ispectify.dart'`

### M1b. Unit tests для core primitives (обязательные)

16. **`ISpectTraceCategory.pickLogKey`:** 3 ветки — error, secondary match, default success
17. **`ISpectTraceConfig.shouldLog`:** null sampleRate → always log; errorSampleRate override; localSample override
18. **`buildTraceMessage`:** все комбинации optional fields (target, key, duration, success/failure)
19. **`CategoryFilter.apply`:** match, no-match, missing category in additionalData
20. **`SourceFilter.apply`:** match, no-match, missing source in additionalData
21. **`FakeISpectLogger.byLogLevel`:** query non-trace logs by LogLevel
22. **`truncateValue`:** string truncation, non-string passthrough, null handling
23. **`_csvEscape`:** formula injection chars (`=`, `+`, `-`, `@`), commas, quotes, newlines
24. **`_redactExportString`:** URL credentials, Bearer tokens, query params, JSON patterns, RegExp.escape for special key chars

### M2. Security-specific тесты

25. **Export redaction:** `toText(redactKeys: defaultSensitiveKeys)` — exception с URL credentials (`https://user:pass@host`) редактируется → `https://***:***@host`
26. **Export redaction:** `toText(redactKeys: {'token'})` — exception с `?token=abc123` → `?token=***`
27. **Export redaction: Bearer tokens:** exception с `Authorization: Bearer eyJhbG...` → `Authorization: Bearer ***`
28. **Export redaction:** `toMarkdown(redactKeys: ...)` — аналогичные проверки
29. **Export redaction backward compat:** `toText(redactKeys: null)` — НЕ редактирует (null = no Layer 3)
30. **toJsonLines redaction:** `LogExporter.toJsonLines(logs, redactKeys: {'token'})` — exception с `?token=abc` → `?token=***`
31. **CSV formula injection:** source='=CMD(...)' → escaped с tab prefix, обёрнут в кавычки
32. **CSV all columns escaped:** все 10 колонок проходят через `_csvEscape`
33. **LogExporter cap:** `LogExporter.toText(logsOf100K)` — берёт последние 5000, header показывает `(capped from 100000)`
34. **LogExporter no-cap:** `LogExporter.toText(logs, maxLogs: null)` — без лимита (осторожно!)
35. **FakeISpectLogger maxTraces:** при 15000 логов с maxTraces=10000 — `traces.length == 10000`, первые 5000 удалены (FIFO)
36. **toMarkdown JsonEncoder guard:** additionalData с non-JSON type (e.g. custom object) → fallback на toString(), не throw
37. **userId not in message:** `authTrace(userId: 'user@email.com')` → message string НЕ содержит email
38. **Zone key private:** `Zone.current[#ispectTxnId]` returns null (public Symbol), only `_txnZoneKey` works

### M3. Тесты на edge cases (обязательные)

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

### M4. Regression тесты для fixes 110-117

50. **safeTrace catches buildTraceMessage errors:** передать объект с broken `toString()` как `target` → нет exception, trace silently dropped
51. **ISpectLogDataX defensive getters:** `additionalData` содержит `{TraceKeys.meta: "not a map", TraceKeys.durationMs: "not int"}` → все getters возвращают `null`, не бросают TypeError
52. **ISpectLogDataX paymentAmount num→double:** `traceMeta?['amount']` = `100` (int) → `paymentAmount` возвращает `100.0` (double), не null
53. **TraceStreamTransformer controller.isClosed:** subscribe → cancel в первом onData → второй event не бросает StateError
54. **Convenience getters на v4 logs:** `ISpectLogData` без TraceKeys в additionalData → все ISpectLogDataX getters возвращают null

### M5. Coverage gap тесты

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

---

## Part N: Critical Files

### New (ispectify core)
- `packages/ispectify/lib/src/redaction/export_redaction.dart` — shared `redactExportString()` (internal, not exported)
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
- `packages/ispect/lib/src/features/ispect/presentation/widgets/settings/log_type_filter_section.dart` — dynamic grouping via _resolveCategory

### Deleted (clean break v5.0) — ТОЛЬКО typed LOG subclasses
- `packages/ispectify/lib/src/network/network_logs.dart` — BaseNetworkLog, NetworkRequestLog, NetworkResponseLog, NetworkErrorLog, `kRequestIdKey`
- `packages/ispectify_dio/lib/src/models/` — DioRequestLog, DioResponseLog, DioErrorLog (log subclasses only)
- `packages/ispectify_http/lib/src/models/` — HttpRequestLog, HttpResponseLog, HttpErrorLog (log subclasses only)
- `packages/ispectify_ws/lib/src/models/` — WSSentLog, WSReceivedLog, WSErrorLog, WSLogFields
- `packages/ispectify_bloc/lib/src/models/` — BlocLifecycleLog (sealed), BlocEventLog, BlocTransitionLog, BlocStateLog, BlocCreateLog, BlocCloseLog, BlocDoneLog, BlocErrorLog

### НЕ удаляется — data helper classes
- `packages/ispectify_dio/lib/src/data/request.dart` — DioRequestData (data class with toJson())
- `packages/ispectify_dio/lib/src/data/response.dart` — DioResponseData (data class with toJson())
- `packages/ispectify_dio/lib/src/data/error.dart` — DioErrorData (data class with toJson())
- `packages/ispectify_http/lib/src/data/` — аналогичные data classes (HttpRequestData, HttpResponseData)
- Эти классы содержат toJson() с redaction и используются interceptor'ами для сериализации в meta

---

## Part O: Верификация API и UI совместимости

### API compatibility — все вызовы из плана верифицированы:

| API call в плане | Существует | Файл | Статус |
|---|---|---|---|
| `ISpectLogData(message, key:, logLevel:, additionalData:, ...)` | Да | models/data.dart | OK — positional message, unmodifiable additionalData |
| `ISpectLogData.toJson()` | Да | history/serialization.dart | OK — **extension** `ISpectLogDataSerialization`, не метод на классе. `toText()`/`toMarkdown()` добавляются в тот же extension |
| `cleanMap(additionalData)` | Да | utils/common_utils.dart | OK — убирает null и пустые строки |
| `RedactionService.redactByKeys(meta, keys)` | Да | redaction/redaction_service.dart | OK — static, case-insensitive, recursive |
| `ISpectLogType.fromKey(key)` | Да | models/log_type.dart | OK — static lookup via `_byKey` map, nullable |
| `LogLevel.error`, `LogLevel.info` | Да | models/log_level.dart | OK |
| `ISpectLogger.logData(data)` | Да | ispectify.dart | OK — public, can override |
| `options.enabled` | Да | ispectify.dart + options.dart | OK — `ISpectLoggerOptions get options` → `options.enabled` |
| `samplePass(rate)` | Да | utils/common_utils.dart | OK — null/>=1 → true, <=0 → false, else random |
| `generateTraceId()` | Да | utils/common_utils.dart | OK — 16-char hex from timestamp+random |
| `ISpectDbCore.truncateValue(value, maxLen)` | Да | db_core.dart:66 | OK — static |
| `ISpectDbCore.sqlDigest(statement)` | Да | db_core.dart:46 | OK — static |
| `ISpectDbCore.redactPositionalArgs(args, keys, stmt)` | Да | db_core.dart:97 | OK — static |
| `BaseNetworkInterceptor` | Да | network/base_interceptor.dart | OK — **mixin** с `redactHeaders()`, `redactBody()`, `redactUrl()`, `NetworkPayloadSanitizer` |
| `defaultSensitiveKeys` | Да | redaction/constants/key_defaults.dart | OK — `Set<String>` с 102 записями |
| `Filter<T>` interface | Да | filter/filter.dart | OK — abstract class с `bool apply(T item)` |
| `ISpectLogData.formattedTime` | Да | models/data.dart:68 | OK — late final getter |

### UI clean break — все компоненты проверены:

| Компонент | Зависит от typed subclasses? | Fallback через additionalData? | Статус |
|---|---|---|---|
| LogCard | Нет (кроме `is RouteLog`) | Да | SAFE |
| CollapsedBody | Нет — получает statusCode через параметр | Да, но вызывающий код (LogCard, DesktopLogRow) читает `additionalData?['statusCode']` на top-level → **ОБНОВИТЬ** на `(additionalData?[TraceKeys.meta] as Map?)?['statusCode']` | NEEDS UPDATE |
| NetworkTransactionCard | Нет напрямую — через NetworkTransaction | Да — fallback в getters | SAFE |
| NetworkTransaction | Да — type checks, НО с fallback | **ОБНОВИТЬ**: fallback keys не совпадают с trace layout (method→operation, url→target, statusCode→meta.statusCode). Getters нужно переписать | NEEDS UPDATE |
| LogDetailView | Нет — generic correlationId/transactionId + HTTP fallback | N/A | SAFE |
| ShareLogBottomSheet | Нет — работает с Map | N/A | SAFE |
| ShareAllLogsSheet | Нет — `.toJson()` | N/A | SAFE |
| LogExportService | Нет — delegates | N/A | SAFE |
| LogsJsonService | Нет — `.toJson()` / `fromJson()` | N/A | SAFE |
| LogTypeFilterSection | Нет — prefix matching | N/A | SAFE |
| CurlCommand | Нет — extension на ISpectLogData через additionalData + key | `additionalData?['request-options']` → `traceMeta?['requestOptions']` + fallback | NEEDS UPDATE |
| `message` property | Нет — поле на ISpectLogData | N/A | SAFE |

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
- Export: additionalData — уже redacted (Layer 2). exception/error — Layer 3 regex redaction через `_redactExportString()`
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

## Part P: Migration Guide v4.x → v5.0

### P1. Удалённые typed subclasses — замена на ISpectLogDataX

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

### P2. Key/field renames

| v4.x | v5.0 | Где |
|------|------|-----|
| `kRequestIdKey = 'request-id'` | `'requestId'` | `meta['requestId']` (nested) |
| `additionalData['method']` | `additionalData['operation']` | top-level, `TraceKeys.operation` |
| `additionalData['url']` | `additionalData['target']` | top-level, `TraceKeys.target` |
| `additionalData['statusCode']` | `meta['statusCode']` | nested в `TraceKeys.meta` |
| `ISpectDbConfig.slowQueryThreshold` | `ISpectTraceConfig.slowThreshold` | config parameter |

### P3. Interceptor API — без изменений для пользователей

Пользователи НЕ меняют свой код для Dio/HTTP/WS/BLoC interceptors:
```dart
// Осталось как было:
dio.interceptors.add(ISpectDioInterceptor(logger: logger));
// Внутренне interceptor теперь вызывает trace() вместо создания typed subclasses.
```

### P4. ISpectLogType exhaustive switch

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

### P5. Export API — новые параметры

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

### P6. ISpectTheme — новые поля (optional)

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

### P7. Дополнительные breaking changes (не забыть!)

| Что изменилось | Ошибка компиляции | Миграция |
|---|---|---|
| `RedactionService.redactByKeys` signature | `List<String>` → `Iterable<String>` | Если вызывали напрямую — Set и List оба совместимы с `Iterable`, `.toList()` больше не нужен |
| `kRequestIdKey` удалён | `Undefined name 'kRequestIdKey'` | Заменить на строковый литерал `'requestId'` или `ISpectLogDataX.requestId` |
| `ISpectDbConfig.slowQueryThreshold` | `The named parameter 'slowQueryThreshold' isn't defined` | Заменить на `slowThreshold`: `ISpectDbConfig(slowThreshold: Duration(seconds: 1))` |
| BLoC typed subclasses в тестах | `Undefined class 'BlocEventLog'` | Заменить `is BlocEventLog` → `log.key == ISpectLogType.blocEvent.key`. Аналогично для `BlocTransitionLog`, `BlocStateLog`, `BlocCreateLog`, `BlocCloseLog`, `BlocDoneLog`, `BlocErrorLog` |
| WS typed subclasses | `Undefined class 'WSSentLog'` | Заменить на `log.key == ISpectLogType.wsSent.key` |
| `ISpectWSInterceptorSettings` filter callbacks | `The argument type 'bool Function(WSSentLog)' can't be assigned to the parameter type 'bool Function(ISpectLogData)'` | Заменить `bool Function(WSSentLog)?` → `bool Function(ISpectLogData)?`. Доступ к полям: `log.additionalData?[TraceKeys.meta]` или convenience getters из `ISpectLogDataX` (e.g., `log.traceOperation`). Аналогично для `receivedFilter`, `errorFilter`. |
| `RequestIdGenerator` format changed | Нет ошибки компиляции | Формат requestId меняется: v4 `'net-{sessionHex}-{counter}'` → v5 `generateTraceId()` (16-char hex). `NetworkTransactionService` коррелирует по equality — формат не важен. Импортированные v4 логи с `net-*` requestId корректно группируются. Key: v4 `'request-id'` (kebab, top-level) → v5 `'requestId'` (camelCase, nested в meta). |
| `l10n.group*` → `l10n.category*` | `The getter 'groupHttp' isn't defined` | Маппинг: `groupHttp`→`categoryNetwork`, `groupBloc`→`categoryState`, `groupRiverpod`→`categoryState`, `groupWebSocket`→`categoryWebSocket`, `groupDatabase`→`categoryDb`, `groupNavigation`→`categoryNavigation`, `groupGeneral`→removed (fallback: capitalize category id) |
| `data_extensions.dart` `curlCommand` | Runtime: cURL returns null | `additionalData?['request-options']` → `traceMeta?['requestOptions']` (v5 Dio interceptor кладёт в meta). Backward compat для imported v4 logs: fallback to `additionalData?['request-options']` |
| `authTrace(userId:)` теперь в meta | `userId` больше не в `key` field / message string | Если искали userId в `log.key` → теперь в `log.traceMeta?['userId']` |

### P8. Минимальная миграция (happy path)

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
