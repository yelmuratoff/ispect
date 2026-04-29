---
description: Review the current branch diff using ISpect package boundaries and safety rules
argument-hint: "[base-ref]"
---

Base ref: `${ARGUMENTS:-main}`

Changed files:
!`git diff --name-only ${ARGUMENTS:-main}...HEAD`

Diff:
!`git diff ${ARGUMENTS:-main}...HEAD`

Review the branch as an ISpect maintainer.

Prioritize:

1. Production-safety regressions around `ISPECT_ENABLED`, disabled initialization, tree-shaking assumptions, or release build instructions.
2. Redaction/data exposure in network, DB, export, clipboard, observer, cURL, and log metadata paths.
3. Public API compatibility: package exports, constructor signatures, log keys, trace category IDs, metadata keys, localization keys.
4. Package boundary drift between `ispectify`, `ispectify_*`, `ispect`, `ispect_layout`, examples, and `web_logs_viewer`.
5. Missing tests for request/response/error, disabled logging, redaction opt-outs, and generated README/version changes.

For each finding, include severity, confidence, exact file/line, and a concrete fix.
If no issues are found, say the branch is production-ready and list any checks that still need to run.
