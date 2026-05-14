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

- Let the error surface until you understand it. A silent try-catch hides the cause and breeds a worse bug later.
- Trace to the root cause before applying the fix. Symptom-level patches return as new bugs.
- Form a hypothesis grounded in the data before changing code. Speculation burns more time than diagnosis.
- Change one thing at a time so you can tell what fixed the bug.
- Trace upstream from the error site. The bug usually lives where the bad value is produced, not where it explodes.
