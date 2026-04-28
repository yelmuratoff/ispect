# Core Rules

## Changes

- Change only what's needed for the task. Don't refactor unrelated code.
- No new abstractions for one-off use — three similar lines beat a premature helper.
- Remove dead code; don't comment it out.

## Errors

- Use the project's typed exceptions. Never throw raw strings.
- Don't catch-and-ignore. Either handle the failure or let it propagate.
- Validate at system boundaries (user input, external APIs); trust internal calls.

## Tests

- Test business logic and error paths. Skip framework internals.
- Tests must be deterministic — no real network, no randomness, no time-based sleeps.
- Name tests by behavior verified, not by method called.

## Security

- No hardcoded secrets, API keys, or credentials.
- Never log tokens, passwords, or PII.
- Use the project's secure storage for sensitive values.
