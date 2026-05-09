# Core Rules

## Changes

- Change only what the task requires. Leave unrelated code as-is.
- Wait for real duplication before extracting a helper — three similar lines beat a premature abstraction.
- Delete dead code outright and rely on git for history.

## Errors

- Raise the project's typed exceptions instead of raw strings.
- Handle failures explicitly — either recover or let the exception propagate.
- Validate at system boundaries (user input, external APIs); trust internal calls.

## Tests

- Test business logic and error paths. Skip framework internals.
- Keep tests deterministic — local fixtures only, no real network, no randomness, no time-based sleeps.
- Name tests by behavior verified, not by method called.

## Security

- Keep secrets, API keys, and credentials out of source. Load them at runtime from the project's secret store.
- Keep tokens, passwords, and PII out of logs.
- Store sensitive values via the project's secure storage primitive.
