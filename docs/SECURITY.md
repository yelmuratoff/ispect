# Security and Data Handling

ISpect is an internal pre-release diagnostics toolkit. It captures the streams you configure for development, QA, staging, dogfooding, and design-review builds: logs, network metadata, optional request/response payloads, database trace arguments, BLoC events/states, navigation events, exported sessions, and observer events.

The default posture is conservative: ISpect is compile-time gated, network redaction is enabled by default, and payload/header capture can be limited through settings. Teams should still handle ISpect output according to the data it contains.

Compared with plain log viewers, ISpect provides a shared redaction pipeline for supported interceptors, export flows, clipboard helpers, cURL generation, and observer payloads. The goal is safer pre-release diagnostics by default, while keeping capture scope and external forwarding explicit.

## Production Builds

ISpect is controlled by the compile-time `ISPECT_ENABLED` flag. It is not a runtime switch and ISpect does not enable itself in production. Public production release pipelines normally omit `--dart-define=ISPECT_ENABLED=true`; passing the flag is an explicit build configuration choice for internal builds.

Recommended release rule:

```bash
# Internal dev / QA / staging only
flutter run --dart-define=ISPECT_ENABLED=true

# Production release: flag omitted
flutter build apk
```

Use an additional environment guard when your pipeline has multiple non-production channels:

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

Recommended CI policy:

- production jobs do not pass `--dart-define=ISPECT_ENABLED=true`;
- internal dev/QA/staging jobs may pass the flag explicitly;
- release artifacts can be checked with the repository's `production_safety.yml` workflow;
- any intentional public-production enablement should be reviewed as a separate internal policy decision.

## Redaction

Network redaction is enabled by default. The shared redaction engine covers common sensitive keys and patterns, including authorization headers, cookies, tokens, passwords, API keys, credentials, PII fields, phone numbers, and financial data.

Domain-specific fields should be registered by the application team. Add custom keys for values such as:

- tenant identifiers;
- internal account numbers;
- organization-specific tokens;
- customer references;
- business-sensitive IDs;
- proprietary request fields.

Example:

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

## Data Minimization

Prefer focused capture before relying on broad payload logging.

Recommended defaults for shared dev, QA, staging, dogfooding, and design-review builds:

- keep request/response body capture disabled unless needed;
- keep headers disabled unless debugging authentication, caching, or routing;
- project database traces to counts, IDs, timings, and status instead of full rows;
- avoid logging raw user input with `logger.info(...)`;
- export sessions only through the channels approved for the data they contain.

Recommended rollout:

1. Start with the debug panel, structured logs, and metadata-only network diagnostics.
2. Enable body/header capture only for targeted debugging sessions.
3. Add domain-specific redaction keys before sharing logs outside the engineering team.
4. Use filters and sampling for noisy categories.
5. Review observer adapters before forwarding data to external systems.

## Exports and Observers

Exported sessions are plain-text artifacts for internal diagnostic handoff, and supported export paths apply the shared redaction pipeline before writing data out. Observer hooks can forward selected events to internal tools through your own adapter. Handle both exports and observer payloads according to the data classes they contain.

Before enabling observers:

- review which categories are forwarded;
- apply server-side retention and access controls;
- avoid forwarding full payloads when metadata is enough;
- verify that the internal destination is approved for the data class being sent.

Export handling is intentionally left to the application team's policy because teams use different channels for QA, design review, and pre-release debugging. ISpect provides redacted export paths; the project decides where exported diagnostic files may be stored, shared, and retained.

## Reporting Security Issues

Please do not open public issues for suspected security problems. Send a private report to the project maintainer with:

- affected package and version;
- reproduction steps;
- expected and actual redaction behavior;
- whether exported logs, observer events, or release builds are affected.

The maintainer will coordinate a fix and disclose details after patched versions are available.
