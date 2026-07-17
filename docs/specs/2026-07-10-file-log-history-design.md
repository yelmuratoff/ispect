# File Log History Design

Date: 2026-07-10
Status: Implemented in 6.1.0

This document is the historical design record for `RollingFileLogHistory`.
Current behavior is defined by the public API, tests, and generated package
documentation.

## Context

`ispectify` exposes the `FileLogHistory` contract and `ispect` already contains
the daily-history browser, but version 6 has no first-party implementation.
The implementation that existed in 4.x rewrote a complete JSON array on every
save, estimated sizes, coupled storage to the global Flutter logger, and did
not redact data before writing it. Reintroducing that implementation would
restore the feature but also restore its scalability, reliability, and privacy
problems.

The new implementation is an opt-in diagnostics store for development, QA,
staging, and dogfooding builds. It is not a production telemetry backend and
must remain inert when `ISPECT_ENABLED` is omitted.

## Goals

- Provide a first-party `FileLogHistory` implementation for Dart IO platforms.
- Keep the synchronous logging path free from file-system work.
- Group physical storage by day and size while correlating logical app
  sessions through `session.id`.
- Redact every record before it reaches disk.
- Bound memory, segment size, retained days, and total disk usage.
- Prevent duplicate records by the existing globally unique log ID.
- Recover useful records from interrupted writes and malformed input.
- Preserve the current daily-session UI and read legacy 4.x daily JSON files.
- Provide deterministic tests for business rules, I/O failures, and disabled
  builds.

## Non-goals

- Replacing Flutter DevTools, Sentry, Crashlytics, or an external log backend.
- Persisting logs on web, where no equivalent local file system is available.
- Creating a file for every app launch.
- Adding a per-session browser in this change. The persisted `session.id`
  allows that to be added without changing the storage format.
- Encrypting the diagnostic files. The store writes redacted data into the
  application cache sandbox so it remains inspectable and shareable. Apps with
  a regulated-data threat model can supply a custom `FileLogHistory`.
- Guaranteeing lossless logging after process termination. Batching makes the
  accepted loss window explicit and bounded by the auto-save interval.

## Public API

The existing `FileLogHistory` interface remains the compatibility boundary.
The concrete implementation is exported from `ispectify`:

```dart
final class RollingFileLogHistory implements FileLogHistory {
  RollingFileLogHistory(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
  });
}

typedef FileLogDirectoryProvider = Future<String> Function();
```

`FileLogHistoryOptions` is immutable and owns only persistence settings:

```dart
final class FileLogHistoryOptions {
  const FileLogHistoryOptions({
    this.maxSessionDays = 7,
    this.maxFileSize = 5 * 1024 * 1024,
    this.maxTotalSize = 50 * 1024 * 1024,
    this.autoSaveInterval = const Duration(seconds: 1),
    this.maxBatchItems = 100,
    this.enableAutoSave = true,
    this.cleanupStrategy = SessionCleanupStrategy.deleteOldest,
    this.onError,
  });
}
```

Construction rejects non-positive limits and requires
`maxTotalSize >= maxFileSize`. Keeping these settings out of
`ISpectLoggerOptions` prevents generic in-memory or custom histories from
depending on file-specific policy.

Flutter consumers get an additive convenience parameter:

```dart
final logger = ISpectFlutter.init(
  options: ISpectLoggerOptions(...),
  fileHistory: const FileLogHistoryOptions(...),
);
```

`ISpectFlutter.init` resolves the application cache directory lazily through
the existing `path_provider` dependency. Passing both `history` and
`fileHistory` throws `ArgumentError`, because two sources of history ownership
would be ambiguous. When file history is unsupported or compile-time disabled,
the logger uses its normal in-memory history and `fileLogHistory` remains
`null`, keeping the history UI hidden.

The current synchronous `sessionDirectory` and `todaySessionPath` getters are
retained. They throw `StateError` until the first asynchronous storage
operation finishes initialization. The Flutter daily-session screen will no
longer read `sessionDirectory` while constructing its route; it first awaits a
history operation.

## Storage Layout and Format

```text
ispect_logs/
  2026-07-10/
    000000.jsonl
    000001.jsonl
  2026-07-11/
    000000.jsonl
```

Each segment is newline-delimited JSON. A line contains one normal
`ISpectLogData.toJson()` map plus:

- `schema-version: 1`;
- `session.id` in `additional-data`;
- `payload-truncated: true` when an oversized record had its payload removed.

The app-launch session ID is generated once per history instance. It is a
non-user ULID-style identifier and must never reuse authentication or analytics
session identifiers.

The codec strips private presentation keys through the existing serialization
path, sanitizes unsupported values into JSON-safe strings, applies the injected
or default `RedactionService` to the whole record, then encodes UTF-8. It does
not call `ISpectLogData.toJson()` and write the result without redaction.

Legacy `logs_YYYY-MM-DD.json` arrays remain readable. New writes always use the
segmented JSONL layout. Reading a legacy date and subsequently saving new logs
does not modify or delete the legacy file; reads merge both sources by ID.

For segmented storage:

- `getDateFileSize` returns the sum of live and archived segments for a date.
- `getLogsByDate` reads every segment, deduplicates by ID, and sorts by time
  with ID as a deterministic tie-breaker.
- `getLogPathByDate` returns the date directory. The interface documentation
  will allow either a file or directory depending on the implementation.
- `getLogsBySession` accepts a managed segment or date-directory path and
  rejects paths outside `sessionDirectory`, including resolved symlinks.
- `clearDateStorage` deletes the whole managed date directory and any matching
  legacy daily file.
- `clearAllFileStorage` deletes only artifacts owned by this implementation,
  never arbitrary siblings of the configured root.

## In-memory Buffer and Deduplication

The file history uses a bounded `ListQueue<ISpectLogData>` for ordered memory
history and a `Set<String>` for membership. Both are updated together:

- a duplicate ID is ignored;
- FIFO eviction removes the evicted ID from the set;
- membership is amortized O(1);
- `history` remains an unmodifiable cached view;
- `useHistory`, `enabled`, and `maxHistoryItems` retain their current meaning.

Pending disk writes use an insertion-ordered map keyed by ID. The queue is
bounded by `maxHistoryItems`; if storage remains unavailable, it cannot grow
without limit. An evicted pending record is reported through `onError` as a
bounded-buffer data loss event rather than silently consuming memory.

Imports and multi-segment reads build one ID map and therefore deduplicate in
O(n) before the final O(n log n) ordering step. Message or timestamp hashes are
not used because equal text at the same time can represent separate events.

## Write and Concurrency Model

`add()` performs no file-system work. It updates memory, enqueues an accepted
record, and schedules one trailing batch timer if none is active. Continuous
logging cannot create one timer per record and cannot postpone persistence
indefinitely.

`loadFromDate` replaces the memory buffer with already-persisted entries and
does not enqueue them again. `importFromJson` appends accepted entries to memory
and does enqueue them: a later save groups imported records by their original
local event dates. Existing `session.id` values are preserved; imported legacy
records without one receive a distinct import-session ID rather than the
current app-launch ID.

Flushes are serialized through one future chain:

1. Atomically detach a snapshot of pending records.
2. Redact and UTF-8 encode the snapshot.
3. Group records by their original local calendar dates and resolve each
   active segment.
4. Validate the active segment tail; truncate an incomplete final line back to
   the last newline or rotate when safe truncation is impossible.
5. Split the batch when the next complete line would exceed `maxFileSize`.
6. Append complete newline-terminated records.
7. Apply retention only after the write succeeds.
8. Remove successfully written IDs from pending state.

Manual `saveToDailyFile`, auto-save, and logger disposal share this path. A
failed batch is restored ahead of newer pending records without duplicating
IDs. `ISpectLogger.dispose()` awaits `saveToDailyFile()` before disposing a
file history. Replacing history through the existing synchronous `configure`
API remains caller-managed: callers that replace a live file history must
explicitly await `saveToDailyFile()` first.

A crash can leave only the last JSONL line incomplete. Readers ignore one
incomplete trailing line and continue to surface all complete records. Malformed
complete lines are skipped and reported; they do not make the whole day
unreadable.

`updateAutoSaveSettings` retains its existing contract. Interval updates are
stored, replacing the single pending timer when auto-save is active; disabling
auto-save cancels the timer without discarding pending records; re-enabling it
uses the latest interval.

## Rotation and Retention

Limits are enforced from real UTF-8 byte lengths and filesystem metadata, not
sampling estimates.

- `maxFileSize` limits one segment.
- `maxSessionDays` limits distinct local calendar dates, including archives.
- `maxTotalSize` limits every live, legacy, and archived artifact owned by the
  history root in steady state. Temporary archive files are bounded by one
  segment, removed after failure, and included in the preflight space check.
- The active segment is never selected for cleanup.
- Earlier closed segments from the current day may be cleaned when necessary.

After every successful flush and during first initialization, the retention
planner first removes dates beyond `maxSessionDays`, oldest first. It then
reduces total size according to `cleanupStrategy`:

- `deleteOldest`: remove the oldest closed segments first.
- `deleteBySize`: remove the largest closed segments first, with age as the
  deterministic tie-breaker.
- `archiveOldest`: GZIP closed segments through a temporary file and atomic
  rename, then delete oldest archives if compression alone does not satisfy the
  total cap.

Archives count toward both date and total-size limits and are readable by the
normal APIs. Compression is opt-in through the existing strategy and is never
performed on the active segment. Compression runs outside the caller's logging
path and does not block `add()`.

If one encoded record is larger than `maxFileSize`, the codec keeps ID, time,
level, key, a bounded message, and safe trace correlation fields; it removes
the payload and marks the record as truncated. If even that envelope cannot
fit, the record is rejected through a typed error without corrupting the
segment.

## Security and Privacy

- Redaction occurs before disk write, archive creation, and JSON export.
- The default `RedactionService` includes the existing sensitive-key and
  pattern strategies. Consumers may inject their application-specific
  redactor.
- The global redaction opt-out remains authoritative. Disabling it while file
  history is enabled deliberately allows raw persistence and will be called
  out prominently in API documentation and tested as an explicit opt-out.
- No tokens, cookies, credentials, or raw payload fixtures appear in test
  output.
- External paths, path traversal, and symlink escapes are rejected.
- Imported JSON is bounded by `maxTotalSize` before parsing and by
  `maxHistoryItems` after parsing.
- Persistence uses the application cache sandbox and does not request new
  platform permissions.
- The feature performs no initialization, directory creation, timers, or
  writes when `kISpectEnabled` is false.

## Errors and Observability

Public explicit operations throw a sealed `FileLogHistoryException` hierarchy:

- `FileLogStorageException` for create/read/write/delete failures;
- `FileLogFormatException` for invalid imports or unrecoverable file formats;
- `FileLogAccessException` for paths outside the managed root;
- `FileLogLimitException` for records or imports that cannot fit configured
  bounds.

Exceptions retain the operation, safe managed path when applicable, cause,
and stack trace. Their `toString()` must not include persisted content.

Auto-save catches these exceptions so diagnostics cannot crash the host app.
It invokes the optional `onError` callback and keeps the batch pending for a
later attempt. It does not log back through the same `ISpectLogger`, avoiding
re-entrant history writes. If no callback exists, the existing scoped
`dart:developer` fallback is used with the `[ISpect]` prefix.

## Test Strategy

Implementation follows red-green-refactor. Tests mirror the source layout and
use real temporary directories for the I/O boundary plus pure unit tests for
codec and retention rules.

Required coverage:

- option validation at every B-1/B/B+1 boundary;
- bounded FIFO memory behavior and duplicate IDs;
- single and concurrent flush ordering;
- date rollover and exact byte-size segment rollover;
- `maxSessionDays`, `maxFileSize`, and `maxTotalSize` interactions;
- every cleanup strategy, deterministic tie-breaking, and active-file safety;
- archive accounting and readback;
- redaction before live write, archive, and export;
- explicit unredacted global opt-out;
- oversized-record minimization;
- malformed middle lines and interrupted final lines;
- tail repair before the next append;
- transient write failure with pending-batch recovery;
- load-without-requeue and date-preserving import persistence;
- auto-save disable, interval update, and re-enable transitions;
- import limits, invalid shapes, and ID deduplication;
- path traversal and symlink escape rejection;
- legacy 4.x JSON-array read compatibility;
- logger disposal flush;
- disabled-build no directory, timer, or file side effects;
- Flutter convenience wiring and web fallback.

The affected package gates are:

```bash
cd packages/ispectify
dart format <changed Dart files>
dart analyze --fatal-infos
dart test --coverage=coverage

cd packages/ispect
flutter analyze --fatal-infos
flutter test --coverage
```

README sources, generated README files, root changelog, roadmap, and dependency
checks are updated and verified when implementation changes their inputs.

## Rollout and Compatibility

The feature is additive and disabled unless `fileHistory` or a concrete custom
history is supplied. Existing in-memory history, custom `ILogHistory`
implementations, export UI, and web behavior remain unchanged.

The current `FileLogHistory` interface gains no new required members. Its path
documentation is broadened for segmented implementations. The concrete class,
options, exceptions, and directory-provider typedef are exported from the
`ispectify` root library. Flutter convenience wiring is exported from `ispect`.

The implementation is complete when both package gates pass, README drift and
dependency checks pass, and a final diff audit confirms redaction, retention,
disabled-build behavior, and scope against this specification.
