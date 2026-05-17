---
description: Investigate and fix a GitHub issue
argument-hint: "<issue-number>"
---

Look at issue #$ARGUMENTS in this repo.

!`gh issue view $ARGUMENTS`

1. Understand the bug from the issue description and comments.
2. Trace it to the root cause in the code.
3. Fix it with the smallest correct change.
4. Write a test that would have caught this bug.
5. Verify existing tests still pass.
