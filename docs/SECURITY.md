# Security and Data Handling

ISpect is a diagnostics toolkit. It can capture logs, network metadata, request/response payloads, database trace arguments, BLoC events/states, navigation events, exported sessions, and observer events depending on how you configure it.

The default posture is conservative, but teams must still treat ISpect output as sensitive.

## Production Builds

ISpect is controlled by the compile-time `ISPECT_ENABLED` flag. Do not pass `--dart-define=ISPECT_ENABLED=true` to production release builds unless your organization has explicitly approved that policy.

Recommended release rule:

```bash
# Internal QA / staging only
flutter run --dart-define=ISPECT_ENABLED=true

# Production release
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

## Redaction

Network redaction is enabled by default. The shared redaction engine covers common sensitive keys and patterns, including authorization headers, cookies, tokens, passwords, API keys, credentials, PII fields, phone numbers, and financial data.

Automatic redaction cannot know every domain-specific field. Add custom keys for values such as:

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

Prefer capturing less data before relying on redaction.

Recommended defaults for shared QA, staging, and support builds:

- keep request/response body capture disabled unless needed;
- keep headers disabled unless debugging authentication, caching, or routing;
- project database traces to counts, IDs, timings, and status instead of full rows;
- avoid logging raw user input with `logger.info(...)`;
- avoid exporting sessions that contain customer production data.

## Exports and Observers

Exported sessions are plain-text artifacts. Observer hooks can forward events to Sentry, Crashlytics, Grafana, or a custom backend through your own adapter. Treat both exports and observer payloads as sensitive, even when redaction is enabled.

Before enabling observers:

- review which categories are forwarded;
- apply server-side retention and access controls;
- avoid forwarding full payloads when metadata is enough;
- verify that your backend is approved for the data class being sent.

## Reporting Security Issues

Please do not open public issues for suspected security problems. Send a private report to the project maintainer with:

- affected package and version;
- reproduction steps;
- expected and actual redaction behavior;
- whether exported logs, observer events, or release builds are affected.

The maintainer will coordinate a fix and disclose details after patched versions are available.
