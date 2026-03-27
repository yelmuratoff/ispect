# Universal Trace Architecture for ispectify — Final Plan

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

> **Почему нет `messageBuilder`:** Message formatting — в trace pipeline через единый `buildTraceMessage()` (top-level function в `trace_helpers.dart`). Не нужен per-category — message это одна строка в списке, а детали всегда в JSON viewer.

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

const networkCategory = ISpectTraceCategory(
  id: TraceCategoryIds.network,
  successKey: ISpectLogType.httpResponse.key,
  errorKey: ISpectLogType.httpError.key,
  secondaryKey: ISpectLogType.httpRequest.key,
  secondaryOperations: {'GET', 'HEAD', 'OPTIONS'},
);

const dbCategory = ISpectTraceCategory(
  id: TraceCategoryIds.db,
  successKey: ISpectLogType.dbResult.key,
  errorKey: ISpectLogType.dbError.key,
  secondaryKey: ISpectLogType.dbQuery.key,
  secondaryOperations: {'query', 'get', 'select', 'find', 'count', 'list'},
);

const authCategory = ISpectTraceCategory(
  id: TraceCategoryIds.auth,
  successKey: ISpectLogType.authSuccess.key,
  errorKey: ISpectLogType.authError.key,
);

const wsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.ws,
  successKey: ISpectLogType.wsReceived.key,  // receive → default success
  errorKey: ISpectLogType.wsError.key,       // error
  secondaryKey: ISpectLogType.wsSent.key,    // send → secondary
  secondaryOperations: {'send'},
);

const sseCategory = ISpectTraceCategory(
  id: TraceCategoryIds.sse,
  successKey: ISpectLogType.sseReceived.key,
  errorKey: ISpectLogType.sseError.key,
);

const storageCategory = ISpectTraceCategory(
  id: TraceCategoryIds.storage,
  successKey: ISpectLogType.storageResult.key,
  errorKey: ISpectLogType.storageError.key,
  secondaryKey: ISpectLogType.storageQuery.key,
  secondaryOperations: {'download', 'list', 'getUrl', 'getMetadata'},
);

const stateCategory = ISpectTraceCategory(
  id: TraceCategoryIds.state,
  successKey: ISpectLogType.stateChange.key,
  errorKey: ISpectLogType.stateError.key,
);

const pushCategory = ISpectTraceCategory(
  id: TraceCategoryIds.push,
  successKey: ISpectLogType.pushReceived.key,
  errorKey: ISpectLogType.pushError.key,
);

const analyticsCategory = ISpectTraceCategory(
  id: TraceCategoryIds.analytics,
  successKey: ISpectLogType.analytics.key,
  errorKey: ISpectLogType.analytics.key,
);

const paymentCategory = ISpectTraceCategory(
  id: TraceCategoryIds.payment,
  successKey: ISpectLogType.paymentSuccess.key,
  errorKey: ISpectLogType.paymentError.key,
);

const navigationCategory = ISpectTraceCategory(
  id: TraceCategoryIds.navigation,
  successKey: ISpectLogType.route.key,
  errorKey: ISpectLogType.route.key,
);

const grpcCategory = ISpectTraceCategory(
  id: TraceCategoryIds.grpc,
  successKey: ISpectLogType.grpcResponse.key,
  errorKey: ISpectLogType.grpcError.key,
  secondaryKey: ISpectLogType.grpcRequest.key,
  secondaryOperations: {'unary', 'serverStreaming'},
);

const graphqlCategory = ISpectTraceCategory(
  id: TraceCategoryIds.graphql,
  successKey: ISpectLogType.graphqlResponse.key,
  errorKey: ISpectLogType.graphqlError.key,
  secondaryKey: ISpectLogType.graphqlRequest.key,
  secondaryOperations: {'query', 'subscription'},
);
```

> **SSOT:** Category ID → `TraceCategoryIds`. Log key → `ISpectLogType.*.key`. Одно место правды.
> **Новые категории:** `const myCategory = ISpectTraceCategory(id: 'xxx', ...)`. Пользователь использует свои строки — нет ограничений.
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
    this.redactKeys = defaultSensitiveKeys,
    this.maxValueLength = 500,
    this.attachStackOnError = false,
    this.slowThreshold,
  });

  final double? sampleRate;         // % success операций для логирования
  final double errorSampleRate;     // % error операций (default: все)
  final bool redact;
  final List<String> redactKeys;
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

final class ISpectTraceToken {
  ISpectTraceToken._({
    required Stopwatch stopwatch,
    required this.category,
    required this.source,
    required this.operation,
    this.target,
    this.key,
    this.meta,
    this.config,
  }) : _stopwatch = stopwatch;

  final Stopwatch _stopwatch;
  final ISpectTraceCategory category;
  final String source;
  final String operation;
  final String? target;
  final String? key;
  final Map<String, Object?>? meta;
  final ISpectTraceConfig? config;

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
  }) {
    if (!options.enabled) return;  // ← zero overhead в production

    final cfg = config ?? const ISpectTraceConfig();
    final isError = error != null || success == false;

    if (!cfg.shouldLog(localSample: sample, isError: isError)) return;

    final resolvedLogKey = logKey ?? category.pickLogKey(isError: isError, operation: operation);

    // Единый формат: [source] operation → target (duration)
    // NB: buildTraceMessage — top-level function из trace_helpers.dart
    final message = buildTraceMessage(
      source: source, operation: operation,
      target: target, key: key, duration: duration,
      success: !isError,
    );

    // Auto-redaction meta по config.redactKeys
    final safeMeta = cfg.redact
        ? RedactionService.redactByKeys(meta, cfg.redactKeys)
        : meta;

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
      );
      return result;
    } catch (e, st) {
      sw.stop();
      trace(
        category: category, source: source, operation: operation,
        target: target, key: key, error: e, errorStackTrace: st,
        success: false, duration: sw.elapsed,
        meta: meta, config: cfg, sample: sample, logKey: logKey,
      );
      rethrow;
    }
  }

  // ── Sync wrapper ────────────────────────────────────
  T traceSync<T>({
    // same params as traceAsync but sync (no extra)
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
  }) { /* same pattern, synchronous — пробрасывает logKey в trace() */ }

  // ── Manual span (request → response) ────────────────
  ISpectTraceToken traceStart({
    required ISpectTraceCategory category,
    required String source,
    required String operation,
    String? target,
    String? key,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
  }) => ISpectTraceToken._(
    stopwatch: Stopwatch()..start(),
    category: category, source: source, operation: operation,
    target: target, key: key, meta: meta, config: config,
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
  }) {
    if (!options.enabled) return stream;  // zero overhead

    // Pure Dart StreamTransformer (см. A7 ниже)
    return stream.transform(TraceStreamTransformer<T>(
      onListen: () => trace(
        category: category, source: source,
        operation: '$operation.subscribe', target: target,
        success: true, config: config,
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
          sample: sample, config: config,
        );
      },
      onError: (e, st) => trace(
        category: category, source: source,
        operation: '$operation.error', target: target,
        error: e, errorStackTrace: st, success: false,
        config: config,
      ),
      onCancel: () => trace(
        category: category, source: source,
        operation: '$operation.unsubscribe', target: target,
        success: true, config: config,
      ),
    ));
  }

  // ── Transaction (zone-based ID) ─────────────────────
  Future<T> traceTransaction<T>({
    required ISpectTraceCategory category,
    required String source,
    required Future<T> Function() run,
    bool logMarkers = false,
  }) async {
    final txnId = generateTraceId();
    return runZoned(
      () async {
        if (logMarkers) {
          trace(category: category, source: source,
            operation: 'transaction-begin', success: true,
            meta: {TraceKeys.transactionId: txnId});
        }
        try {
          final result = await run();
          if (logMarkers) {
            trace(category: category, source: source,
              operation: 'transaction-commit', success: true,
              meta: {TraceKeys.transactionId: txnId});
          }
          return result;
        } catch (e, st) {
          if (logMarkers) {
            trace(category: category, source: source,
              operation: 'transaction-rollback', error: e,
              errorStackTrace: st, success: false,
              meta: {TraceKeys.transactionId: txnId});
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
  }) => traceAsync(
    category: authCategory,
    source: source,
    operation: operation,
    key: userId,
    meta: {if (provider != null) 'provider': provider, ...?meta},
    run: run,
    projectResult: projectResult,
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
  }) => trace(
    category: authCategory,
    source: source,
    operation: operation,
    key: userId,
    success: success,
    error: error,
    duration: duration,
    meta: {if (provider != null) 'provider': provider, ...?meta},
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
  }) => traceAsync(
    category: storageCategory,
    source: source, operation: operation,
    target: path,
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
  }) => trace(
    category: analyticsCategory,
    source: source, operation: event,
    meta: parameters, success: true,
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
  }) => trace(
    category: sseCategory,
    source: source, operation: operation,
    target: url, key: eventId,
    meta: {
      if (eventType != null) 'eventType': eventType,
      if (data != null) 'data': data,
    },
    success: operation != 'error',
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
  }) => traceAsync(
    category: graphqlCategory,
    source: source, operation: operation,
    target: operationName,
    meta: {
      if (document != null) 'document': document,
      if (variables != null) 'variables': variables,
    },
    run: run, projectResult: projectResult,
  );
}
```

---

## Part C: Log Entity — конвертация и экспорт

### C1. `ISpectLogData` — расширение для экспорта

Существующий `ISpectLogData.toJson()` уже есть. Добавляем конвертацию в другие форматы:

```dart
/// Расширяем ISpectLogData (в ispectify core):

extension ISpectLogDataExport on ISpectLogData {

  /// JSON — уже есть (toJson()). Используется для файлового экспорта и web viewer.
  Map<String, dynamic> toJson({bool truncated = false});

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
      ..writeln('### ${_logLevelEmoji(logLevel)} `$key` — $message')
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

  String _logLevelEmoji(LogLevel? level) => switch (level) {
    LogLevel.error || LogLevel.critical => 'X',
    LogLevel.warning => '!',
    LogLevel.info => 'i',
    LogLevel.debug => 'D',
    _ => '-',
  };
}
```

### C2. Batch export — список логов

> **NB:** Extensions ниже — convenience для малых наборов (< 1000 логов).
> Для bulk export в UI — использовать существующий `LogsJsonService` с chunked processing,
> расширив его поддержкой text/markdown форматов (yield каждые 50 items).

```dart
extension ISpectLogListExport on List<ISpectLogData> {

  /// Export as JSON Lines (одна строка = один лог)
  String toJsonLines() => map((log) => jsonEncode(log.toJson())).join('\n');

  /// Export as plain text
  String toTextReport() {
    final buffer = StringBuffer()
      ..writeln('=== ISpect Log Report ===')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Total entries: $length')
      ..writeln('---');
    for (final log in this) {
      buffer.writeln(log.toText());
    }
    return buffer.toString();
  }

  /// Export as Markdown
  String toMarkdownReport() {
    final buffer = StringBuffer()
      ..writeln('# ISpect Log Report')
      ..writeln()
      ..writeln('> Generated: ${DateTime.now().toIso8601String()} | Entries: $length')
      ..writeln();
    for (final log in this) {
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
class ISpectDbConfig extends ISpectTraceConfig {
  const ISpectDbConfig({
    super.sampleRate,
    super.errorSampleRate,
    super.redact,
    super.redactKeys,
    super.maxValueLength,
    super.attachStackOnError,
    super.slowThreshold,
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
    logKey: ISpectLogType.httpRequest.key,  // ← explicit override
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
    logKey: ISpectLogType.httpResponse.key,  // ← explicit override
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
void onEvent(Bloc bloc, Object? event) {
  super.onEvent(bloc, event);
  if (!_shouldLog(bloc) || !settings.printEvents) return;

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
- `NetworkTransaction` — корреляция request/response через `additionalData['request-id']`
- Convenience extensions для доступа к trace данным:

```dart
extension ISpectLogDataX on ISpectLogData {
  String? get traceCategory => additionalData?[TraceKeys.category] as String?;
  String? get traceSource => additionalData?[TraceKeys.source] as String?;
  String? get traceOperation => additionalData?[TraceKeys.operation] as String?;
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
// Использует ISpectLogDataExport extensions из Part C.
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
        data.dart                     # ISpectLogData + toText(), toMarkdown() extensions
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
2. `const myCategory = ISpectTraceCategory(id: TraceCategoryIds.my, ...)` в `trace_categories.dart`
3. Extension method в `trace/extensions/my_extension.dart`
4. `ISpectLogType` enum values с `category: TraceCategoryIds.my`
5. Icons/colors в `ISpectConstants`
6. L10n label в `_categoryLabel` (switch case через `TraceCategoryIds.my`)
7. Export barrel в `ispectify.dart`
8. Тесты

### Для пользователя библиотеки:

```dart
// 1. Определить категорию:
const myCategory = ISpectTraceCategory(
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
```

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
// packages/ispectify/lib/src/trace/trace_helpers.dart
// Top-level private functions (library-private, видны только внутри src/trace/)

String buildTraceMessage({...}) { ... }  // из trace_message.dart
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
| **SSOT** | Category IDs → `TraceCategoryIds`. Log keys → `ISpectLogType.*.key`. Config → один `ISpectTraceConfig`. Message format → один `buildTraceMessage()` |
| **Strategy** | pickLogKey() — стратегия выбора log key |
| **Template Method** | traceAsync — template: check enabled → start timer → run → project → log |
| **Decorator** | BaaS wrappers: implement SDK interface, delegate, trace terminal ops |
| **Observer** | BLoC/Riverpod observers |
| **DRY** | Один trace() pipeline. Domain extensions ~20 строк, не copy-paste. Нет дублирования строковых литералов — все через const |
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

1. Core trace primitive (trace_category, trace_config, trace_token, trace_keys, trace_extension, trace_message, trace_stream_transformer)
2. ISpectLogType + category field + new enum values
3. ISpectLogData export extensions (toText, toMarkdown, batch export)
4. Domain extensions (auth, storage, push, analytics, payment, sse, grpc, graphql)
5. CategoryFilter, SourceFilter
6. FakeISpectLogger testing utility
7. Рефакторинг ispectify_db → delegates to core trace
8. Рефакторинг ispectify_bloc → uses trace()
9. Рефакторинг ispectify_dio → two trace() + logKey override
10. Рефакторинг ispectify_http → two trace() + logKey override
11. Рефакторинг ispectify_ws → trace()
12. UI: dynamic filter grouping, new icons/colors, categoryLabels
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
- `packages/ispectify/lib/src/trace/trace_stream_transformer.dart`
- `packages/ispectify/lib/src/trace/extensions/*.dart` (8 files)
- `packages/ispectify/lib/src/filter/category_filter.dart`
- `packages/ispectify/lib/src/testing/fake_logger.dart`

### Modified
- `packages/ispectify/lib/src/models/log_type.dart` — category field + new values
- `packages/ispectify/lib/src/models/data.dart` — toText(), toMarkdown() extensions
- `packages/ispectify/lib/ispectify.dart` — barrel exports
- `packages/ispectify_db/lib/src/db_logger.dart` — delegate to core trace
- `packages/ispectify_db/lib/src/config.dart` — extends ISpectTraceConfig
- `packages/ispectify_db/lib/src/db_token.dart` — wraps ISpectTraceToken
- `packages/ispectify_bloc/lib/src/observer.dart` — use trace()
- `packages/ispectify_dio/lib/src/interceptor.dart` — two trace() + logKey
- `packages/ispectify_http/lib/src/interceptor.dart` — two trace() + logKey
- `packages/ispectify_ws/lib/src/interceptor.dart` — trace()
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
3. **Private helpers → top-level functions** — `buildTraceMessage()`, `truncateValue()`, `safeLogData()` в `trace_helpers.dart`
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
15. **Null-safety в `toMarkdown()`** — `logLevel` на `ISpectLogData` is `LogLevel?`. `logLevel.name` → NPE. Исправлено: `logLevel?.name ?? 'unknown'` и `_logLevelEmoji(LogLevel? level)`.
16. **SSOT в `ISpectLogDataX`** — `isNetwork`, `isDb`, `isAuth` использовали hardcoded строки. Исправлено: `TraceCategoryIds.network` и т.д.
17. **WS/BLoC typed subclasses** — в Part D4 и Part N добавлены `WSSentLog`, `WSReceivedLog`, `WSErrorLog`, `WSLogFields` и все BLoC subclasses (`BlocLifecycleLog` sealed + 7 subclasses) для удаления.
18. **WS icons** — Part E2 не содержал иконки для `ws-sent`, `ws-received`, `ws-error`. Добавлены.
19. **Private extension methods** — Part I.1 утверждал что Dart не поддерживает private methods в extensions. Dart 3.1+ поддерживает. Исправлен текст: helpers как top-level потому что shared между файлами, не потому что Dart не позволяет.
20. **`logKey` в traceAsync/traceSync** — добавлен параметр `logKey` (пробрасывается в `trace()`). `traceEnd` — не нуждается (one-log протоколы используют `pickLogKey`).

---

## Part P: Финальная верификация (deep audit)

### API compatibility — все вызовы из плана верифицированы:

| API call в плане | Существует | Файл | Статус |
|---|---|---|---|
| `ISpectLogData(message, key:, logLevel:, additionalData:, ...)` | Да | models/data.dart | OK — positional message, unmodifiable additionalData |
| `cleanMap(additionalData)` | Да | utils/common_utils.dart | OK — убирает null и пустые строки |
| `RedactionService.redactByKeys(meta, keys)` | Да | redaction/redaction_service.dart | OK — static, case-insensitive |
| `ISpectLogType.fromKey(key)` | Да | models/log_type.dart | OK — static lookup, nullable |
| `LogLevel.error`, `LogLevel.info` | Да | models/log_level.dart | OK |
| `ISpectLogger.logData(data)` | Да | ispectify.dart | OK — public, can override |
| `options.enabled` | Да | ispectify.dart + options.dart | OK — public getter → public field |
| `ISpectDbCore.truncateValue(value, maxLen)` | Да | db_core.dart:66 | OK |
| `ISpectDbCore.sqlDigest(statement)` | Да | db_core.dart:46 | OK |
| `ISpectDbCore.redactPositionalArgs(args, keys, stmt)` | Да | db_core.dart:97 | OK |

### UI clean break — все компоненты проверены:

| Компонент | Зависит от typed subclasses? | Fallback через additionalData? | Статус |
|---|---|---|---|
| LogCard | Нет (кроме `is RouteLog`) | Да | SAFE |
| CollapsedBody | Нет | Да — `additionalData?['statusCode']` | SAFE |
| NetworkTransactionCard | Нет напрямую — через NetworkTransaction | Да — fallback в getters | SAFE |
| NetworkTransaction | Да — type checks, НО с fallback | Да — lines 51-66 | SAFE |
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
- `NetworkTransaction.statusCode/method/url` — имеют typed check + additionalData fallback. После удаления subclasses будут использовать только fallback. Работает.
- `network_transaction_service.dart` — hybrid checks: `log is NetworkRequestLog || log.key == ISpectLogType.httpRequest.key`. После удаления subclasses — всегда fallback на key. Работает.

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
