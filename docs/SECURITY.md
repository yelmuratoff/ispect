# Security and Data Handling

ISpect is a pre-release diagnostics toolkit. On an internal build, it captures whatever streams you enable: logs, network metadata, optional request and response payloads, database trace arguments, BLoC events and states, navigation events, exported sessions, and observer events.

The default posture is conservative. Compile-time gating, network redaction on by default, and per-interceptor settings let you keep payload and header capture narrow. The toolkit gives you safer defaults. The team using it still has to handle the output according to the data class it contains.

The shared redaction pipeline is what sets ISpect apart from a plain log viewer. The same redactor runs across interceptors, export flows, clipboard helpers, cURL generation, and observer payloads. A request masked in the viewer stays masked in every place it can leak.

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
- Internal dev, QA, and staging jobs may pass it explicitly.
- Release artifacts can be checked with the repository's `production_safety.yml` workflow.
- Any intentional production enablement should be reviewed as a separate internal policy decision.

## Redaction

Network redaction is on by default. The shared engine covers common sensitive keys and patterns: authorization headers, cookies, tokens, passwords, API keys, credentials, PII, phone numbers, and financial data.

Domain-specific fields belong to the application team. Register custom keys for values such as tenant identifiers, internal account numbers, organization-specific tokens, customer references, business-sensitive IDs, and proprietary request fields.

```dart
final redactor = RedactionService(
  sensitiveKeys: {
    ...defaultSensitiveKeys,
    'x-tenant-token',
    'customer_reference',
    'internal_account_id',
  },
);
```

## Data minimization

Capture metadata first. Reach for broad payload logging only when metadata is not enough.

Defaults that work for shared internal builds:

- Keep request and response body capture off unless you need it.
- Keep headers off unless you are debugging auth, caching, or routing.
- Project database traces to counts, IDs, timings, and status fields instead of full rows.
- Do not pipe raw user input through `logger.info(...)`.
- Export sessions only through the channels approved for the data class they contain.

A safe rollout:

1. Start with the debug panel, structured logs, and metadata-only network diagnostics.
2. Turn body and header capture on for a specific debugging session, then turn it back off.
3. Add domain-specific redaction keys before sharing logs outside the engineering team.
4. Apply filters and sampling to noisy categories.
5. Review observer adapters before pointing them at external systems.

## Exports and observers

Exported sessions are plain-text artifacts for internal diagnostic handoff. Supported export paths run them through the same redaction pipeline before writing. Observer hooks can forward selected events to internal tools through your own adapter. Both should be handled according to the data class they contain.

Before enabling an observer:

- Review which categories are forwarded.
- Apply retention and access controls on the receiving side.
- Avoid forwarding full payloads when metadata is enough.
- Confirm the receiving system is approved for the data class being sent.

Export handling is left to the application team's policy on purpose. Teams use different channels for QA, design review, and pre-release debugging. ISpect provides redacted export paths. The project decides where exported diagnostic files may be stored, shared, and retained.

## Reporting security issues

Do not open a public issue for a suspected security problem. Send a private report to the project maintainer with:

- The affected package and version.
- Reproduction steps.
- Expected and actual redaction behavior.
- Whether exported logs, observer events, or release builds are affected.

The maintainer will coordinate a fix and disclose details after patched versions are available.
