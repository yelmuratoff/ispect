# Use Cases

ISpect runs inside internal builds where attaching a debugger is inconvenient or impossible: dev machines, QA devices, staging, dogfood and design-review builds. It is not for public production releases.

## QA reproduction

A tester reproduces a bug in a QA build with `ISPECT_ENABLED=true`, opens the in-app panel, filters the logs around the failing flow, and exports a diagnostic session. Network, BLoC, Riverpod, navigation, and database entries appear together in one viewer instead of having to be reconstructed from separate console logs.

## Staging verification

A team validates a staging release with metadata-only network capture, redaction on, and project-specific keys configured. Body capture stays off until a payload-level issue needs investigation.

## Internal handoff

A tester, designer, QA engineer, or developer exports a diagnostic session from an internal build and shares it through the team's approved channel. Supported export paths apply the shared redaction pipeline before writing data out.

## Local development

ISpect runs alongside Flutter DevTools. DevTools handles profiling, memory, CPU, and debugger workflows. ISpect adds an in-app view of logs, requests, state transitions, navigation, and exported sessions.

## Not for

- Replacing production crash reporting or release-health systems.
- Capturing every payload by default.
- Bypassing an organization's policy for diagnostic files.
- Enabling diagnostics in public production release builds.
