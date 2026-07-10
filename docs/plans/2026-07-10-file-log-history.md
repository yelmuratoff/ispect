# Rolling File Log History Implementation Plan

> Execute with `subagent-driven-development` only when the user explicitly
> authorizes subagents/delegation; otherwise execute inline. Steps use `- [ ]`
> for tracking.

**Goal:** Ship an opt-in, redaction-first, bounded rolling `FileLogHistory`
implementation with Flutter convenience wiring and deterministic coverage.

**Architecture:** The test seam is the public `RollingFileLogHistory` contract,
exercised against real temporary directories. Pure helpers own bounded memory,
record encoding, and retention planning; the IO implementation coordinates
them behind a conditional export so `ispectify` remains web-compatible.

**Tech stack:** Dart 3.6+, `dart:io`, `dart:convert`, `dart:async`, existing
`ispectify` redaction/serialization APIs, Flutter `path_provider`, `package:test`,
and `flutter_test`. Add no dependencies.

## Global Constraints

- Read `.ai/src/rules/*.md` and load `command-swe`, `testing`, `security`, and
  `performance` before implementation.
- Create an isolated `codex/rolling-file-history` worktree before editing;
  never implement this plan directly on `main`.
- Follow strict analyzer rules and use explicit return types.
- Use red-green-refactor: every production behavior starts with a test that is
  observed failing for the intended reason.
- Persist newline-delimited JSON under `ispect_logs/YYYY-MM-DD/NNNNNN.jsonl`.
- Use local event dates for grouping and exact UTF-8 lengths for rotation.
- Redact with `RedactionService` before every disk write and JSON export.
- Deduplicate only by immutable `ISpectLogData.id`.
- Default limits: 7 days, 5 MiB per segment, 50 MiB total, 100 records per
  batch, and a 1-second auto-save interval.
- The active segment is never cleaned; archives count toward all limits.
- `kISpectEnabled == false` must create no directory, timer, or file.
- Keep network/database redaction defaults, log keys, generated localization,
  versions, and dependency constraints unchanged.
- Preserve unrelated user changes and never use destructive git commands.
- Treat `docs/specs/2026-07-10-file-log-history-design.md` as the approved
  source of requirements.

---

## File Structure

Create or modify the following units:

```text
packages/ispectify/lib/src/history/file_log/
  file_log_history.dart                 # existing compatibility contract/export
  file_log_history_exception.dart       # typed public failure hierarchy
  file_log_history_options.dart         # immutable persistence configuration
  bounded_log_buffer.dart               # ordered O(1)-deduplicating memory store
  file_log_codec.dart                   # JSON-safe redaction/JSONL codec
  retention_planner.dart                # pure cleanup decision engine
  rolling_file_log_history.dart         # conditional public export
  rolling_file_log_history_io.dart      # Dart IO coordinator
  rolling_file_log_history_stub.dart    # unsupported non-IO shape
  session_cleanup_strategy.dart         # existing strategy enum
  session_statistics.dart               # add total-limit reporting

packages/ispectify/lib/src/trace/trace_keys.dart
packages/ispectify/lib/src/ispectify.dart
packages/ispectify/lib/ispectify.dart

packages/ispectify/test/history/file_log/
  file_log_history_options_test.dart
  bounded_log_buffer_test.dart
  file_log_codec_test.dart
  retention_planner_test.dart
  rolling_file_log_history_test.dart
  rolling_file_log_history_recovery_test.dart
  rolling_file_log_history_retention_test.dart
  rolling_file_log_history_security_test.dart

packages/ispect/lib/src/common/extensions/init.dart
packages/ispect/lib/src/common/history/flutter_file_log_history_factory.dart
packages/ispect/lib/src/features/log_viewer/presentation/screens/daily_sessions.dart
packages/ispect/test/common/extensions/init_file_history_test.dart

docs/readme/_partials/root_body.md
docs/readme/ispectify.md
ROADMAP.md
CHANGELOG.md
```

---

### Task 1: Public configuration and typed failures

**Files:**
- Create: `packages/ispectify/lib/src/history/file_log/file_log_history_exception.dart`
- Create: `packages/ispectify/lib/src/history/file_log/file_log_history_options.dart`
- Modify: `packages/ispectify/lib/src/history/file_log/session_statistics.dart`
- Modify: `packages/ispectify/lib/src/history/file_log/file_log_history.dart`
- Test: `packages/ispectify/test/history/file_log/file_log_history_options_test.dart`
- Test: `packages/ispectify/test/session_statistics_test.dart`

**Interfaces:**
- Consumes: existing `SessionCleanupStrategy` and `SessionStatistics`.
- Produces: `FileLogDirectoryProvider`, `FileLogHistoryErrorHandler`,
  `FileLogHistoryOptions`, and the sealed `FileLogHistoryException` hierarchy.

- [ ] **Step 1: Write the failing option-boundary tests**

```dart
import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('FileLogHistoryOptions.validate', () {
    const mib = 1024 * 1024;
    final cases = <({FileLogHistoryOptions options, String field})>[
      (
        options: const FileLogHistoryOptions(maxSessionDays: 0),
        field: 'maxSessionDays',
      ),
      (
        options: const FileLogHistoryOptions(maxFileSize: 0),
        field: 'maxFileSize',
      ),
      (
        options: const FileLogHistoryOptions(maxTotalSize: 4 * mib),
        field: 'maxTotalSize',
      ),
      (
        options: const FileLogHistoryOptions(maxBatchItems: 0),
        field: 'maxBatchItems',
      ),
      (
        options: const FileLogHistoryOptions(
          autoSaveInterval: Duration.zero,
        ),
        field: 'autoSaveInterval',
      ),
    ];

    for (final testCase in cases) {
      test('rejects invalid ${testCase.field}', () {
        expect(
          testCase.options.validate,
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              testCase.field,
            ),
          ),
        );
      });
    }

    test('accepts maxTotalSize equal to maxFileSize', () {
      const options = FileLogHistoryOptions(
        maxFileSize: 5 * mib,
        maxTotalSize: 5 * mib,
      );

      expect(options.validate, returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run from `packages/ispectify`:

```bash
dart test test/history/file_log/file_log_history_options_test.dart
```

Expected: FAIL because `FileLogHistoryOptions` does not exist.

- [ ] **Step 3: Add the exact public types**

```dart
// file_log_history_exception.dart
sealed class FileLogHistoryException implements Exception {
  const FileLogHistoryException({
    required this.kind,
    required this.operation,
    this.path,
    this.cause,
    this.stackTrace,
  });

  final String kind;
  final String operation;
  final String? path;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'FileLogHistoryException(kind: $kind, operation: $operation'
      '${path == null ? '' : ', path: $path'})';
}

final class FileLogStorageException extends FileLogHistoryException {
  const FileLogStorageException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'storage');
}

final class FileLogFormatException extends FileLogHistoryException {
  const FileLogFormatException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'format');
}

final class FileLogAccessException extends FileLogHistoryException {
  const FileLogAccessException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'access');
}

final class FileLogLimitException extends FileLogHistoryException {
  const FileLogLimitException({
    required super.operation,
    super.path,
    super.cause,
    super.stackTrace,
  }) : super(kind: 'limit');
}
```

```dart
// file_log_history_options.dart
import 'package:ispectify/src/history/file_log/file_log_history_exception.dart';
import 'package:ispectify/src/history/file_log/session_cleanup_strategy.dart';
import 'package:meta/meta.dart';

typedef FileLogDirectoryProvider = Future<String> Function();
typedef FileLogHistoryErrorHandler = void Function(
  FileLogHistoryException error,
);

@immutable
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

  final int maxSessionDays;
  final int maxFileSize;
  final int maxTotalSize;
  final Duration autoSaveInterval;
  final int maxBatchItems;
  final bool enableAutoSave;
  final SessionCleanupStrategy cleanupStrategy;
  final FileLogHistoryErrorHandler? onError;

  void validate() {
    if (maxSessionDays <= 0) {
      throw ArgumentError.value(maxSessionDays, 'maxSessionDays');
    }
    if (maxFileSize <= 0) {
      throw ArgumentError.value(maxFileSize, 'maxFileSize');
    }
    if (maxTotalSize < maxFileSize) {
      throw ArgumentError.value(maxTotalSize, 'maxTotalSize');
    }
    if (maxBatchItems <= 0) {
      throw ArgumentError.value(maxBatchItems, 'maxBatchItems');
    }
    if (autoSaveInterval <= Duration.zero) {
      throw ArgumentError.value(autoSaveInterval, 'autoSaveInterval');
    }
  }
}
```

Export both files from `file_log_history.dart`; add `maxTotalSize` with a
default of `0` to `SessionStatistics` so existing callers remain source
compatible, and include it in `toString()`.

- [ ] **Step 4: Run tests and confirm GREEN**

```bash
dart test test/history/file_log/file_log_history_options_test.dart test/session_statistics_test.dart
```

Expected: both test files PASS.

- [ ] **Step 5: Commit the public foundation**

```bash
git add packages/ispectify/lib/src/history/file_log packages/ispectify/test/history/file_log/file_log_history_options_test.dart packages/ispectify/test/session_statistics_test.dart
git commit -m "feat(ispectify): define file history configuration"
```

---

### Task 2: Bounded ordered memory with ID deduplication

**Files:**
- Create: `packages/ispectify/lib/src/history/file_log/bounded_log_buffer.dart`
- Test: `packages/ispectify/test/history/file_log/bounded_log_buffer_test.dart`

**Interfaces:**
- Consumes: `ISpectLogData` and `ISpectLoggerOptions`.
- Produces: internal `BoundedLogBuffer.add`, `replaceAll`, `clear`, and
  unmodifiable `history` used by the rolling coordinator.

- [ ] **Step 1: Write failing behavior tests**

```dart
import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/bounded_log_buffer.dart';
import 'package:test/test.dart';

void main() {
  test('deduplicates by ID and evicts FIFO with a bounded index', () {
    final buffer = BoundedLogBuffer(
      ISpectLoggerOptions(maxHistoryItems: 2),
    );
    final first = ISpectLogData('first', id: 'A');
    final duplicate = ISpectLogData('duplicate', id: 'A');
    final second = ISpectLogData('second', id: 'B');
    final third = ISpectLogData('third', id: 'C');

    expect(buffer.add(first), isTrue);
    expect(buffer.add(duplicate), isFalse);
    expect(buffer.add(second), isTrue);
    expect(buffer.add(third), isTrue);
    expect(buffer.history.map((log) => log.id), ['B', 'C']);
  });

  test('returns an unmodifiable cached history view', () {
    final buffer = BoundedLogBuffer(ISpectLoggerOptions())
      ..add(ISpectLogData('entry', id: 'A'));
    final first = buffer.history;

    expect(() => first.clear(), throwsUnsupportedError);
    buffer.add(ISpectLogData('next', id: 'B'));
    expect(identical(first, buffer.history), isFalse);
  });
}
```

- [ ] **Step 2: Run and confirm RED**

```bash
dart test test/history/file_log/bounded_log_buffer_test.dart
```

Expected: FAIL because `BoundedLogBuffer` is missing.

- [ ] **Step 3: Implement the bounded queue and ID set**

Use `ListQueue<ISpectLogData>` and `Set<String>`. `add` returns `false` when
history is disabled, the maximum is zero, or the ID exists. Before adding at
capacity, remove the head and its ID. `replaceAll` clears once and calls `add`
in input order. Invalidate the cached unmodifiable list after every mutation.

- [ ] **Step 4: Run and confirm GREEN**

```bash
dart test test/history/file_log/bounded_log_buffer_test.dart
```

Expected: PASS with no warnings.

- [ ] **Step 5: Commit**

```bash
git add packages/ispectify/lib/src/history/file_log/bounded_log_buffer.dart packages/ispectify/test/history/file_log/bounded_log_buffer_test.dart
git commit -m "feat(ispectify): add bounded file history buffer"
```

---

### Task 3: Redaction-first JSONL codec

**Files:**
- Create: `packages/ispectify/lib/src/history/file_log/file_log_codec.dart`
- Modify: `packages/ispectify/lib/src/trace/trace_keys.dart`
- Test: `packages/ispectify/test/history/file_log/file_log_codec_test.dart`

**Interfaces:**
- Consumes: `ISpectLogData.toJson`, `ISpectLogDataJsonUtils.fromJson`,
  `RedactionService`, and `TraceKeys`.
- Produces: `EncodedLogRecord`, `FileLogCodec.encode`, `decodeLine`,
  `decodeLegacyArray`, and exact byte-bounded minimization.

- [ ] **Step 1: Write failing codec tests**

```dart
test('redacts before encoding and adds the non-user session ID', () {
  final codec = FileLogCodec(redactor: RedactionService());
  final log = ISpectLogData(
    'request',
    id: 'A',
    additionalData: {'authorization': 'Bearer secret-value'},
  );

  final encoded = codec.encode(
    log,
    sessionId: 'SESSION',
    maxBytes: 4096,
  );
  final text = utf8.decode(encoded.bytes);

  expect(text, isNot(contains('secret-value')));
  expect(text, contains('SESSION'));
  expect(text.endsWith('\n'), isTrue);
});

test('minimizes a record that exceeds one segment', () {
  final codec = FileLogCodec(redactor: RedactionService());
  final encoded = codec.encode(
    ISpectLogData(
      'message',
      id: 'A',
      additionalData: {'body': 'x' * 10000},
    ),
    sessionId: 'SESSION',
    maxBytes: 512,
  );

  expect(encoded.bytes.length, lessThanOrEqualTo(512));
  expect(encoded.truncated, isTrue);
  expect(utf8.decode(encoded.bytes), contains('payload-truncated'));
});

test('round trips one JSONL record with its original ID', () {
  final codec = FileLogCodec(redactor: RedactionService());
  final source = ISpectLogData('message', id: 'A');
  final encoded = codec.encode(source, sessionId: 'S', maxBytes: 4096);

  expect(codec.decodeLine(utf8.decode(encoded.bytes).trim()).id, 'A');
});
```

- [ ] **Step 2: Run and confirm RED**

```bash
dart test test/history/file_log/file_log_codec_test.dart
```

Expected: FAIL because the codec is not defined.

- [ ] **Step 3: Implement the codec**

Add these metadata constants:

```dart
static const sessionId = 'session.id';
static const payloadTruncated = 'payload-truncated';
```

Define:

```dart
final class EncodedLogRecord {
  const EncodedLogRecord({
    required this.id,
    required this.bytes,
    required this.truncated,
  });
  final String id;
  final List<int> bytes;
  final bool truncated;
}
```

`FileLogCodec.encode` must:

1. copy `log.toJson()`;
2. copy `additional-data` and add `TraceKeys.sessionId`;
3. add `schema-version: 1`;
4. recursively convert unsupported map/list values to JSON-safe values;
5. call `redactor.redact` on the whole map;
6. `jsonEncode`, append one newline, then `utf8.encode`;
7. if too large, rebuild only ID, time, level, key, a message bounded to 160
   characters, safe correlation fields, session ID, and the truncation marker;
8. throw `FileLogLimitException` if the minimized line still exceeds
   `maxBytes`.

`decodeLine` validates a JSON object and delegates to
`ISpectLogDataJsonUtils.fromJson`. `decodeLegacyArray` validates a JSON list,
skips no invalid entries silently, and throws `FileLogFormatException` with the
entry index in `operation`.

- [ ] **Step 4: Run codec and existing redaction tests**

```bash
dart test test/history/file_log/file_log_codec_test.dart test/redaction_service_test.dart
```

Expected: PASS; the redaction regression suite remains green.

- [ ] **Step 5: Commit**

```bash
git add packages/ispectify/lib/src/history/file_log/file_log_codec.dart packages/ispectify/lib/src/trace/trace_keys.dart packages/ispectify/test/history/file_log/file_log_codec_test.dart
git commit -m "feat(ispectify): encode redacted JSONL history records"
```

---

### Task 4: Pure retention decisions

**Files:**
- Create: `packages/ispectify/lib/src/history/file_log/retention_planner.dart`
- Test: `packages/ispectify/test/history/file_log/retention_planner_test.dart`

**Interfaces:**
- Consumes: `FileLogHistoryOptions` and `SessionCleanupStrategy`.
- Produces: immutable `FileLogArtifact`, sealed `RetentionAction`, and
  `RetentionPlanner.plan` for the IO coordinator.

- [ ] **Step 1: Write table-driven failing tests**

Cover these exact rules:

```dart
test('removes expired dates before applying the size strategy', () {
  final actions = RetentionPlanner(
    const FileLogHistoryOptions(
      maxSessionDays: 2,
      maxFileSize: 100,
      maxTotalSize: 300,
    ),
  ).plan([
    artifact('old', DateTime(2026, 7, 8), size: 50),
    artifact('middle', DateTime(2026, 7, 9), size: 50),
    artifact('active', DateTime(2026, 7, 10), size: 50, active: true),
  ]);

  expect(actions, [isA<DeleteArtifact>().having((a) => a.path, 'path', 'old')]);
});

test('never selects the active artifact', () {
  final actions = RetentionPlanner(
    const FileLogHistoryOptions(
      maxSessionDays: 7,
      maxFileSize: 100,
      maxTotalSize: 100,
    ),
  ).plan([
    artifact('closed', DateTime(2026, 7, 10), size: 80),
    artifact('active', DateTime(2026, 7, 10), size: 80, active: true),
  ]);

  expect(actions.map((action) => action.path), isNot(contains('active')));
});
```

Add rows proving oldest-first, largest-first with age tie-breaking, archive
selection, archives counted toward total size, and temporary files excluded
from normal candidates but reported for cleanup after failure.

- [ ] **Step 2: Run and confirm RED**

```bash
dart test test/history/file_log/retention_planner_test.dart
```

Expected: FAIL because planner types are missing.

- [ ] **Step 3: Implement a deterministic planner**

Use records or final immutable classes. `plan` must never touch the filesystem.
Group distinct dates, select all artifacts from dates beyond
`maxSessionDays`, subtract their sizes, then choose closed artifacts until the
projected total is within `maxTotalSize`. Return actions in execution order.
For `archiveOldest`, return `ArchiveArtifact` only for uncompressed closed
segments; if only archives remain, return `DeleteArtifact` oldest-first.

- [ ] **Step 4: Run and confirm GREEN**

```bash
dart test test/history/file_log/retention_planner_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/ispectify/lib/src/history/file_log/retention_planner.dart packages/ispectify/test/history/file_log/retention_planner_test.dart
git commit -m "feat(ispectify): plan bounded file history retention"
```

---

### Task 5: Minimal rolling IO history slice

**Files:**
- Create: `packages/ispectify/lib/src/history/file_log/rolling_file_log_history.dart`
- Create: `packages/ispectify/lib/src/history/file_log/rolling_file_log_history_io.dart`
- Create: `packages/ispectify/lib/src/history/file_log/rolling_file_log_history_stub.dart`
- Modify: `packages/ispectify/lib/src/history/file_log/file_log_history.dart`
- Test: `packages/ispectify/test/history/file_log/rolling_file_log_history_test.dart`

**Interfaces:**
- Consumes: Tasks 1-4 types and existing `FileLogHistory`.
- Produces: exported `RollingFileLogHistory` supporting memory add/clear,
  initialization, manual flush, exact segment rotation, daily read, and clear.

- [ ] **Step 1: Write the first end-to-end failing test**

```dart
test('writes redacted unique records and reads the day in order', () async {
  final root = await Directory.systemTemp.createTemp('ispect-history-');
  addTearDown(() => root.delete(recursive: true));
  final history = RollingFileLogHistory.testing(
    ISpectLoggerOptions(useConsoleLogs: false),
    directoryProvider: () async => root.path,
    options: const FileLogHistoryOptions(enableAutoSave: false),
  );
  final first = ISpectLogData(
    'first',
    id: 'A',
    time: DateTime(2026, 7, 10, 9),
    additionalData: {'authorization': 'Bearer secret-value'},
  );

  history
    ..add(first)
    ..add(ISpectLogData('duplicate', id: 'A', time: first.time));
  await history.saveToDailyFile();

  final stored = await history.getLogsByDate(DateTime(2026, 7, 10));
  expect(stored.map((log) => log.id), ['A']);
  final datePath = await history.getLogPathByDate(DateTime(2026, 7, 10));
  final file = File('$datePath/000000.jsonl');
  expect(await file.readAsString(), isNot(contains('secret-value')));
});
```

- [ ] **Step 2: Run and confirm RED**

```bash
dart test test/history/file_log/rolling_file_log_history_test.dart
```

Expected: FAIL because `RollingFileLogHistory` is absent.

- [ ] **Step 3: Add the conditional public entry**

```dart
// rolling_file_log_history.dart
export 'rolling_file_log_history_stub.dart'
    if (dart.library.io) 'rolling_file_log_history_io.dart';
```

The stub must expose the same public constructor and every `FileLogHistory`
member. Its constructor throws `UnsupportedError('File log history requires dart:io')`.

- [ ] **Step 4: Implement the minimal IO coordinator**

The normal constructor delegates to a private constructor with
`enabled: kISpectEnabled`. Add a `@visibleForTesting`
`RollingFileLogHistory.testing` constructor with `enabled: true`. Validate
options before starting initialization.

Use:

- `BoundedLogBuffer` for memory;
- `LinkedHashMap<String, ({ISpectLogData log, String sessionId})>` for pending;
- one generated app-launch session ID;
- a cached `Future<void>` for directory initialization;
- zero timers until an accepted record is added;
- six-digit segment names ordered lexicographically;
- `FileMode.append` only after checking the exact encoded line length;
- a serialized future chain so two `saveToDailyFile()` calls cannot overlap.

Implement all simple contract methods in this slice. `exportToJson` must return
a redacted JSON array built from the memory history. Leave archive execution to
Task 7, but the default delete-oldest planner may already run.

- [ ] **Step 5: Add exact-size rotation coverage**

Add a test with two individually fitting encoded lines whose combined byte
length exceeds `maxFileSize`; assert `000000.jsonl` and `000001.jsonl` exist and
`getLogsByDate` returns both IDs once.

- [ ] **Step 6: Run the slice and confirm GREEN**

```bash
dart test test/history/file_log/rolling_file_log_history_test.dart
```

Expected: PASS; temporary directories are deleted by tear-down.

- [ ] **Step 7: Commit**

```bash
git add packages/ispectify/lib/src/history/file_log packages/ispectify/test/history/file_log/rolling_file_log_history_test.dart
git commit -m "feat(ispectify): persist rolling daily JSONL history"
```

---

### Task 6: Auto-save, serialized flush, import, and recovery

**Files:**
- Modify: `packages/ispectify/lib/src/history/file_log/rolling_file_log_history_io.dart`
- Test: `packages/ispectify/test/history/file_log/rolling_file_log_history_recovery_test.dart`

**Interfaces:**
- Consumes: the minimal coordinator from Task 5.
- Produces: non-overlapping batching, timer transitions, date-preserving
  import, tail repair, retryable pending batches, and safe dispose behavior.

- [ ] **Step 1: Write failing recovery tests**

Add tests that:

1. call `saveToDailyFile()` twice without awaiting the first and assert one ID;
2. disable auto-save, update the interval, re-enable, and verify
   `SessionStatistics` reports the latest interval;
3. import records from two dates, save once, and assert two date directories;
4. load a date and save again, asserting no duplicate is queued;
5. append an incomplete JSON fragment, add another record, save, and assert the
   fragment was truncated before the valid line;
6. inject a directory provider that fails once, assert the first explicit save
   throws `FileLogStorageException`, then succeeds and writes the retained ID;
7. reach `maxBatchItems` and assert an immediate serialized flush is scheduled;
8. overflow the bounded pending queue after a simulated persistent write
   failure and assert `onError` receives one `FileLogLimitException` without
   including the record payload.

Use `Completer<void>` to control concurrency; do not use sleeps.

- [ ] **Step 2: Run and confirm RED**

```bash
dart test test/history/file_log/rolling_file_log_history_recovery_test.dart
```

Expected: FAIL on missing recovery behaviors, not on fixture setup.

- [ ] **Step 3: Implement one serialized operation queue**

Every public save creates an operation completer and appends work to a future
that catches its own error so one failure does not poison later operations.
Detach the pending map, restore it ahead of newer entries on failure, and remove
only IDs whose complete newline was flushed.

Before append, open the active segment with `RandomAccessFile`, inspect the
last byte, and when it is not newline scan backward in bounded chunks for the
last newline and call `truncate`. Rotate instead of modifying when no complete
line exists.

`importFromJson` accepts either a JSON array or JSONL, checks
`utf8.encode(input).length <= maxTotalSize`, assigns one import-session ID to
legacy entries, and queues accepted IDs by original date. `loadFromDate` uses
`BoundedLogBuffer.replaceAll` without queueing.

The `.testing` constructor accepts an internal one-shot timer factory so tests
can capture and fire the scheduled callback synchronously. Production uses
`Timer(duration, callback)`. Background callbacks catch
`FileLogHistoryException`, invoke `options.onError`, retain pending data, and
fall back to a scoped `[ISpect]` `dart:developer` message when no handler is
configured; they never log through the owning `ISpectLogger`.

Implement `updateAutoSaveSettings({bool? enabled, Duration? interval})` by
persisting the latest valid interval, cancelling the one current timer, and
rescheduling only when auto-save remains enabled and pending data exists.

- [ ] **Step 4: Make `ISpectLogger.dispose` flush file history**

Modify `packages/ispectify/lib/src/ispectify.dart`:

```dart
if (_history case final FileLogHistory fileHistory) {
  await fileHistory.saveToDailyFile();
}
_history.dispose();
```

Add a logger-level test proving a pending record exists on disk after
`await logger.dispose()`.

- [ ] **Step 5: Run recovery plus logger disposal tests**

```bash
dart test test/history/file_log/rolling_file_log_history_recovery_test.dart test/ispect_logger_dispose_test.dart
```

Expected: PASS without timers left alive after test completion.

- [ ] **Step 6: Commit**

```bash
git add packages/ispectify/lib/src/history/file_log/rolling_file_log_history_io.dart packages/ispectify/lib/src/ispectify.dart packages/ispectify/test/history/file_log/rolling_file_log_history_recovery_test.dart packages/ispectify/test/ispect_logger_dispose_test.dart
git commit -m "feat(ispectify): make file history flush recoverable"
```

---

### Task 7: Retention, archive, statistics, legacy reads, and path safety

**Files:**
- Modify: `packages/ispectify/lib/src/history/file_log/rolling_file_log_history_io.dart`
- Modify: `packages/ispectify/lib/src/history/file_log/session_statistics.dart`
- Test: `packages/ispectify/test/history/file_log/rolling_file_log_history_retention_test.dart`
- Test: `packages/ispectify/test/history/file_log/rolling_file_log_history_security_test.dart`

**Interfaces:**
- Consumes: `RetentionPlanner`, typed failures, JSONL/legacy codec.
- Produces: all three cleanup strategies, GZIP readback, bounded statistics,
  legacy 4.x compatibility, owned-root deletion, and traversal rejection.

- [ ] **Step 1: Write failing retention integration tests**

Use real temporary directories and fixed log dates. Cover:

- 8 dates with `maxSessionDays: 7` deletes only the oldest date;
- total size over cap removes closed segments but never the active segment;
- delete-by-size chooses the largest closed file and uses age for equal sizes;
- archive-oldest creates `.jsonl.gz`, removes the source, remains readable, and
  deletes the oldest archive when the cap is still exceeded;
- `clearDateStorage` removes its directory and matching legacy JSON;
- `clearAllFileStorage` preserves an unrelated sibling file;
- `getSessionStatistics` returns total days, bytes, entries, configured limits,
  and the current auto-save state.

- [ ] **Step 2: Write failing security and legacy tests**

```dart
test('rejects a path outside the managed root', () async {
  expect(
    history.getLogsBySession(outsideFile.path),
    throwsA(isA<FileLogAccessException>()),
  );
});

test('reads a legacy 4.x JSON array and deduplicates IDs', () async {
  await legacyFile.writeAsString(jsonEncode([
    ISpectLogData('legacy', id: 'A', time: date).toJson(),
    ISpectLogData('duplicate', id: 'A', time: date).toJson(),
  ]));

  expect((await history.getLogsByDate(date)).map((log) => log.id), ['A']);
});
```

On platforms where symlink creation is supported, add a symlink escape test;
skip only when `Link.create` returns a platform permission failure.

- [ ] **Step 3: Run and confirm RED**

```bash
dart test test/history/file_log/rolling_file_log_history_retention_test.dart test/history/file_log/rolling_file_log_history_security_test.dart
```

Expected: FAIL on missing archive/retention/access behavior.

- [ ] **Step 4: Implement artifact scanning and action execution**

Scan only:

- `YYYY-MM-DD` owned directories;
- six-digit `.jsonl` and `.jsonl.gz` segments;
- `logs_YYYY-MM-DD.json` legacy files;
- owned `.tmp` archive files.

Resolve canonical paths before reads/deletes and require either exact root or a
root-plus-separator prefix. Stream GZIP through a temporary file, close all
handles, atomically rename, and delete the source only after successful rename.
Rerun the planner after archive actions because compressed size is known only
after writing. Ensure failed temporary files are removed in `finally`.

Count JSONL entries by complete non-empty lines and legacy entries by decoded
array length. Do not retain decoded payloads while calculating statistics.

- [ ] **Step 5: Run and confirm GREEN**

```bash
dart test test/history/file_log/rolling_file_log_history_retention_test.dart test/history/file_log/rolling_file_log_history_security_test.dart
```

Expected: PASS; no file remains outside test-owned roots.

- [ ] **Step 6: Commit**

```bash
git add packages/ispectify/lib/src/history/file_log packages/ispectify/test/history/file_log/rolling_file_log_history_retention_test.dart packages/ispectify/test/history/file_log/rolling_file_log_history_security_test.dart
git commit -m "feat(ispectify): enforce smart history retention"
```

---

### Task 8: Compile-time gate, public exports, and Flutter convenience

**Files:**
- Modify: `packages/ispectify/lib/ispectify.dart`
- Create: `packages/ispect/lib/src/common/history/flutter_file_log_history_factory.dart`
- Modify: `packages/ispect/lib/src/common/extensions/init.dart`
- Modify: `packages/ispect/lib/src/features/log_viewer/presentation/screens/daily_sessions.dart`
- Test: `packages/ispect/test/common/extensions/init_file_history_test.dart`

**Interfaces:**
- Consumes: `RollingFileLogHistory`, `FileLogHistoryOptions`,
  `getApplicationCacheDirectory`, `kISpectEnabled`, and `kIsWeb`.
- Produces: `ISpectFlutter.init(fileHistory: ...)`, web/disabled fallback, and
  lazy-safe daily-session navigation.

- [ ] **Step 1: Write failing factory and conflict tests**

Test the internal factory directly with injected booleans and provider:

```dart
test('disabled factory does not call the directory provider', () {
  var called = false;
  final history = createFlutterFileLogHistory(
    loggerOptions: ISpectLoggerOptions(),
    fileHistoryOptions: const FileLogHistoryOptions(),
    isEnabled: false,
    isWeb: false,
    directoryProvider: () async {
      called = true;
      return '/unused';
    },
  );

  expect(history, isNull);
  expect(called, isFalse);
});

test('init rejects custom and first-party history together', () {
  expect(
    () => ISpectFlutter.init(
      history: DefaultISpectLoggerHistory(ISpectLoggerOptions()),
      fileHistory: const FileLogHistoryOptions(),
    ),
    throwsArgumentError,
  );
});
```

Add a web-row test asserting `null`, and an enabled IO row asserting a
`RollingFileLogHistory` is created without resolving the provider eagerly.

- [ ] **Step 2: Run and confirm RED**

```bash
flutter test test/common/extensions/init_file_history_test.dart
```

Expected: FAIL because factory and parameter are absent.

- [ ] **Step 3: Implement Flutter factory and init wiring**

```dart
FileLogHistory? createFlutterFileLogHistory({
  required ISpectLoggerOptions loggerOptions,
  required FileLogHistoryOptions fileHistoryOptions,
  FileLogDirectoryProvider? directoryProvider,
  bool isEnabled = kISpectEnabled,
  bool isWeb = kIsWeb,
}) {
  if (!isEnabled || isWeb) return null;
  return RollingFileLogHistory(
    loggerOptions,
    options: fileHistoryOptions,
    directoryProvider: directoryProvider ?? () async {
      final directory = await getApplicationCacheDirectory();
      return directory.path;
    },
  );
}
```

In `ISpectFlutter.init`, resolve options once, reject both history inputs, and
pass either the custom history or factory result to `ISpectLogger`.

Remove eager `history.sessionDirectory` access from
`DailySessionsScreen.push`; route arguments may contain only a boolean that
history is configured. Existing async session loading initializes the path
before open/copy actions become relevant.

- [ ] **Step 4: Export public core types and run Flutter tests**

Export options, exceptions, and conditional rolling history from
`packages/ispectify/lib/ispectify.dart` through the existing
`file_log_history.dart` barrel.

```bash
flutter test test/common/extensions/init_file_history_test.dart test/ispect_logger_lazy_init_test.dart
```

Expected: PASS; default disabled behavior remains unchanged.

- [ ] **Step 5: Prove the compile-time disabled no-op in core**

Add a normal-constructor test under the default test environment. Pass a
provider that increments a counter, call `add`, `saveToDailyFile`, and
`dispose`, then assert the counter is zero and the root is empty. Keep active
behavior tests on the `.testing` constructor.

```bash
dart test test/history/file_log/rolling_file_log_history_test.dart
```

Expected: PASS and no filesystem artifacts.

- [ ] **Step 6: Commit**

```bash
git add packages/ispectify/lib/ispectify.dart packages/ispect/lib/src/common/extensions/init.dart packages/ispect/lib/src/common/history/flutter_file_log_history_factory.dart packages/ispect/lib/src/features/log_viewer/presentation/screens/daily_sessions.dart packages/ispect/test/common/extensions/init_file_history_test.dart packages/ispectify/test/history/file_log/rolling_file_log_history_test.dart
git commit -m "feat(ispect): wire opt-in rolling file history"
```

---

### Task 9: Public documentation, changelog, and roadmap completion

**Files:**
- Modify: `docs/readme/_partials/root_body.md`
- Modify: `docs/readme/ispectify.md`
- Modify: `CHANGELOG.md`
- Modify: `ROADMAP.md`
- Generated by script: `README.md`, `packages/*/README.md`

**Interfaces:**
- Consumes: final public API from Task 8.
- Produces: copy-paste setup, retention/security explanation, migration note,
  user-facing release note, and an updated roadmap.

- [ ] **Step 1: Add a compiling setup example**

Document:

```dart
final logger = ISpectFlutter.init(
  options: ISpectLoggerOptions(maxHistoryItems: 10_000),
  fileHistory: const FileLogHistoryOptions(
    maxSessionDays: 7,
    maxFileSize: 5 * 1024 * 1024,
    maxTotalSize: 50 * 1024 * 1024,
  ),
);

ISpect.run(() => runApp(const App()), logger: logger);
```

State that storage is JSONL in application cache, redaction follows the global
toggle, web falls back to in-memory history, and `ISPECT_ENABLED` is mandatory
for internal builds but omitted from production builds.

- [ ] **Step 2: Update changelog and roadmap**

Add one current-version changelog bullet covering opt-in rolling history,
redaction-before-write, bounded retention, and legacy read compatibility.
Replace the `Next: optional file-based session history` roadmap section with a
short shipped note or remove it while retaining later priorities. Do not claim
benchmarks that were not run.

- [ ] **Step 3: Rebuild and verify generated README files**

```bash
./bash/build_readme.sh
./bash/build_readme.sh --check
```

Expected: generation succeeds and the check reports no drift.

- [ ] **Step 4: Commit documentation**

```bash
git add docs/readme README.md packages/*/README.md CHANGELOG.md ROADMAP.md
git commit -m "docs(history): document rolling file persistence"
```

---

### Task 10: Package gates, review, and independent double-check

**Files:**
- Modify only files implicated by failures or review findings.

**Interfaces:**
- Consumes: the complete implementation and approved specification.
- Produces: formatted, analyzed, tested, reviewed, and release-check-clean
  change ready for user review.

- [ ] **Step 1: Format every changed Dart file**

```bash
dart format \
  packages/ispectify/lib/src/history/file_log \
  packages/ispectify/lib/src/trace/trace_keys.dart \
  packages/ispectify/lib/src/ispectify.dart \
  packages/ispectify/lib/ispectify.dart \
  packages/ispectify/test/history/file_log \
  packages/ispectify/test/session_statistics_test.dart \
  packages/ispectify/test/ispect_logger_dispose_test.dart \
  packages/ispect/lib/src/common/extensions/init.dart \
  packages/ispect/lib/src/common/history/flutter_file_log_history_factory.dart \
  packages/ispect/lib/src/features/log_viewer/presentation/screens/daily_sessions.dart \
  packages/ispect/test/common/extensions/init_file_history_test.dart
```

Expected: formatter exits 0. Review its changed-file list for unrelated files;
if broad directory formatting touched unrelated code, restore those unrelated
format-only changes without destructive commands.

- [ ] **Step 2: Run the pure Dart package gate**

```bash
cd packages/ispectify
dart analyze --fatal-infos
dart test --coverage=coverage
```

Expected: zero analyzer issues and all tests PASS.

- [ ] **Step 3: Run the Flutter package gate**

```bash
cd packages/ispect
flutter analyze --fatal-infos
flutter test --coverage
```

Expected: zero analyzer issues and all tests PASS.

- [ ] **Step 4: Run repository docs and dependency checks**

From the repository root:

```bash
./bash/build_readme.sh --check
./bash/check_version_sync.sh
./bash/check_dependencies.sh
```

Expected: every script exits 0 with no drift or constraint mismatch.

- [ ] **Step 5: Run `command-double-check` against the original request**

Audit:

- each spec requirement against a concrete diff location;
- every deletion for accidental loss;
- redaction-before-write and explicit global opt-out;
- exact size/day/total bounds and active-file protection;
- compile-time no-op side effects;
- path traversal and import limits;
- duplicate prevention and serialized flush;
- unrelated changes and generated artifacts.

Fix every blocking finding, then rerun the affected gate and the complete
package gate. Do not declare completion from stale test results.

- [ ] **Step 6: Inspect final status and commit any audit fixes**

```bash
git status --short
git diff --check
git diff --stat main...HEAD
```

Expected: only intentional files are changed and no whitespace errors exist.
If audit fixes remain, inspect `git status --short`, stage each reported audit
file by its explicit path (never `git add .`), and commit:

```bash
git commit -m "fix(history): address rolling history audit findings"
```

Skip the final commit only when there are no post-audit changes.
