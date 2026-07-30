# Security and Data Handling

ISpect is a pre-release diagnostics toolkit. On an internal build, it captures whatever streams you enable: logs, network requests and responses, database trace arguments, BLoC events and states, Riverpod provider lifecycle events, navigation events, exported sessions, and observer events.

The default posture favors useful diagnostics in internal builds: network
payloads, headers, exceptions, stack traces, and state values are visible after
bounded redaction. Balanced capture may call application-defined `toJson()` or
`toString()` inside guarded boundaries, then immediately bounds the result.
Compile-time gating and the shared redaction policy remain mandatory defaults,
while strict capture and per-integration compact or metadata-only presets let
teams opt into stronger execution and data-minimization guarantees. The team
using ISpect still has to handle the output according to the data class it
contains.

The shared redaction pipeline is what sets ISpect apart from a plain log viewer. One configurable default policy covers core logs, traces, persistence, supported interceptors, database diagnostics, state observers, export flows, clipboard helpers, cURL generation, and observer payloads. A request masked in the viewer stays masked in every place it can leak.

## Production builds

ISpect is controlled by the `ISPECT_ENABLED` compile-time flag. It is not a runtime switch, and it does not enable itself in production. A release pipeline opts in only when it explicitly passes `--dart-define=ISPECT_ENABLED=true`.

```bash
# Internal dev, QA, staging.
flutter run --dart-define=ISPECT_ENABLED=true

# Production release. Flag omitted.
flutter build apk
```

Add an environment guard when the same pipeline produces multiple non-production channels:

```dart
class ISpectConfig {
  static const bool isEnabled = bool.fromEnvironment('ISPECT_ENABLED');
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get shouldInitialize => isEnabled && environment != 'production';
}
```

CI policy:

- Production jobs do not pass `--dart-define=ISPECT_ENABLED=true`.
- Public production deployments, including the web logs viewer on GitHub
  Pages, do not pass the flag.
- Internal dev, QA, and staging jobs may pass it explicitly.
- The repository's `production_safety.yml` workflow exercises direct disabled
  APIs in every diagnostics package and builds a release APK without the flag.
- Any intentional production enablement should be reviewed as a separate internal policy decision.

## Redaction

Network redaction is on by default. The shared engine covers common sensitive keys and patterns: authorization headers, cookies, tokens, passwords, API keys, credentials, PII, phone numbers, and financial data.

Redaction applies to complete diagnostic envelopes, not only structured body
maps. Free-form messages, exception and stack strings, embedded URLs,
percent-encoded nested URLs, authentication schemes, prose assignments,
typed binary data, absolute filesystem paths, string-encoded JSON, export
metadata, clipboard/share content, and persisted JSON Lines are scanned before
they cross an outbound boundary.

Outbound redaction is enabled when export APIs are called without a custom
policy. Disabling it requires an explicit per-export or global opt-out and
should be limited to controlled local debugging.

An opt-out changes content masking, not the defensive output boundary.
Diagnostic values remain size-bounded. The balanced default may invoke guarded
application-defined `toJson()` or `toString()` while the value is first
captured; `DiagnosticCaptureMode.strict` disables those calls. Persistence,
exports, and observer fan-out operate on the captured snapshot and never
re-invoke application formatters.
The caller's validated `DiagnosticResourceLimits` remains authoritative
through every redaction and outbound normalization pass: `extended` never
disables redaction, and `constrained` is never widened internally.

Domain-specific fields belong to the application team. Register custom keys for values such as tenant identifiers, internal account numbers, organization-specific tokens, customer references, business-sensitive IDs, and proprietary request fields. Extend the safe defaults through the global policy:

```dart
ISpectRedaction.configure(
  service: RedactionService(
    additionalSensitiveKeys: {
      'x-tenant-token',
      'customer_reference',
      'internal_account_id',
    },
    additionalSensitiveKeyPatterns: [
      RegExp(r'^partner_credential_\w+$', caseSensitive: false),
    ],
  ),
);
```

`additionalSensitiveKeys` and `additionalSensitiveKeyPatterns` preserve the built-in protection. The replacement parameters `sensitiveKeys` and `sensitiveKeyPatterns` remain available for deliberate policy replacement. An explicit service supplied to one integration takes precedence over the global service; otherwise even already-created integrations resolve the current global policy per diagnostic operation. Runtime configuration is scoped to the current Dart isolate.

`ISpectRedaction.enabled = false` remains the global content-masking opt-out.
Local `enableRedaction` flags can disable masking for one integration. Neither
form disables output bounds, storage checks, the selected capture mode, or the
compile-time `ISPECT_ENABLED` gate.

## Data minimization

Defaults favor useful redacted diagnostics. Use the stricter presets when a
session does not need payload values.

Optional hardening for shared internal builds:

- Use `logRequests: false` and `logResponses: false` (or an errors-only
  production preset) when routine network records are unnecessary.
- Use the Dio, HTTP, or WebSocket `metadataOnly()` preset when request and
  response bodies are unnecessary. These presets select strict capture.
- Use `ISpectBlocSettings.compact` or `ISpectRiverpodSettings.compact` when
  lifecycle visibility is enough without values. These presets also select
  strict capture.
- Select `DiagnosticCaptureMode.strict` directly on logger, adapter, observer,
  or database settings when application-defined formatters must never run.
- Project database traces to counts, IDs, timings, and status fields instead of full rows.
- Do not pipe raw user input through `logger.info(...)`.
- Supply device model metadata only. Never attach serial numbers, advertising
  IDs, installation IDs, or another stable device identifier.
- Export sessions only through the channels approved for the data class they contain.

A safe rollout:

1. Start with the default redacted diagnostics in an isolated internal build.
2. Switch noisy or higher-risk integrations to `metadataOnly()` or `compact`.
3. Add domain-specific redaction keys before sharing logs outside the engineering team.
4. Apply filters and sampling to noisy categories.
5. Review observer adapters before pointing them at external systems.

## Exports and observers

Exported sessions are plain-text artifacts for internal diagnostic handoff.
Supported export paths run them through the same redaction pipeline before
writing. Native shares use a dedicated temporary directory rather than the
durable logs directory; explicit downloads remain durable until the host or
user removes them. Generated cURL commands redact by default and use
`--data-raw` so an `@`-prefixed body cannot be interpreted as a local file.
Imported JSON sessions are bounded and pass through the active redaction
policy before they are retained. `enableRedaction: false` is the explicit
local opt-out for controlled raw-session analysis.

Structured values are bounded to 256 KiB, individual records to 1 MiB, and
complete JSON exports to 32 MiB. Export metadata includes `totalLogs`,
`exportedLogs`, and `truncated`, so a partial handoff is explicit. Use
`LogsJsonService.importFromJsonWithReport(...)` when the caller must surface
invalid records that were skipped.

Observer hooks receive a redacted copy by default before forwarding selected
events to an internal tool. Disabling `ISpectRedaction.enabled` is the explicit
content-redaction opt-out for both exports and observers. Ordinary supported
values remain visible, but output bounds and the selected capture mode still
apply. Handle either form according to the data class it contains.

Before enabling an observer:

- Review which categories are forwarded.
- Apply retention and access controls on the receiving side.
- Avoid forwarding full payloads when metadata is enough.
- Confirm the receiving system is approved for the data class being sent.

Export handling is left to the application team's policy on purpose. Teams use different channels for QA, design review, and pre-release debugging. ISpect provides redacted export paths. The project decides where exported diagnostic files may be stored, shared, and retained.

## Local file-history trust boundary

Rolling file history must use an existing app-private directory supplied by
the host. On POSIX platforms, ISpect requires the provider to be owner-only;
its traversal permissions protect child artifacts even when the process umask
creates more permissive child modes. Managed session and date directories
must not be writable by the group or by everyone. ISpect also rejects
symbolic-link artifacts, confines managed names to the resolved history root,
bounds every read and write, and revalidates paths around open handles.
Persistence never invokes supplied `Exception`, `Error`, or `StackTrace`
formatting methods after capture. In strict mode, exceptions and errors use a
bounded safe descriptor and stack fields use a fail-closed marker. In balanced
mode, their guarded text snapshots are already bounded before persistence sees
them.

Public cross-platform `dart:io` does not expose an atomic no-follow open or the
inode/file ID behind a `RandomAccessFile`. Consequently, those checks detect
ordinary replacement races but cannot prove safety against an active process
running as the same OS principal that can perform a same-size double swap
during a file open. That same-principal namespace attacker is outside the
rolling-history threat model. Apps exposed to it should keep the default
in-memory history or place persistence behind a platform-native service that
uses `openat`/`fstat` on POSIX and handle-based reparse-point checks on Windows.

## Reporting security issues

Do not open a public issue for a suspected security problem. Send a private report to the project maintainer with:

- The affected package and version.
- Reproduction steps.
- Expected and actual redaction behavior.
- Whether exported logs, observer events, or release builds are affected.

The maintainer will coordinate a fix and disclose details after patched versions are available.
