---
name: ispect-read-logs
description: >-
  Read redacted ISpect logs, errors, and HTTP or database traces from a running Flutter debug or profile build through the ext.ispect VM service extensions, to diagnose a failure without the in-app panel.
---

# Read logs from a running Flutter app

`ISpect.run` and `ISpect.initialize` register read-only VM service extensions
in builds compiled with `ISPECT_ENABLED=true`. Query them to see what the app
logged instead of asking the user to copy logs from the panel.

## Connect

1. Run the app with `flutter run --dart-define=ISPECT_ENABLED=true`, or add
   `--profile`. Release builds have no VM service.
2. Copy the URI from the `A Dart VM Service on ... is available at:` line, for
   example `http://127.0.0.1:50123/AbCd=/`.
3. From the app root, call a method with `scripts/ispect_logs.dart` in this
   skill's directory. It accepts the printed URI or its `ws://.../ws` form and
   the method name with or without the `ext.ispect.` prefix, and prints the
   JSON reply.

```bash
dart run <skill-dir>/scripts/ispect_logs.dart \
  http://127.0.0.1:50123/AbCd=/ getLogs minLevel=error limit=20
```

The script imports `package:vm_service`, which Flutter apps resolve through
the SDK's test dependencies. If resolution fails, add it with
`flutter pub add dev:vm_service`. Other VM service clients, such as an MCP
server or DevTools, call the full `ext.ispect.*` names with the same string
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
`http-error`, `ws-error`, `bloc-error`, `riverpod-fail`, `db-error`, `route`.
`topKeys` in `getSummary` lists the keys this app actually logs.

## Workflow

1. Call `getSummary`, then `getLogs` with `minLevel=error` or the keys of the
   failing area.
2. Call `getLog` for each suspicious entry. When an entry carries a
   `correlationId` (HTTP and WebSocket entries, database calls inside
   `dbTransaction`), call `getTrace` with it to see the related entries
   together.
3. To capture a reproduction, keep the `cursor` from a `getLogs` call, ask for
   the reproduction, then call `getLogs` with `afterId` set to that cursor.

## Boundaries

Replies carry the same redaction and size limits as a JSON Lines export.
Masked values stay masked; do not turn redaction off to read them. `query`
matches values before redaction, so a hit can come from a masked field.
Replies can still contain user content: keep them in the debugging session.

The extensions are read-only, and history holds at most `maxHistoryItems`
entries, so the oldest entries drop first. An `invalidParams` reply says how
to fix the call. A "not initialized" reply means ISpect has not started or
was disposed. When the script reports that no isolate registers `ext.ispect.*`
methods, the build is missing the define or ISpect has not initialized.
