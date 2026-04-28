# Use Cases

ISpect is intended for internal in-app diagnostics in dev, QA, staging, dogfooding, and design-review builds where attaching a debugger is inconvenient or impossible. It is not intended to be enabled in public production releases.

## QA Reproduction

A tester reproduces a bug in a QA build with `ISPECT_ENABLED=true`, opens the in-app panel, filters logs around the failing flow, and exports a diagnostic session. Network, BLoC, navigation, and database entries can be reviewed together instead of reconstructed from separate console logs.

## Staging Verification

A team validates a staging release with metadata-only network capture, redaction enabled, and project-specific keys configured. Body capture can stay off until a payload-level issue needs investigation.

## Internal Handoff

A tester, designer, QA engineer, or developer can export a diagnostic session from an internal build and share it through the team's approved development channel. Supported export paths apply the shared redaction pipeline before writing data out.

## Local Development

Developers can use ISpect alongside Flutter DevTools. DevTools remains the right tool for profiling, memory, CPU, and debugger workflows; ISpect adds an in-app view of logs, requests, state transitions, navigation, and exported sessions.

## Not Intended For

- Replacing production crash reporting or release-health systems.
- Capturing every payload by default.
- Bypassing an organization's policy for diagnostic files.
- Enabling diagnostics in public production release builds.
