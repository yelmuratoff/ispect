---
name: ispectify-read-logs
description: >-
  Read redacted ispectify logs, errors, and traces from a running Dart process through the ext.ispect VM service extensions, including registering them in an app that does not use the Flutter ISpect package.
---

# Read logs from a running Dart app

`ISpectServiceExtensions` exposes the logger history as read-only VM service
extensions in builds compiled with `ISPECT_ENABLED=true`. The Flutter `ispect`
package registers them in `ISpect.run`; a pure Dart app registers its own
logger once at startup:

```dart
ISpectServiceExtensions.register(() => logger);
```

The callback runs on every call, so returning a replaced logger needs no
second registration; returning `null` answers "not initialized".

## Connect

1. Run with the VM service enabled:
   `dart run --enable-vm-service -DISPECT_ENABLED=true bin/main.dart`.
   For Flutter, use `flutter run --dart-define=ISPECT_ENABLED=true`.
2. Copy the URI from `The Dart VM service is listening on`, for example
   `http://127.0.0.1:8181/AbCd=/`.
3. From the app root, call a method with `scripts/ispect_logs.dart` in this
   skill's directory. It accepts the printed URI or its `ws://.../ws` form and
   the method name with or without the `ext.ispect.` prefix, and prints the
   JSON reply.

```bash
dart run <skill-dir>/scripts/ispect_logs.dart \
  http://127.0.0.1:8181/AbCd=/ getLogs minLevel=error limit=20
```

The script imports `package:vm_service`; add it with
`dart pub add dev:vm_service` when the app does not resolve it. Other VM
service clients call the full `ext.ispect.*` names with the same string
arguments.

## Methods

- `ext.ispect.getSummary`: entry and level counts, `errorCount`, `topKeys`,
  and `recentErrors`. Start here.
- `ext.ispect.getLogs`: compact entries for the newest matches, listed oldest
  first.
  - `minLevel`: `critical`, `error`, `warning`, `info`, `debug`, or `verbose`;
    keeps that level and more severe ones. Entries without a level never
    match, so it can return fewer entries than `errorCount`; filter by `keys`
    when the counts disagree.
  - `keys`: comma-separated log keys, such as `http-error,db-error`.
  - `query`: text matched against captured values.
  - `limit`: page size, default 50, maximum 200.
  - `beforeId`: pass the first returned `id` to page back while `hasMore` is true.
  - `afterId`: pass the returned `cursor` to read only entries logged since
    then; repeat with each new `cursor` while `hasMore` is true.
- `ext.ispect.getLog` with `id`: the full redacted record. Compact entries
  truncate text and can show only an error type, with the message under
  `additional-data`, so read the full record before drawing conclusions.
- `ext.ispect.getTrace` with `id` set to a `correlationId` or `transactionId`
  value from an entry, not the entry `id`: up to 200 entries for one HTTP call,
  WebSocket connection, or database transaction, oldest first.

Common keys: `error`, `exception`, `http-request`, `http-response`,
`http-error`, `ws-error`, `bloc-error`, `riverpod-fail`, `db-error`, plus the
`errorKey` of each custom `ISpectTraceCategory`. `topKeys` in `getSummary`
lists the keys this app actually logs.

## Workflow

1. Call `getSummary`, then `getLogs` with `minLevel=error` or the keys of the
   failing area.
2. Call `getLog` for each suspicious entry. When an entry carries a
   `correlationId` (HTTP and WebSocket entries, database calls inside
   `dbTransaction`), call `getTrace` with it to see the related entries
   together.
3. To capture a reproduction, keep the `cursor` from a `getLogs` call, trigger
   the failing path, then call `getLogs` with `afterId` set to that cursor.

## Boundaries

Replies carry the same redaction and size limits as a JSON Lines export.
Masked values stay masked; do not turn redaction off to read them. `query`
matches values before redaction, so a hit can come from a masked field.
Replies can still contain user content: keep them in the debugging session.

The extensions are read-only, and history holds at most `maxHistoryItems`
entries, so the oldest entries drop first. Registration is a no-op without
the define. An `invalidParams` reply says how to fix the call. When the script
reports that no isolate registers `ext.ispect.*` methods, the process is
missing the define or has not reached `register` yet.
