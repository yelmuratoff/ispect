---
name: debug
description: Investigate and fix bugs, errors, or unexpected behavior systematically — reproduce, locate, understand the root cause, fix it, and add a regression test. Use this skill when the user reports a failure (test, runtime, build, CI), shares a stack trace or error message, says something doesn't work, asks why something is broken, or asks for a fix that requires diagnosis — even when the word "debug" is not used (e.g. "this is broken", "почему падает", "не работает X").
---

# Debug

Systematically find and fix the root cause of a bug.

## Steps

1. **Reproduce** — Get the exact error message, stack trace, or steps to reproduce. Understand what happens vs. what should happen.
2. **Locate** — Narrow down where the problem is:
   - Read the error message and stack trace — they usually point to the exact location.
   - Search for relevant keywords (error strings, function names).
   - Trace the data flow from input to the failure point.
3. **Understand** — Before fixing, understand *why* it fails:
   - What assumption is violated?
   - When was it introduced? (`git log`, `git blame`)
   - Logic error? Data problem? Race condition? Missing edge case?
4. **Fix** — Make the smallest change that correctly addresses the root cause.
5. **Verify** — Write or update a test that catches this bug. Run the full test suite for regressions.
6. **Explain** — Briefly describe what caused it and why the fix is correct.

## Gotchas

- Don't wrap the error in try-catch to silence it — that's hiding, not fixing.
- Don't fix symptoms without understanding the cause.
- Don't make speculative changes ("maybe this will fix it") — understand first.
- Don't change multiple things at once — isolate the fix so you know what worked.
- Don't assume the bug is where the error is thrown — trace upstream to the root cause.
