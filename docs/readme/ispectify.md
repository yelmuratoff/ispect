<!-- partial:header -->

**ispectify** is the logging backbone of the [ISpect toolkit](#the-ispect-toolkit). Pure Dart, no Flutter — usable in CLI tools, server-side Dart, and shared business-logic packages.

- Typed log entries with explicit severity levels and log-type keys.
- Filtering, in-memory history, and custom truncation.
- Trace extensions for async / sync / stream operations with timing and outcome tagging.
- Observer hooks to forward selected events into internal tools through your own adapter.
- Built-in [redaction engine](#data-redaction) shared across the `ispectify_*` interceptor packages.

## Install

```yaml
dependencies:
  ispectify: ^{{version}}
```

## Quick start

```dart
import 'package:ispectify/ispectify.dart';

final logger = ISpectLogger();

logger.info('Application started');
logger.warning('Cache miss — falling back to network');
logger.error('Payment gateway returned 502', exception, stackTrace);
```

Custom log types:

```dart
logger.log(
  'User signed in',
  logLevel: LogLevel.info,
  type: const ISpectLogType('auth'),
);
```

## Configuration

```dart
final logger = ISpectLogger(
  options: ISpectLoggerOptions(
    enabled: true,
    useHistory: true,
    useConsoleLogs: true,
    maxHistoryItems: 5000,
    logTruncateLength: 4000,
  ),
);
```

**Streaming-only** (no in-memory history — useful when every event is forwarded to an observer):

```dart
final logger = ISpectLogger(
  options: const ISpectLoggerOptions(useHistory: false),
);
```

**Filter by log-type key** (suppress noisy categories without changing call sites):

```dart
final logger = ISpectLogger(
  filter: ISpectFilter(logTypeKeys: {'analytics', 'route'}),
);
```

**Filter by level** (drop `debug`/`verbose`, keep `info` and above):

```dart
final logger = ISpectLogger(
  logger: ISpectBaseLogger(
    filter: LogLevelRangeFilter(minLevel: LogLevel.info),
  ),
);
```

## Tracing

Trace extensions wrap work in a start/end log pair with duration, outcome, and optional result projection — so you can see one-line "did this domain action succeed?" entries in the log viewer.

```dart
final users = await logger.traceAsync<List<User>>(
  source: 'user_repository',
  operation: 'fetch_list',
  run: () => userRepository.fetchAll(),
  projectResult: (list) => {'count': list.length},
);
```

Also available: `traceSync`, `traceStream`. Each reports duration, exception, and stack trace on failure.

## Observers

Observers receive every log event in real time — attach one per external sink:

```dart
class GrafanaObserver extends ISpectObserver {
  const GrafanaObserver();

  @override
  void onLog(ISpectLogData data) { /* ship to Loki */ }

  @override
  void onError(ISpectLogData err) { /* ship to Loki */ }

  @override
  void onException(ISpectLogData err) { /* ship to Loki */ }
}

logger.addObserver(const GrafanaObserver());
```

<!-- partial:redaction -->

## Security

Exported logs are plain-text JSON. Never write PII (emails, phone numbers, tokens) directly via `logger.info(...)` — rely on the redaction engine when values flow through network interceptors, and sanitize user input before logging it manually. See [`docs/SECURITY.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md) for the recommended data-handling policy.

<!-- partial:install_matrix -->

<!-- partial:footer -->
