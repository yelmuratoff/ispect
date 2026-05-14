---
description: Review the current branch diff for issues before merging
---

## Changes

!`git diff --name-only main...HEAD`

## Diff

!`git diff main...HEAD`

Review the above changes. Cover:

1. **Correctness** — logic errors, off-by-one bugs, missing edge cases, race conditions.
2. **Security** — hardcoded secrets, injection risks, missing validation, exposed PII.
3. **Error handling** — swallowed exceptions, missing error paths, raw strings instead of typed errors.
4. **Architecture** — does this respect existing layer boundaries and patterns?
5. **Test coverage** — are new behaviors and error paths tested?

Report **every issue you find**, including ones you're uncertain about or consider low-severity. Don't filter for importance at this stage — coverage matters more than precision; a downstream pass can rank findings. For each finding, include a confidence level (`high`/`medium`/`low`) and severity (`blocking`/`suggestion`/`nit`) so they can be triaged.

Point to the exact file and line. Explain *why* it's a problem, not just *what* to change. Suggest a concrete fix when possible.

If the code is solid, say so plainly — don't manufacture criticism.
