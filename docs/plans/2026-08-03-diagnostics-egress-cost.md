# Diagnostics Egress Cost Plan

Status: Complete. Phase 1 was folded into Phase 3, which is specified and
implemented in `docs/specs/2026-08-03-split-bound-and-mask-design.md`.

Measured against 7.0.0-dev5: logging a 1 KB payload fell from 129.8 µs to about
30 µs with or without console output, a 100-entry JSON Lines share from 25.5 ms
to 3.4 ms, and a 100-entry text share from 14.5 ms to 5.6 ms.

**Goal:** Recover the enabled-path CPU cost that 7.0.0-dev5 introduced, without
weakening any egress guarantee, and restore crash-reporter fidelity for
observers. Every step is Pareto-positive or it does not land.

**Context:** 7.0.0-dev5 moved bounding and redaction from the egress boundary to
capture time. The redaction engine itself got 12–23× faster, but it now runs on
every emitted entry, so a 1 KB payload log went from ~2.4 µs to ~129 µs. The
security posture that buys this is worth keeping; the redundant work inside it
is not.

**Baseline (this machine, macOS arm64, Dart 3.12.2, AOT, `maxHistoryItems: 1000`):**

| case | 6.1.7 | 7.0.0-dev5 |
| --- | --- | --- |
| `logger.metadata-only` | 2.17 µs | 4.14 µs |
| `logger.with-payload` (1 KB) | 2.41 µs | 129.3 µs |
| `logger.with-payload` (redaction off) | — | 48.9 µs |
| `redaction.1kb` (structural) | 449 µs | 37.9 µs |
| `redaction.export.1kb` | — | 84.7 µs |
| `export.json-lines.1000` | 46.2 ms | 154.9 ms |
| `export.json-lines.1000` (redaction off) | — | 7.1 ms |

Reproduce with `./bash/run_benchmarks.sh`. Numbers are indicative of ratios on
one machine, not an absolute budget.

## Invariants

No step may change any of these. A step that cannot preserve them is dropped,
not softened.

- Nothing unmasked reaches the console, the stream, an observer, an export, the
  clipboard, a generated cURL command, or persisted history.
- Redaction stays fail-closed: a value that cannot be processed is masked, never
  passed through.
- Caller-owned objects are never retained past the emit call, and caller
  formatters never run in `strict` capture mode.
- `kISpectEnabled` false keeps every path inert.
- Default sensitive-key sets and placeholders are unchanged.

## Non-goals

Decided against changing in this work, with reasons:

- **Network header capture defaults.** `printRequestHeaders` /
  `printResponseHeaders` defaulting to `true` is a deliberate product call for a
  compile-gated development tool with tested redaction. Reverting it trades UX
  for a guarantee redaction already provides.
- **Configuration surface.** `DiagnosticResourceLimits` (25 fields) and
  `DiagnosticProcessingPolicy` (20 fields) are larger than they need to be, but
  shrinking them is breaking and the presets cover the common cases. Revisit at
  8.0.0 alongside the scheduled deprecation removals.
- **Subclass hardening.** Reading package-owned private storage instead of
  overridable getters is correct. The migration note for custom log types is a
  documentation fix, not a code one.

## Steps

### Phase 0 — Make the cost separable — done

- [x] Added `logger.metadata-only.console`, `logger.with-payload.console`,
      `capture.with-payload`, and `export.history.json-lines.100`. The last one
      matters most: the pre-existing export benchmarks construct entries
      directly, so they never exercise the path the in-app share uses.
- [x] Recorded the baseline below.

Attribution of the 127.5 µs `logger.with-payload` case:

| component | µs | share |
| --- | --- | --- |
| `redactForExport` over the payload | 84.7 | 66% |
| entry capture | 16.4 | 13% |
| second capture during the egress rebuild | ~16 | 13% |
| console rendering | 6.1 | 5% |
| filter, dispatch, history, text fields | ~10 | 8% |

Two findings changed the plan. Console rendering is nearly free, so the
"console forces eager masking" argument for keeping export-grade work at emit
carries far less weight than assumed. And capture runs twice per entry — the
egress rebuild re-bounds data that was just bounded — which was not in the
original plan at all.

### Phase 1 — One envelope pass per entry — folded into Phase 3

The measurement retired this step as written. The five text-field redaction
calls hit `_redactForExport`'s short-string fast path, so merging them saves
almost nothing. The real 13% sits in the duplicate capture during the egress
rebuild, and removing it needs either a caller-settable trust flag on a
security boundary or a provenance-typed bounded value. A trust flag that
silently disables bounding when misused is not an acceptable trade for 13%, so
this work moves into Phase 3, where the provenance question is already open.

### Phase 1 — One envelope pass per entry

`_processLog` builds the egress entry field by field: `additionalData`,
`message`, `exceptionText`, `errorText`, `stackTraceText`, and `key` each go
through a separate `redactForExport` call, each constructing its own walker and
running its own normalize/scrub/bound cycle.

- [ ] Assemble one envelope, redact it with a single
      `redactEnvelopeForExport` pass, and destructure the result.
- [ ] Prove output equivalence: the existing `security_regression_test.dart` and
      `export_security_test.dart` expectations must pass unchanged.

Gate: no test edits allowed in this step. Any expectation that needs changing
means the redaction output changed — stop and reassess.

### Phase 2 — Do not redact twice — done

- [x] Provenance lives in an `Expando` in
      `lib/src/redaction/egress_provenance.dart`, matching the existing idiom in
      `ispect_theme.dart`. It keeps `ISpectLogData` immutable and gives
      consumers no constructor parameter that could claim redaction that never
      ran.
- [x] `LogExporter._jsonLine` reuses capture-time redaction only when the
      caller passed no `redactKeys` and no `redactionService`, the recorded
      service is `identical` to the one that would run now, and the resource
      limits compare equal. Every other case takes the original path.
- [x] `test/export_capture_redaction_reuse_test.dart` covers the reuse path and
      four mismatch paths: custom service, custom redact keys, reconfigured
      global policy, and entries rebuilt from persisted JSON.

Result, measured A/B on one binary pair with the reuse branch compiled out
versus in:

| case | before | after | |
| --- | --- | --- | --- |
| `export.history.json-lines.100` | 25.5 ms | 3.2 ms | 7.9× |
| `logger.with-payload` | 128.6 µs | 129.8 µs | unchanged |
| `export.json-lines.100` (no provenance) | 15.4 ms | 15.4 ms | unchanged |

The emit path is untouched and the directly-constructed export path correctly
still runs the full pass. Remaining cases sit within run-to-run noise.

Only JSON Lines reuses the mark, and it should stay that way. JSON Lines is
what `ISpectViewController.copyLogEntryText` and `copyAllLogsToClipboard` run
synchronously on the main isolate, so this is the export that janks the UI.
Text, Markdown, and CSV go through `compute(...)` in `share_all_logs_sheet.dart`
— off the UI thread, and an `Expando` mark cannot cross an isolate boundary, so
the reuse branch could never fire there. Extending it would be dead code.

Verification note: the reuse branch was temporarily made to throw, which
confirmed the two reuse tests fail and the four mismatch tests still pass — the
tests discriminate between the paths rather than passing through the old one.

### Phase 3 — Split bounding from masking

Superseded by `docs/specs/2026-08-03-split-bound-and-mask-design.md`, which
reframes this as a single-responsibility fix rather than a relocation of
redaction, carries the full boundary enumeration, and targets 7.1.0. The
enumeration found that the console reaches into the payload for network
entries, which breaks the clean eager/lazy field split assumed below.

**This is the only step with a threat-model question, and it needs explicit
ratification before implementation.**

`_redactForExport` runs five traversals: bound → replace truncated prefixes →
structural redaction → free-text credential scrub → bound again. The free-text
scrub exists to catch secrets embedded in prose (`"Auth failed: Bearer eyJ…"`).

Hypothesis: the structural pass is what severs the caller's object graph and
bounds memory, and it must stay eager. The free-text scrub only matters where
free text is produced — console rendering, export, clipboard, cURL, and observer
delivery — and could move there.

- [ ] Enumerate every boundary that turns an entry into text or hands it to
      third-party code. If even one cannot be proven covered, drop this phase.
- [ ] If covered: apply the structural pass at capture and the scrub at each
      boundary, memoized per entry so a row read twice is scrubbed once.
- [ ] Threat-model note: history would then hold bounded-but-unscrubbed free
      text for the session. Weigh against the fact that the host app already
      holds those values. Record the decision either way in `docs/SECURITY.md`.

Gate: ratification before code. Then the full security suite plus a new test
per enumerated boundary.

### Phase 4 — Observer fidelity for crash reporters

Observers currently receive a synthetic error object and a stringified stack
(`StackTrace.empty` on the error). That is correct for redaction and wrong for
anyone forwarding to Crashlytics or Sentry.

- [ ] Do not weaken observer redaction. Instead document `ISpect.run`'s error
      callbacks as the supported crash-forwarding path — they still receive the
      original error and stack.
- [ ] Add the migration note to `docs/DEPRECATIONS.md` and the 7.0.0 breaking
      changes (done in CHANGELOG; mirror it in the docs).
- [ ] If a real need for structured forwarding remains after that, design an
      explicit opt-in seam rather than relaxing the default.

Gate: docs check; no behavioral change unless the seam is separately ratified.

### Phase 5 — Publish honest numbers — done

- [x] `docs/PERFORMANCE.md` now states what capture-time redaction costs, that
      roughly two thirds of the payload case is redaction of the payload
      itself, and that `strict` capture does not reduce it — only capturing
      less does.
- [x] Named the concrete levers with their real API shapes: `metadataOnly()`
      lives on the settings *builders*, not the settings classes, and the
      database package has no such preset.

### Phase 3 — remaining scope

Phase 3 is now the only open perf work, and it carries the whole remaining gap:
about two thirds of the payload-logging cost. It stays unratified because it is
the one step that changes what history holds. Note when reopening it that the
comparison is against 7.0.0's eager masking, not against 6.1.7 — 6.1.7 retained
raw caller references, so lazy masking over a bounded snapshot would still be
an improvement on that older baseline.

Parity with 6.1.7's ~2.4 µs is not a target. That number came from storing a
reference and doing no work; any design that redacts at capture is an order of
magnitude above it by construction.

## Verification

Per package, per phase:

- `dart analyze --fatal-infos` / `flutter analyze --fatal-infos`
- `flutter test --dart-define=ISPECT_ENABLED=true --coverage`
- `dart test --run-skipped test/production_safety_test.dart`
- `./bash/run_benchmarks.sh` compared against the Phase 0 baseline
- `./bash/build_readme.sh --check`

A phase that improves a benchmark but changes any redaction expectation is a
failed phase.
