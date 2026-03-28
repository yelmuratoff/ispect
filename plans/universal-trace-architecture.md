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
- `ISpectLogType` enum — существующие values (`httpRequest`, `httpResponse`, `httpError`, `dbQuery`, `dbResult`, `dbError`, `wsSent`, `wsReceived`, `blocEvent`, etc.) + `fromKey()` static method
- `RedactionService.redactByKeys()` — static, `(Object? data, List<String> keys)`
- `defaultSensitiveKeys` — `const Set<String>` (118 entries)
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
    this.secondaryOperations = const {},
  });

  final String id;                        // 'network', 'db', 'ws', 'auth', ...
  final String successKey;                // log key при успехе (default)
  final String errorKey;                  // log key при ошибке
  final String? secondaryKey;             // optional: альтернативный success key
  final Set<String> secondaryOperations;  // operations → используют secondaryKey

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
);

final analyticsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.analytics,
  successKey: ISpectLogType.analytics.key,
  errorKey: ISpectLogType.analytics.key,
);

final paymentCategory = ISpectTraceCategory(
  id: TraceCategoryIds.payment,
  successKey: ISpectLogType.paymentSuccess.key,
  errorKey: ISpectLogType.paymentError.key,
);

final navigationCategory = ISpectTraceCategory(
  id: TraceCategoryIds.navigation,
  successKey: ISpectLogType.route.key,
  errorKey: ISpectLogType.route.key,
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

  ISpectTraceConfig copyWith({...});
}
```

> **Почему нет `operationFilters`:** YAGNI. `sampleRate` + `errorSampleRate` покрывает 99% кейсов. Если нужен per-operation контроль — пользователь задаёт `sample` параметр при вызове `trace()`.

### A4. `ISpectTraceToken`

```dart
/// trace_token.dart

/// Constructor is NOT private: trace_extension.dart needs access from a different file.
/// Class is `final` — cannot be subclassed, so public constructor is safe.
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

    // Единый формат: [source] operation → target (duration)
    // NB: buildTraceMessage — top-level function из trace_message.dart
    final message = buildTraceMessage(
      source: source, operation: operation,
      target: target, key: key, duration: duration,
      success: !isError,
    );

    // Auto-redaction meta по config.redactKeys
    // NB: redactByKeys принимает List<String>, redactKeys — Set<String>
    final safeMeta = cfg.redact
        ? RedactionService.redactByKeys(meta, cfg.redactKeys.toList())
        : meta;

    // Auto-inject transaction ID from zone (set by traceTransaction)
    // Defensive cast: avoids CastException if zone value is non-String
    final rawTxnId = Zone.current[#ispectTxnId];
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

    // NB: safeLogData — top-level function из trace_helpers.dart
    safeLogData(this, () => ISpectLogData(
      message,
      key: resolvedLogKey,
      logLevel: isError ? LogLevel.error : LogLevel.info,
      additionalData: cleanMap(additionalData),
      exception: error is Exception ? error : null,
      error: error is Error ? error : null,
      stackTrace: isError && cfg.attachStackOnError ? errorStackTrace : null,
    ));
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
      zoneValues: {#ispectTxnId: txnId},
    );
  }
}
```

### A7. `TraceStreamTransformer` — pure Dart, без rxdart

```dart
/// trace_stream_transformer.dart

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

    controller = StreamController<T>(
      onListen: () {
        onListen();
        sub = stream.listen(
          (data) { onData(data); controller.add(data); },
          onError: (Object e, StackTrace st) { onError(e, st); controller.addError(e, st); },
          onDone: controller.close,
        );
      },
      onPause: () => sub.pause(),
      onResume: () => sub.resume(),
      onCancel: () { onCancel(); return sub.cancel(); },
      sync: true,
    );

    return controller.stream;
  }
}
```

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

### B1. Auth

```dart
extension ISpectLoggerAuth on ISpectLogger {
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
  }) => traceAsync(
    category: authCategory,
    source: source,
    operation: operation,
    key: userId,
    meta: {if (provider != null) 'provider': provider, ...?meta},
    run: run,
    projectResult: projectResult,
    config: config,
    correlationId: correlationId,
  );

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
  }) => trace(
    category: authCategory,
    source: source,
    operation: operation,
    key: userId,
    success: success,
    error: error,
    duration: duration,
    meta: {if (provider != null) 'provider': provider, ...?meta},
    config: config,
  );
}
```

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
  }) => traceAsync(
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
  }) => trace(
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
  );
}
```

### B4. Analytics

```dart
extension ISpectLoggerAnalytics on ISpectLogger {
  void analyticsEvent({
    required String source,     // 'firebase', 'mixpanel', 'amplitude'
    required String event,
    Map<String, Object?>? parameters,
    ISpectTraceConfig? config,
  }) => trace(
    category: analyticsCategory,
    source: source, operation: event,
    meta: parameters, success: true,
    config: config,
  );
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
  }) => traceAsync(
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
```

### B6. SSE

```dart
extension ISpectLoggerSSE on ISpectLogger {
  void sse({
    required String source,
    required String operation,  // 'connected', 'event', 'disconnected'
    String? url,
    String? eventType,
    String? eventId,
    Map<String, Object?>? data,
    ISpectTraceConfig? config,
  }) => trace(
    category: sseCategory,
    source: source, operation: operation,
    target: url, key: eventId,
    meta: {
      if (eventType != null) 'eventType': eventType,
      if (data != null) 'data': data,
    },
    success: operation != 'error',
    config: config,
  );
}
```

### B7. gRPC

```dart
extension ISpectLoggerGrpc on ISpectLogger {
  Future<T> grpcTrace<T>({
    required String source,
    required String operation,  // 'unary', 'serverStreaming', 'clientStreaming'
    required Future<T> Function() run,
    String? service,
    String? method,
    Map<String, Object?>? metadata,
    Object? Function(T)? projectResult,
    ISpectTraceConfig? config,
    String? correlationId,
  }) => traceAsync(
    category: grpcCategory,
    source: source, operation: operation,
    target: service != null && method != null ? '$service/$method' : null,
    meta: {
      if (service != null) 'service': service,
      if (method != null) 'method': method,
      if (metadata != null) 'metadata': metadata,
    },
    run: run, projectResult: projectResult,
    config: config, correlationId: correlationId,
  );
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
  }) => traceAsync(
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

  /// Plain text — для шаринга, копирования, чтения человеком
  String toText() {
    final buffer = StringBuffer()
      ..writeln('[$formattedTime] [$key] $message');

    if (additionalData != null && additionalData!.isNotEmpty) {
      for (final entry in additionalData!.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    if (exception != null) buffer.writeln('  Exception: $exception');
    if (error != null) buffer.writeln('  Error: $error');
    if (stackTrace != null) buffer.writeln('  StackTrace:\n$stackTrace');

    return buffer.toString();
  }

  /// Markdown — для вставки в issue tracker, документацию
  String toMarkdown() {
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
        ..writeln('```json')
        ..writeln(JsonEncoder.withIndent('  ').convert(additionalData))
        ..writeln('```');
    }

    if (exception != null) {
      buffer.writeln('\n**Exception:** `$exception`');
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
}
```

### C2. Batch export — список логов

> **NB:** Utility class вместо extension на `List<ISpectLogData>` — extension был бы доступен
> на ЛЮБОМ `List<ISpectLogData>`, что приводит к случайным вызовам на больших наборах.
> Явный вызов `LogExporter.toText(logs)` безопаснее.
> Для bulk export в UI — использовать существующий `LogsJsonService` с chunked processing,
> расширив его поддержкой text/markdown форматов (yield каждые 50 items).

```dart
/// log_exporter.dart — utility для batch export малых наборов (< 1000 логов).
/// Для bulk — LogsJsonService с chunked processing.

abstract final class LogExporter {

  /// Export as JSON Lines (одна строка = один лог)
  static String toJsonLines(List<ISpectLogData> logs) =>
      logs.map((log) => jsonEncode(log.toJson())).join('\n');

  /// Export as plain text
  static String toText(List<ISpectLogData> logs) {
    final buffer = StringBuffer()
      ..writeln('=== ISpect Log Report ===')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Total entries: ${logs.length}')
      ..writeln('---');
    for (final log in logs) {
      buffer.writeln(log.toText());
    }
    return buffer.toString();
  }

  /// Export as Markdown
  static String toMarkdown(List<ISpectLogData> logs) {
    final buffer = StringBuffer()
      ..writeln('# ISpect Log Report')
      ..writeln()
      ..writeln('> Generated: ${DateTime.now().toIso8601String()} | Entries: ${logs.length}')
      ..writeln();
    for (final log in logs) {
      buffer
        ..writeln(log.toMarkdown())
        ..writeln('---');
    }
    return buffer.toString();
  }
}
```

### C3. Share/Export в UI

```dart
/// В ispect Flutter UI:

// Экспорт одного лога:
// - Copy as JSON (clipboard)
// - Copy as text (clipboard)
// - Share as markdown

// Экспорт всех / filtered логов:
// - Save as .json file
// - Save as .txt file
// - Save as .md file
// - Share file

// Иконки в AppBar:
// [Share] → bottom sheet с опциями формата
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
      if (settings.printRequestHeaders) 'headers': redactHeaders(options.headers),
      if (settings.printRequestData) 'body': redactBody(options.data),
    },
  );
}

void onResponse(Response response, ...) {
  final requestId = response.requestOptions.extra['requestId'] as String?;
  final sw = response.requestOptions.extra['_sw'] as Stopwatch?;
  sw?.stop();

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
      if (settings.printResponseHeaders) 'headers': response.headers.map,
      if (settings.printResponseData) 'body': response.data,
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

**`ispectify_http`:** аналогично, `Expando<String>` для requestId + `Expando<Stopwatch>` для timing.

**`traceStart/traceEnd`** используется для протоколов с ОДНИМ логом (gRPC unary, GraphQL query/mutation).
Для gRPC streaming и GraphQL subscription — `traceStream()`.
`traceAsync()`, `traceSync()` — тоже поддерживают `logKey` override (пробрасывают в `trace()`).
`traceEnd()` — НЕ нуждается в `logKey` (используется только для one-log протоколов, `pickLogKey` достаточен).

**`ispectify_ws`:** `trace(category: wsCategory, operation: 'send'|'receive', ...)` per event. `wsCategory.pickLogKey()` returns `ws-sent` for send, `ws-received` for receive, `ws-error` for errors.

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
    success: true,
  );
}
```

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
    // meta содержит domain-specific данные (statusCode, headers, body)
    final respMeta = response?.additionalData?[TraceKeys.meta] as Map<String, dynamic>?;
    final errMeta = error?.additionalData?[TraceKeys.meta] as Map<String, dynamic>?;
    return respMeta?['statusCode'] as int? ?? errMeta?['statusCode'] as int?;
  }

  String? get method =>
      request.additionalData?[TraceKeys.operation] as String?;

  String? get url =>
      request.additionalData?[TraceKeys.target] as String?;
  ```
- Convenience extensions для доступа к trace данным:

```dart
extension ISpectLogDataX on ISpectLogData {
  // ── Structured trace field access ──────────────────
  String? get traceCategory => additionalData?[TraceKeys.category] as String?;
  String? get traceSource => additionalData?[TraceKeys.source] as String?;
  String? get traceOperation => additionalData?[TraceKeys.operation] as String?;
  String? get traceTarget => additionalData?[TraceKeys.target] as String?;
  Map<String, dynamic>? get traceMeta => additionalData?[TraceKeys.meta] as Map<String, dynamic>?;
  int? get traceDurationMs => additionalData?[TraceKeys.durationMs] as int?;
  bool? get traceSuccess => additionalData?[TraceKeys.success] as bool?;
  String? get traceTransactionId => additionalData?[TraceKeys.transactionId] as String?;
  String? get traceCorrelationId => additionalData?[TraceKeys.correlationId] as String?;

  // ── Domain-specific convenience (from nested meta) ──
  int? get httpStatusCode => traceMeta?['statusCode'] as int?;
  String? get requestId => traceMeta?['requestId'] as String?;

  // ── Category checks ────────────────────────────────
  bool get isNetwork => traceCategory == TraceCategoryIds.network;
  bool get isDb => traceCategory == TraceCategoryIds.db;
  bool get isAuth => traceCategory == TraceCategoryIds.auth;
  // etc. — всегда через TraceCategoryIds (SSOT)
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

  // ── General (no specific category) ────────────
  error('error'), critical('critical'), info('info'),
  debug('debug'), verbose('verbose'), warning('warning'),
  exception('exception'), good('good'), print('print'),
  provider('provider'),
  ;

  const ISpectLogType(this.key, {this.category = TraceCategoryIds.general});
  final String key;
  final String category;
}
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
    // ...existing fields (logColors, logIcons, logDescriptions)...
    this.categoryLabels,    // ← NEW: display name для категории
    this.logCategories,     // ← NEW: mapping log key → category id
  });

  /// Custom category display labels: {'my-service': 'My Service Name'}
  final Map<String, String>? categoryLabels;

  /// Custom log key → category mapping: {'my-success': 'my-service', 'my-error': 'my-service'}
  /// Позволяет кастомным log keys группироваться в нужную категорию.
  final Map<String, String>? logCategories;
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

### F3. Detail view — JSON viewer only

```dart
// LogDetailView — без изменений.
// Всегда JsonScreen. Correlation banner для HTTP — через requestId в additionalData.
// Новые категории автоматически отображаются в JSON viewer.
// Никакого per-category рендеринга. Простота > красота.
```

### F4. Новые фильтры

```dart
// CategoryFilter и SourceFilter — в ispectify core
class CategoryFilter implements Filter<ISpectLogData> {
  const CategoryFilter(this.categories);
  final Set<String> categories;

  @override
  bool apply(ISpectLogData item) {
    final cat = item.additionalData?[TraceKeys.category] as String?;
    return cat != null && categories.contains(cat);
  }
}

class SourceFilter implements Filter<ISpectLogData> {
  const SourceFilter(this.sources);
  final Set<String> sources;

  @override
  bool apply(ISpectLogData item) {
    final src = item.additionalData?[TraceKeys.source] as String?;
    return src != null && sources.contains(src);
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

class FakeISpectLogger extends ISpectLogger {
  final traces = <ISpectLogData>[];

  @override
  void logData(ISpectLogData data) {
    traces.add(data);
    super.logData(data);
  }

  List<ISpectLogData> byCategory(String category) =>
      traces.where((t) => t.additionalData?[TraceKeys.category] == category).toList();

  List<ISpectLogData> bySource(String source) =>
      traces.where((t) => t.additionalData?[TraceKeys.source] == source).toList();

  ISpectLogData? lastByCategory(String category) {
    final list = byCategory(category);
    return list.isEmpty ? null : list.last;
  }

  void reset() => traces.clear();
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
        trace_helpers.dart            # truncateValue(), safeLogData() — top-level helpers
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
        category_filter.dart          # CategoryFilter, SourceFilter
      models/
        log_type.dart                 # ISpectLogType + category field + new values
        data.dart                     # ISpectLogData (unchanged)
      history/
        serialization.dart            # + toText(), toMarkdown() (added to existing extension)
      export/
        log_exporter.dart             # LogExporter — batch export utility (static methods)
      testing/
        fake_logger.dart              # FakeISpectLogger for tests

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
5. Icons/colors в `ISpectConstants`
6. L10n label в `_categoryLabel` (switch case через `TraceCategoryIds.my`)
7. Export barrel в `ispectify.dart`
8. Тесты

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
ISpect(theme: ISpectTheme(
  logColors: {'my-success': Colors.teal, 'my-error': Colors.red},
  logIcons: {'my-success': Icons.check, 'my-error': Icons.close},
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

Слой 3: Export (ПРИ ВЫВОДЕ)
  → toJson(truncated: true) — truncates large values
  → toText() / toMarkdown() — используют уже redacted данные из additionalData
```

**Правило:** Domain слой redacts domain-specific patterns. Trace слой — generic safety net. Export слой — truncation. Нет двойной redaction — `redactByKeys` идемпотентен (уже замаскированные значения не изменяются повторно).

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
Map<String, Object?> _preprocessDb({...}) {
  return {
    DbLogKeys.statement: ISpectDbCore.truncateValue(statement, cfg.maxStatementLength),
    DbLogKeys.statementDigest: ISpectDbCore.sqlDigest(statement),
    DbLogKeys.args: ISpectDbCore.redactPositionalArgs(args, ...),
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
Object? truncateValue(Object? value, int maxLen) { ... }
void safeLogData(ISpectLogger logger, ISpectLogData Function() builder) { ... }
```

Extension вызывает их как обычные функции:
```dart
extension ISpectTrace on ISpectLogger {
  void trace({...}) {
    final message = buildTraceMessage(source: source, ...);
    safeLogData(this, () => ISpectLogData(message, ...));
  }
}
```

### Безопасность — чеклист

| Аспект | Решение |
|---|---|
| PII в логах | `ISpectTraceConfig.redactKeys` — auto-redaction в trace(). Default: token, password, secret, authorization, cookie, etc. |
| Sensitive headers | `BaseNetworkInterceptor.redactHeaders()` — маскирует Authorization, Cookie, Set-Cookie |
| Sensitive URLs | `BaseNetworkInterceptor.redactUrl()` — маскирует query params с sensitive keys |
| SQL injection в логах | `ISpectDbCore.sqlDigest()` — нормализует SQL, заменяет литералы на `?` |
| Файлы логов на диске | App-sandboxed directory. Redaction применяется ДО записи. `FileLogHistory` пишет уже redacted данные. |
| Export/Share | `toJson()`, `toText()`, `toMarkdown()` — используют уже redacted `additionalData`. Никакого доступа к raw данным после redaction. |
| Production builds | `if (!options.enabled) return;` — zero overhead. Никакие данные не обрабатываются когда ISpect отключён. |
| Custom redaction keys | Пользователь расширяет: `ISpectTraceConfig(redactKeys: [...defaultSensitiveKeys, 'ssn', 'credit_card'])` |

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

1. Core trace primitive (trace_category, trace_category_ids, trace_categories, trace_config, trace_token, trace_keys, trace_extension, trace_message, trace_helpers, trace_stream_transformer)
2. ISpectLogType + category field + new enum values
3. ISpectLogData serialization extensions (toText, toMarkdown in existing ISpectLogDataSerialization) + LogExporter utility class
4. Domain extensions (auth, storage, push, analytics, payment, sse, grpc, graphql)
5. CategoryFilter, SourceFilter
6. FakeISpectLogger testing utility
7. Рефакторинг ispectify_db → delegates to core trace
8. Рефакторинг ispectify_bloc → uses trace()
9. Рефакторинг ispectify_dio → two trace() + logKey override
10. Рефакторинг ispectify_http → two trace() + logKey override
11. Рефакторинг ispectify_ws → trace()
12. UI: dynamic filter grouping, new icons/colors, categoryLabels, new l10n strings (categoryNetwork, categoryWebSocket, categoryAuth, etc.)
13. UI: export/share sheet
14. Тесты на всё
15. Backward compat: ISpectLogDataX convenience extensions

---

## Part M: Verification

1. `dart test` / `flutter test` — все пакеты
2. `dart analyze --fatal-infos` / `flutter analyze --fatal-infos` — все пакеты
3. Backward compat: все существующие тесты проходят
4. Export: JSON/txt/md корректно генерируются
5. UI: dynamic grouping работает, новые иконки отображаются
6. `./bash/check_version_sync.sh` + `./bash/check_dependencies.sh`
7. Example: Firebase Auth decorator → authTrace → лог в UI → фильтр по auth → JSON detail
8. Audit ALL exhaustive switch на `ISpectLogType` в кодовой базе — добавить `_` default case перед добавлением новых enum values
9. Обновить example apps — удалить ссылки на typed subclasses (`NetworkRequestLog`, `BlocEventLog`, etc.)
10. Проверить `web_logs_viewer/` — если парсит JSON из ISpect, обновить для нового `additionalData` layout
11. Обновить `version.config` → `5.0.0`, синхронизировать через `./bash/update_versions.sh`
12. Написать CHANGELOG.md с migration guide для breaking changes
13. Добавить l10n строки (`categoryNetwork`, `categoryWebSocket`, etc.) в `.arb` файлы и регенерировать
14. Обновить barrel exports `packages/ispectify/lib/ispectify.dart` — добавить все новые файлы из trace/, filter/, export/, testing/

---

## Part N: Critical Files

### New
- `packages/ispectify/lib/src/trace/trace_category.dart`
- `packages/ispectify/lib/src/trace/trace_category_ids.dart` — SSOT for category ID strings
- `packages/ispectify/lib/src/trace/trace_categories.dart`
- `packages/ispectify/lib/src/trace/trace_config.dart`
- `packages/ispectify/lib/src/trace/trace_token.dart`
- `packages/ispectify/lib/src/trace/trace_keys.dart`
- `packages/ispectify/lib/src/trace/trace_extension.dart`
- `packages/ispectify/lib/src/trace/trace_message.dart`
- `packages/ispectify/lib/src/trace/trace_helpers.dart` — truncateValue(), safeLogData()
- `packages/ispectify/lib/src/trace/trace_stream_transformer.dart`
- `packages/ispectify/lib/src/trace/extensions/*.dart` (8 files)
- `packages/ispectify/lib/src/export/log_exporter.dart`
- `packages/ispectify/lib/src/filter/category_filter.dart`
- `packages/ispectify/lib/src/testing/fake_logger.dart`

### Modified
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
- `packages/ispect/lib/src/common/services/logs_json_service.dart` — extend with text/markdown export methods (chunked processing)
- `packages/ispect/lib/src/core/res/constants/ispect_constants.dart` — new icons/colors
- `packages/ispect/lib/src/core/res/ispect_theme.dart` — + categoryLabels
- `packages/ispect/lib/src/features/ispect/presentation/widgets/settings/log_type_filter_section.dart` — dynamic grouping
- `packages/ispect/lib/src/common/services/logs_json_service.dart` — text/markdown chunked export

### Deleted (clean break v5.0)
- `packages/ispectify/lib/src/network/network_logs.dart` — BaseNetworkLog, NetworkRequestLog, NetworkResponseLog, NetworkErrorLog
- `packages/ispectify_dio/lib/src/models/` — DioRequestLog, DioResponseLog, DioErrorLog
- `packages/ispectify_http/lib/src/models/` — HTTP-specific log types
- `packages/ispectify_ws/lib/src/models/` — WSSentLog, WSReceivedLog, WSErrorLog, WSLogFields
- `packages/ispectify_bloc/lib/src/models/` — BlocLifecycleLog (sealed), BlocEventLog, BlocTransitionLog, BlocStateLog, BlocCreateLog, BlocCloseLog, BlocDoneLog, BlocErrorLog

---

## Part O: Changelog исправлений плана (review fixes applied)

1. **`enabled` → `options.enabled`** — ISpectLogger не имеет публичного `enabled`, доступ через `options.enabled`
2. **Убран `extra` из trace() API** — только `meta` для всех domain данных. Нет конфликтов ключей, нет путаницы
3. **Private helpers → top-level functions** — `buildTraceMessage()` в `trace_message.dart`, `truncateValue()` и `safeLogData()` в `trace_helpers.dart`
4. **Batch export: chunking note** — extensions для < 1000 логов, `LogsJsonService` для bulk
5. **Enum breaking change** — задокументировать в CHANGELOG, рекомендовать `_` default case
6. **Clean break v5.0** — удалить typed subclasses сразу, UI работает через additionalData fallback
7. **Убран misleading комментарий** — "только data" заменён на корректное описание
8. **Prefix heuristic** — 4-й уровень в `_resolveCategory` для backward compat кастомных keys
9. **ISpectTraceCategory comment** — исправлен на корректное описание `pickLogKey()`
10. **`ISpectDbCore.truncate` → `truncateValue`** — метод `truncate` не существует, правильное имя `truncateValue`
11. **SSOT: `TraceCategoryIds`** — category ID строки были hardcoded в 4 местах. Добавлен `TraceCategoryIds` const class. Log key строки — SSOT через `ISpectLogType.*.key`.
12. **WS отделён от network** — WebSocket получил свою категорию `ws` (был `network`). `networkCategory.pickLogKey()` возвращал `http-*` ключи для WS — баг. Теперь `wsCategory` с `sent`/`received`/`error` ключами. Добавлен `ISpectLogType.wsError`.
13. **`queryKey`/`readOperations` → `secondaryKey`/`secondaryOperations`** — generic naming, подходит для всех протоколов (HTTP: request/response, WS: sent/received, DB: query/result).
14. **`logKey` override в `trace()`** — HTTP interceptors emit ДВА лога (request + response) с разными ключами. `pickLogKey()` возвращает один ключ — недостаточно. Добавлен `logKey` parameter: `trace(..., logKey: ISpectLogType.httpRequest.key)`. `traceStart/traceEnd` остаётся для gRPC/GraphQL (один лог).
15. **Null-safety в `toMarkdown()`** — `logLevel` на `ISpectLogData` is `LogLevel?`. `logLevel.name` → NPE. Исправлено: `logLevel?.name ?? 'unknown'` и `_logLevelIndicator(LogLevel? level)`.
16. **SSOT в `ISpectLogDataX`** — `isNetwork`, `isDb`, `isAuth` использовали hardcoded строки. Исправлено: `TraceCategoryIds.network` и т.д.
17. **WS/BLoC typed subclasses** — в Part D4 и Part N добавлены `WSSentLog`, `WSReceivedLog`, `WSErrorLog`, `WSLogFields` и все BLoC subclasses (`BlocLifecycleLog` sealed + 7 subclasses) для удаления.
18. **WS icons** — Part E2 не содержал иконки для `ws-sent`, `ws-received`, `ws-error`. Добавлены.
19. **Private extension methods** — Part I.1 утверждал что Dart не поддерживает private methods в extensions. Dart 3.1+ поддерживает. Исправлен текст: helpers как top-level потому что shared между файлами, не потому что Dart не позволяет.
20. **`logKey` в traceAsync/traceSync** — добавлен параметр `logKey` (пробрасывается в `trace()`). `traceEnd` — не нуждается (one-log протоколы используют `pickLogKey`).
21. **`toJson()` конфликт extensions** — Plan C1 объявлял `toJson()` в новом `ISpectLogDataExport` extension, но `toJson()` уже существует в `ISpectLogDataSerialization` (history/serialization.dart). Два extensions с одинаковой сигнатурой = конфликт при импорте. Исправлено: `toText()` и `toMarkdown()` добавляются в существующий `ISpectLogDataSerialization` extension.
22. **`_logLevelEmoji` → `_logLevelIndicator`** — метод возвращал ASCII строки ('X', '!', 'i', 'D'), а не эмодзи. Переименован и значения заменены на `[ERROR]`, `[WARN]`, `[INFO]`, `[DEBUG]`, `[-]` для читаемости в markdown.
23. **Zone txnId не читался в `trace()`** — `traceTransaction()` ставил `zoneValues: {#ispectTxnId: txnId}`, но `trace()` не читал его. Все inner trace вызовы внутри транзакции теряли корреляцию. Исправлено: `trace()` теперь читает `Zone.current[#ispectTxnId]` и auto-inject в `additionalData[TraceKeys.transactionId]`.
24. **`traceSync` body отсутствовал** — был заглушкой `/* same pattern, synchronous */`. Добавлена полная реализация с `Stopwatch`, `projectResult` try/catch, `rethrow`.
25. **Fire-and-forget extensions не пробрасывали `config`** — `auth()`, `push()`, `sse()`, `analyticsEvent()` вызывали `trace()` без `config` parameter. Async варианты (через `traceAsync`) пробрасывали. Исправлено: добавлен `ISpectTraceConfig? config` во все fire-and-forget domain extensions.
26. **Batch export: extension на `List<T>` → utility class** — `ISpectLogListExport` extension на `List<ISpectLogData>` был доступен на ЛЮБОМ списке, рискуя случайным вызовом на 50K+ записях. Заменён на `abstract final class LogExporter` со static методами: `LogExporter.toText(logs)`, `LogExporter.toJsonLines(logs)`, `LogExporter.toMarkdown(logs)`.
27. **Part P verification table расширена** — добавлены проверки: `toJson()` (extension, не метод), `samplePass()`, `generateTraceId()`, `BaseNetworkInterceptor` (mixin), `defaultSensitiveKeys`, `Filter<T>`, `formattedTime`. Все с точными файлами и статусами.
28. **`redactKeys` тип `List<String>` → `Set<String>`** — `defaultSensitiveKeys` это `const Set<String>`. Нельзя использовать Set как default для List в const конструкторе. Тип `redactKeys` изменён на `Set<String>`. В `trace()` вызов `RedactionService.redactByKeys(meta, cfg.redactKeys.toList())` — `.toList()` для совместимости с API.
29. **NetworkTransaction fallback keys не совпадали с trace layout** — Текущие fallback getters читают `additionalData['method']`, `['url']`, `['statusCode']` на top-level. Но trace pipeline кладёт: `operation` (не `method`) на top-level, `target` (не `url`) на top-level, `statusCode` вложен в `meta` (не top-level). Без исправления NetworkTransaction сломается после рефакторинга. Обновлены: `method` → `TraceKeys.operation`, `url` → `TraceKeys.target`, `statusCode` → `meta['statusCode']`. Также обновлен `network_transaction_service.dart` для `requestId` из `meta`. Добавлены в Part N Modified files. Тест в Part G обновлён с новым layout.
30. **`ISpectTraceConfig` не `final class`** — намеренно: `ISpectDbConfig extends ISpectTraceConfig` (Part D1). LSP соблюдён. Задокументировано.
31. **`ISpectTraceToken._()` приватный конструктор** — `trace_token.dart` и `trace_extension.dart` — разные файлы (нет `part`/`part of` в ispectify). Приватный конструктор `._()` недоступен из другого файла. Конструктор сделан публичным: `ISpectTraceToken({...})`. Класс `final` — не может быть subclassed, публичный конструктор безопасен.
32. **`requestId` key: `'request-id'` → `'requestId'`** — текущий код использует `kRequestIdKey = 'request-id'` (kebab-case) в `network_logs.dart`. Этот файл удаляется в clean break. План использует `'requestId'` (camelCase) в meta Dio interceptor'а. `NetworkTransactionService._extractRequestId()` обновляется на `ISpectLogDataX.requestId` (читает из `traceMeta?['requestId']`).
33. **Новые l10n строки** — `_categoryLabel()` в Part F1 ссылается на `l10n.categoryNetwork`, `l10n.categoryWebSocket`, `l10n.categoryAuth`, `l10n.categoryStorage`, `l10n.categoryPush`, `l10n.categoryAnalytics`, `l10n.categoryPayment`, `l10n.categoryNavigation`, `l10n.categorySse`, `l10n.categoryGrpc`, `l10n.categoryGraphql`, `l10n.categoryDb`, `l10n.categoryState`. Нужно добавить в `ISpectGeneratedLocalization` и все locale-файлы.
34. **`_shouldLog()` signature в BLoC D3** — план показывал `_shouldLog(bloc)` (single argument), но реальная сигнатура `_shouldLog({required bool toggle, required Object? candidate})`. Исправлено на `_shouldLog(toggle: settings.printEvents, candidate: bloc)`. Тип `Bloc` → `Bloc<dynamic, dynamic>`.
35. **`slowQueryThreshold` → `slowThreshold`** — текущий `ISpectDbConfig.slowQueryThreshold` переименовывается в `super.slowThreshold` при наследовании от `ISpectTraceConfig`. Breaking change — задокументировать в migration guide. Unified naming для всех категорий (не только DB).
36. **`const` → `final` для predefined categories** — В Dart `EnumValue.field` (напр. `ISpectLogType.httpResponse.key`) НЕ является compile-time constant expression. `const networkCategory = ISpectTraceCategory(successKey: ISpectLogType.httpResponse.key)` не компилируется. Исправлено: все 13 predefined categories и пользовательские примеры используют `final` вместо `const`. `final` top-level переменные — lazy init, single init, immutable.
37. **Zone cast safety** — `Zone.current[#ispectTxnId] as String?` бросает `CastException` если zone value не String. Заменено на defensive: `final raw = Zone.current[#ispectTxnId]; final txnId = raw is String ? raw : null;`.
38. **Transaction marker txnId redundancy** — Маркеры (begin/commit/rollback) передавали `meta: {TraceKeys.transactionId: txnId}`, но `trace()` уже auto-inject txnId из zone в top-level `additionalData['transactionId']`. Результат: txnId в двух местах. Исправлено: убран из meta маркеров, zone auto-inject достаточен.
39. **`correlationId` — универсальная корреляция для всех протоколов** — Добавлен `correlationId` параметр во все trace методы (trace, traceAsync, traceSync, traceStart/End, traceStream). `TraceKeys.correlationId` и `ISpectLogDataX.traceCorrelationId` getter. HTTP: requestId передаётся как correlationId (request↔response linked). Streams: auto-generated correlationId связывает subscribe/event/unsubscribe/error. gRPC/GraphQL: пользователь может передать для cross-call correlation. Isolate-safe: не зависит от Zone, передаётся явно.
40. **Prefix heuristic documentation** — `_resolveCategory` heuristic задокументирован: keys с built-in prefix (e.g. `db-custom`) auto-group в соответствующую категорию. Override через `theme.logCategories` (приоритет 1).
41. **Zone isolate boundary warning** — Документировано что zone values (transactionId) не пересекают isolate boundaries. Для cross-isolate correlation использовать explicit `correlationId`.
42. **ISpectLogType enum best practice** — Рекомендация: использовать `logType.category == TraceCategoryIds.network` вместо exhaustive switch. Стабильнее при добавлении новых values.
43. **Meta guidelines** — Документированы: descriptive keys, избегать конфликтов с TraceKeys, cross-isolate correlation.
44. **Async domain extensions: `config` + `correlationId`** — `authTrace`, `storageTrace`, `paymentTrace`, `grpcTrace`, `graphqlTrace` не принимали `config` и `correlationId`. Fire-and-forget варианты (`auth()`, `push()`, `sse()`, `analyticsEvent()`) имели `config`, но async — нет. Исправлено: добавлены `ISpectTraceConfig? config` и `String? correlationId` во все 5 async domain extensions, проброшены в `traceAsync()`.
45. **`logs_json_service.dart` в Part N Modified** — Plan C2 описывает расширение `LogsJsonService` поддержкой text/markdown форматов, но файл не был в Part N Modified. Добавлен.

---

## Part P: Финальная верификация (deep audit)

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
| `defaultSensitiveKeys` | Да | redaction/constants/key_defaults.dart | OK — `Set<String>` с 118 записями |
| `Filter<T>` interface | Да | filter/filter.dart | OK — abstract class с `bool apply(T item)` |
| `ISpectLogData.formattedTime` | Да | models/data.dart:68 | OK — late final getter |

### UI clean break — все компоненты проверены:

| Компонент | Зависит от typed subclasses? | Fallback через additionalData? | Статус |
|---|---|---|---|
| LogCard | Нет (кроме `is RouteLog`) | Да | SAFE |
| CollapsedBody | Нет — получает statusCode через параметр | Да, но вызывающий код (LogCard, DesktopLogRow) читает `additionalData?['statusCode']` на top-level → **ОБНОВИТЬ** на `(additionalData?[TraceKeys.meta] as Map?)?['statusCode']` | NEEDS UPDATE |
| NetworkTransactionCard | Нет напрямую — через NetworkTransaction | Да — fallback в getters | SAFE |
| NetworkTransaction | Да — type checks, НО с fallback | **ОБНОВИТЬ**: fallback keys не совпадают с trace layout (method→operation, url→target, statusCode→meta.statusCode). Getters нужно переписать | NEEDS UPDATE |
| LogDetailView | Нет — key-based correlation | N/A | SAFE |
| ShareLogBottomSheet | Нет — работает с Map | N/A | SAFE |
| ShareAllLogsSheet | Нет — `.toJson()` | N/A | SAFE |
| LogExportService | Нет — delegates | N/A | SAFE |
| LogsJsonService | Нет — `.toJson()` / `fromJson()` | N/A | SAFE |
| LogTypeFilterSection | Нет — prefix matching | N/A | SAFE |
| CurlCommand | Нет — extension на ISpectLogData через additionalData + key | N/A | SAFE |
| `message` property | Нет — поле на ISpectLogData | N/A | SAFE |

### Важные детали:
- `curlCommand` — extension getter на `ISpectLogData` (data_extensions.dart:84), работает через `key` + `additionalData`. НЕ зависит от typed subclasses.
- `message` — поле `String?` на `ISpectLogData` (data.dart:35). Доступно всегда.
- `NetworkTransaction.statusCode/method/url` — **ОБНОВИТЬ fallback getters:** текущие читают `['method']`, `['url']`, `['statusCode']` на top-level. Trace pipeline кладёт `operation`/`target` на top-level, а `statusCode` в nested `meta`. Новые getters: `method` → `TraceKeys.operation`, `url` → `TraceKeys.target`, `statusCode` → `meta['statusCode']`.
- `network_transaction_service.dart` — hybrid checks: `log is NetworkRequestLog || log.key == ISpectLogType.httpRequest.key`. После удаления subclasses — всегда fallback на key. Работает. `requestId` extraction: обновить на `(log.additionalData?[TraceKeys.meta] as Map?)?['requestId']`.

### Безопасность — подтверждено:
- Redaction в 3 слоя без дублирования (domain → trace pipeline → export truncation)
- `redactByKeys` идемпотентен — повторный вызов на уже замаскированных данных безопасен
- Default sensitive keys: token, password, secret, authorization, cookie, session, apikey, etc.
- Production: `if (!options.enabled) return;` — zero data processing
- File logs: app-sandboxed, данные redacted ДО записи
- Export: использует уже redacted additionalData

### Нет дублирования — подтверждено:
- Один `trace()` pipeline для всех доменов
- Domain extensions ~20 строк каждый, делегируют в trace()
- `_preprocessDb()` — единственное место DB preprocessing
- `BaseNetworkInterceptor` — единственное место network redaction
- `buildTraceMessage()` — единственный message formatter
