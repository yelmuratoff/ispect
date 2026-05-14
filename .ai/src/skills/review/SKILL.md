---
name: review
description: Perform a structured code review on a diff, PR, or staged changes — surface correctness, security, error-handling, architecture, testing, and clarity issues with file/line references and severity. Use this skill when the user asks to review code, audit a diff or PR, find bugs in changes before merging, sanity-check work before pushing, or look over an implementation — including when phrased softly ("look over this", "check if this is OK", "глянь, всё ли нормально", "посмотри на это").
---

# Code Review

Systematically review changes for correctness, security, and maintainability.

## Steps

1. Read the full diff. Understand the scope before commenting.
2. Check PR description or commit messages for context — what problem is being solved?
3. Review in priority order:
   - **Correctness** — Logic errors, off-by-one bugs, missing edge cases, race conditions.
   - **Security** — Injection risks, hardcoded secrets, missing validation, exposed PII.
   - **Error handling** — Unhandled failures, swallowed exceptions, missing error paths.
   - **Architecture** — Does this follow existing patterns? Are boundaries respected?
   - **Testing** — Are new behaviors tested? Are error paths covered?
   - **Naming & clarity** — Would a new team member understand this?
4. For each issue:
   - Point to the exact file and line.
   - Explain *why* it's a problem, not just *what* to change.
   - Suggest a fix when possible.
   - Mark as **blocking** (must fix) or **suggestion** (nice to have).
5. When the code is solid, say so plainly. Manufactured criticism erodes review trust.

## Output Format

```
## Summary
[1-2 sentence overview]

## Issues
- **[blocking]** file.ts:42 — [problem and suggested fix]
- **[suggestion]** file.ts:15 — [observation and reasoning]

## Verdict
[Approve / Request changes / Needs discussion]
```

## Gotchas

- Skip style nitpicks that a formatter or linter would catch — those are noise.
- Review what's there, not what you would have written. The author's approach stands unless it has a concrete flaw.
- Resolve every blocking issue before approving — politeness is not a reason to ship a known bug.
- Check the full PR, not just the latest commit — bugs often hide in earlier commits.
