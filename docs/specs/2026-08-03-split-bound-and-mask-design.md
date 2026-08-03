# Splitting Bounding From Masking

Status: Implemented

The duplicated redaction in `toText` and `toMarkdown` is now gated too. `toCsv`
never shared it — it is an overview format that omits nested metadata, so
`_redactAdditionalData` has only those two callers.

The gate could not simply skip `_redactAdditionalData`. That helper also applies
the per-record display budget and `stripPrivateKeys: true`, and capture applies
neither, so skipping the whole call would leak internal `_`-prefixed keys such
as the network renderer's `_render-hints`. Only the `redactForExport` call
inside it is suppressed, behind `reuseCaptureRedaction`.

Measured back-to-back on one binary pair, controls flat at 0.95×:
`export.history.text.100` falls from 14.53 ms to 5.60 ms, a 2.60× reduction.
That is essentially the whole upper bound a spike had predicted, confirming
`redactForExport` was the dominant cost in that helper.

The gate compares the mark against the service that would actually run
(`redactionService ?? ISpectRedaction.service`), not against `null` —
`LogExporter` resolves the service before delegating, so a null check never
fires there.

Landed: masking of `additionalData` is deferred to first read and memoized on
the entry, injected as a `DiagnosticMasker` function so the model never depends
on `RedactionService`. A capture stamp on the frozen bounded map lets the egress
rebuild skip a second bound when the limits and oversized-string handling match.
Measured 129.8 → 41.9 → 30.5 µs for a 1 KB payload log, a 4.3× reduction.

The stamp records only the budget and the oversized-string flag, not the
`allowCustom*` pair. After any bound, every value is already a JSON primitive,
map, or list, so a later pass in either capture mode finds nothing left to
convert and is a no-op.

Still open: the console sink reads through the masked accessor, so it forces
the full mask on every entry when `useConsoleLogs` is true, which is the
shipped default. That configuration measures at parity with the previous
behaviour rather than gaining.

Giving the console raw access is not a valid fix. `NetworkLogRenderer._displayUrl`
calls `_readableRedactionMarkers` on the URL and reads query parameters from
`additional-data → payload → request`, so it relies on the payload already
being masked. Reading raw there would print unmasked query secrets to the
console. Any fix must have the renderer mask the request subtree itself, which
is correct SRP — it is the component that owns network schema knowledge — but
it means network entries still mask more than a scalar projection would.

Platform note: both the capture stamp and the export provenance use `Expando`
from `dart:core`, which is available on the VM, dart2js, and WASM, and neither
key is a type `Expando` rejects. No `dart:io` or other platform API entered
this change.

## Problem

7.0.0 fused two operations into one eager pass at emit:

- **Bounding** — snapshot the value, sever the caller's object graph, cap size
  and depth, refuse to run caller formatters in `strict` mode.
- **Masking** — replace sensitive values structurally by key and pattern, then
  scrub remaining free text for embedded credentials.

Bounding must be eager. It is what stops a diagnostic from mutating under the
viewer, from retaining arbitrary application objects for the session, and from
executing `toString()` inside the log viewer at render time. 6.1.7 did none of
this and was wrong for it.

Masking only has to be true at a boundary. Fusing it into the eager pass means
every emitted entry pays for protection that only the entries someone actually
reads ever need. Measured on one macOS arm64 run: bounding a 1 KB payload costs
16.4 µs, masking it costs 84.7 µs. A QA session that emits 10,000 entries and
displays 50 pays the 84.7 µs about 200 times more often than any boundary
consumes it.

This is a single-responsibility problem, not a "redaction is in the wrong place"
problem. The fix is to separate the two, not to move either one.

## Target shape

- Bound eagerly, exactly as today.
- Mask on first crossing of a boundary, memoized per entry so a row read twice,
  or read and then exported, masks once.
- Keep the fail-closed guarantee by construction: the unmasked bounded form is
  reachable only through package-internal accessors, and every public reader
  returns the masked form.

## Boundary enumeration

The gate for this design. Masking must be proven to run at every one of these
before any code changes.

| # | Boundary | Timing | Consumes |
| --- | --- | --- | --- |
| 1 | Console sink | synchronous at emit | message, key, level, time, exception, stack, plus named trace scalars |
| 2 | Console sink, network entries | synchronous at emit | **also reaches into the payload** — see below |
| 3 | Stream listeners | synchronous at emit | whole entry |
| 4 | Observers | synchronous at emit | whole entry |
| 5 | Log viewer UI | lazy, per visible row | whole entry |
| 6 | JSON Lines export and clipboard copy | lazy, main isolate | whole entry |
| 7 | Text, Markdown, CSV export | lazy, background isolate | whole entry |
| 8 | cURL generation | lazy | `request-options` subtree |
| 9 | Rolling file history | on write | whole entry |
| 10 | Import preflight | on read | external input, already masked separately |

### The complication found at boundary 2

`NetworkLogRenderer.renderHeadline` builds the console line for network entries
from `TraceKeys.target` and the request query parameters nested under the
payload. So the console does not consume only scalar trace keys — it reaches
into `additional-data → payload → request`, and a URL carries query secrets
that must be masked.

This kills the clean split of "cheap eager fields versus expensive lazy
payload". Any implementation must either mask that specific path eagerly for
network entries, or make the renderer pull from the masked accessor. The second
is better — it keeps the model from knowing what the console renders — but it
means the masked accessor has to be available synchronously at emit anyway for
entries the console will print.

### Consequence for boundaries 3 and 4

Stream listeners and observers receive the whole entry synchronously. When
either is attached, masking is eager regardless of this design. The lazy win
applies only to history-only configurations, which is the common case for the
in-app viewer but not universal.

## Two traps for the implementer

### The second bound is not redundant

It is tempting to look at `_redactForExport` running `boundJsonValue` over data
the `ISpectLogData` constructor just bounded and remove one of them. They are
not the same pass. `_captureAdditionalData` bounds with
`allowCustomSerialization` and `allowCustomStringification` set from the capture
mode, so in `balanced` it may run caller `toJson`/`toString`. The pass inside
`_redactForExport` leaves both `false`. The second traversal is what guarantees
no caller formatter runs again on the way out, so short-circuiting it removes a
control rather than removing duplicated work.

Any provenance marker used to skip a bound must therefore record the full flag
combination — `maxBytes`, `preserveTypes`, `replaceOversizedStrings`,
`stripPrivateKeys`, and both `allowCustom*` flags — not just the byte budget.

### Lazy alone buys nothing in the default configuration

`useConsoleLogs` is `true` in the shipped defaults
(`settings_manager.dart`, `ispect_scope.dart`), and the console sink is
synchronous at emit. Deferring the mask without also changing what the console
does means the console forces it on every entry and the win never appears. The
log viewer, by contrast, reads history rather than subscribing to
`ISpectLogger.stream`, so the stream usually has no listener.

This is why the design is "each boundary masks what it emits" rather than
"mask lazily". The console emits four named trace scalars plus, for network
entries, the target URL — masking those directly is cheap and leaves the bulk
payload unmasked until something actually reads it.

## Interaction with the shipped export reuse

The `Expando` provenance landed in 7.0.0-dev5 makes `LogExporter.toJsonLines`
skip re-masking because history is known to be pre-masked. This design removes
that property, so the provenance check has to invert: it must record that an
entry has been masked *at all*, and the export path becomes the first masker
rather than a second one. Total work per read entry is unchanged; work per
unread entry drops to zero.

Do not implement this design without revisiting
`lib/src/redaction/egress_provenance.dart` in the same change.

## Cost of the change

57 read sites across 18 files, concentrated in `ispectify` (14 files) and
`ispect` (4). The semantics of the public `ISpectLogData.additionalData` getter
change from "already masked" to "masked on read", and memoization state has to
live outside the `@immutable` model, as the provenance mark already does.

## Why this is the only remaining lever

Two cheaper alternatives were investigated against the code and both failed:

- **Skip the duplicated bound.** Rejected — the two passes use different
  `allowCustom*` flags, so one of them is a control, not duplication.
- **Defer masking without touching consumers.** Rejected — the console is on by
  default and synchronous, so it forces the mask anyway.

What remains is this design. It alters the central data model, inverts an
optimization landed in the same release, and changes what a public getter
guarantees. A mistake in it is a redaction bug, which is the one class of defect
this toolkit exists to prevent, so it wants its own review cycle and its own
red-green pass over the ten boundaries rather than being appended to an
in-flight release.

## Expected result

Emitting a 1 KB payload log should fall from about 130 µs toward the roughly
50 µs measured with redaction disabled, because masking stops running for
entries nobody reads. Boundary consumers pay the same 84.7 µs they pay today,
once per entry actually read, memoized.

## Non-goal

Parity with 6.1.7's ~2.4 µs per payload log. That number came from storing a
reference and doing no work at all. Any design that bounds at capture is an
order of magnitude above it by construction, and bounding at capture is correct.
