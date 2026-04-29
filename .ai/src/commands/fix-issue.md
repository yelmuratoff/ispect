---
description: Investigate and fix a GitHub issue in the ISpect monorepo
argument-hint: "<issue-number>"
---

Issue:
!`gh issue view $ARGUMENTS --comments`

Work through the issue as follows:

1. Identify the affected package: `ispectify`, `ispectify_dio`, `ispectify_http`, `ispectify_ws`, `ispectify_db`, `ispectify_bloc`, `ispect_layout`, `ispect`, or `web_logs_viewer`.
2. Read the package root export, relevant `lib/src/**` files, existing tests, and README source under `docs/readme/**` if setup docs are involved.
3. Reproduce with the smallest package-level test before changing implementation when feasible.
4. Fix the root cause without crossing package boundaries unnecessarily.
5. Add regression coverage for the behavior and any redaction, disabled logging, or error path involved.
6. Run analyzer and tests for the affected package, plus README/version checks if docs or pubspecs changed.

Report changed files, verification commands, and any behavior that could not be reproduced locally.
