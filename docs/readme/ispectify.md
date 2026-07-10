<!-- partial:header -->

`ispectify` is the logging core of the [ISpect toolkit](#the-ispect-toolkit). Pure Dart, no Flutter dependency. Use it in CLI tools, server-side Dart, and shared business-logic packages.

- Typed log entries with explicit severity levels and log-type keys.
- Filtering, bounded in-memory history, and configurable truncation.
- Trace extensions for async, sync, and stream operations with timing and outcome tagging.
- Observer hooks that forward selected events to your own sink.
- A built-in [redaction engine](#data-redaction) shared with the `ispectify_*` interceptor packages.

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
logger.warning('Cache miss, falling back to network');
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

Streaming-only, with no in-memory history. Use this when every event is forwarded to an observer:

```dart
final logger = ISpectLogger(
  options: const ISpectLoggerOptions(useHistory: false),
);
```

Filter by log-type key. Suppress noisy categories without changing call sites:

```dart
final logger = ISpectLogger(
  filter: ISpectFilter(logTypeKeys: {'analytics', 'route'}),
);
```

Filter by level. Drop `debug` and `verbose`, keep `info` and above:

```dart
final logger = ISpectLogger(
  logger: ISpectBaseLogger(
    filter: LogLevelRangeFilter(minLevel: LogLevel.info),
  ),
);
```

### Rolling file history

On Dart IO platforms, opt into bounded JSON Lines persistence by supplying a cache directory owned by your application:

```dart
final loggerOptions = ISpectLoggerOptions(maxHistoryItems: 10_000);
final history = RollingFileLogHistory(
  loggerOptions,
  directoryProvider: () async => '/path/to/application-cache',
  options: const FileLogHistoryOptions(
    maxSessionDays: 7,
    maxFileSize: 5 * 1024 * 1024,
    maxTotalSize: 50 * 1024 * 1024,
  ),
);
final logger = ISpectLogger(options: loggerOptions, history: history);
```

Records are redacted before they reach disk, grouped into daily rolling segments, and deduplicated by log ID. Retention can delete the oldest or largest closed segments, or GZIP old segments with `SessionCleanupStrategy.archiveOldest`. Legacy 4.x daily JSON arrays remain readable. The implementation stays inert unless `ISPECT_ENABLED` is present; web consumers should keep the default in-memory history.

Disabling the global `ISpectRedaction.enabled` switch is an explicit opt-out that also disables redaction before file persistence and JSON export.

## Console output

Console entries use a compact, single-line format by default. Switch to a boxed format — each entry framed for visual separation in a busy console — by setting `ConsoleSettings.formatter`:

```dart
final logger = ISpectLogger(
  logger: ISpectBaseLogger(
    settings: ConsoleSettings(formatter: const BoxedLogEntryFormatter()),
  ),
);
```

```text
┌──────────────────────────────────────────────
│ INFO    [route] | 17:20:42.910 | Push | / → /detail
└──────────────────────────────────────────────
```

The boxed formatter renders the same fields as the default (so redaction and network bodies carry over), and the border glyph and width follow `ConsoleSettings.lineSymbol` / `maxLineWidth`. Implement `ILogEntryFormatter` for a fully custom layout; the default is the compact `HumanLogEntryFormatter`.

By default, entries are written with `print` (browser console on web). To route them through `dart:developer` instead — so they appear in the DevTools logging view with structured metadata — pass the `developerLogOutput` sink:

```dart
final logger = ISpectLogger(
  logger: ISpectBaseLogger(
    output: developerLogOutput,
    settings: ConsoleSettings(formatter: const BoxedLogEntryFormatter()),
  ),
);
```

Each entry becomes a single `log()` call, so multi-line boxed output stays intact, and the log level is mapped through. Messages arrive colored when `ConsoleSettings.enableColors` is on; if your log viewer shows ANSI codes as raw escape sequences, pair it with `enableColors: false`. Flutter apps initialized via `ISpect.run` / `ISpectFlutter.init()` already use a platform-adaptive output (`dart:developer` on iOS/macOS, `print` elsewhere); `developerLogOutput` is for code that wires `ISpectBaseLogger` directly, or any custom `LoggerOutput`.

## Tracing

Trace extensions wrap work in a paired start/end log entry with duration, outcome, and an optional result projection. You get one-line "did this domain action succeed?" entries in the log viewer instead of a flood of unrelated logs.

Each trace call takes an `ISpectTraceCategory`. Pre-built ones (`networkCategory`, `dbCategory`, `authCategory`, `storageCategory`, `paymentCategory`, and the rest) live in `package:ispectify/ispectify.dart`, or you can declare your own.

```dart
const userRepoCategory = ISpectTraceCategory(
  id: 'user-repo',
  successKey: 'user-repo-ok',
  errorKey: 'user-repo-error',
);

final users = await logger.traceAsync<List<User>>(
  category: userRepoCategory,
  source: 'user_repository',
  operation: 'fetch_list',
  run: () => userRepository.fetchAll(),
  projectResult: (list) => {'count': list.length},
);
```

`traceSync` and `traceStream` are also available. Each one records the duration, the exception, and the stack trace on failure.

## Observers

Observers receive every log event in real time. Attach one per external sink.

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

Exported logs are plain-text JSON. Do not write PII (emails, phone numbers, tokens) directly through `logger.info(...)`. Rely on the redaction engine when values flow through network interceptors, and sanitize user input before passing it to a manual log call. See [`docs/SECURITY.md`](https://github.com/yelmuratoff/ispect/blob/main/docs/SECURITY.md) for the data-handling policy.

<!-- partial:install_matrix -->

<!-- partial:footer -->
