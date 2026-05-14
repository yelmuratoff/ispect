# Core Rules

Write code that fits the project's existing patterns, surfaces failures explicitly, and keeps the change scoped to what the task asked for.

## Scope of Changes

- Touch only what the task requires. Adjacent code stays as-is until asked.
- Three similar lines beat a premature abstraction — let real duplication drive helpers.
- Delete dead code outright; git keeps the history.

## Errors

- Raise the project's typed exceptions instead of raw strings.
- Handle failures explicitly — either recover or let the exception propagate.
- Validate at system boundaries (user input, external APIs); trust internal calls.

## Tests

- Cover business logic and error paths. Skip framework internals and trivial getters.
- Keep tests deterministic — local fixtures only, with no real network, no randomness, no time-based sleeps.
- Name tests by the behaviour verified, not by the method called.

## Security

- Load secrets, API keys, and credentials at runtime from the project's secret store — keep them out of source.
- Keep tokens, passwords, and PII out of logs.
- Store sensitive values through the project's secure storage primitive.

## Examples

```
# Surface the failure with structure:
- catch (e) { return null; }
+ catch (e) {
+   logger.error("user fetch failed", { userId, error: e });
+   throw new UserFetchError(userId, { cause: e });
+ }

# Name the test by what it proves:
- test("test_fetch")
+ test("returns empty list when the user has no orders")
```
