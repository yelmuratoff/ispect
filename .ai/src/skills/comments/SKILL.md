---
name: comments
description: Scan recently written or edited code and remove comments that do not earn their place — narration, step markers, task/PR references, commented-out blocks, decorative banners. Use this skill after finishing a non-trivial code change, when reviewing a diff for comment hygiene, when the user mentions noisy or redundant comments, or proactively before declaring a coding task complete. Defer to the `comments` rule for what makes a comment worth keeping.
---

# Comments Cleanup

Scan the diff you just produced and strip comments that the code already carries. The `comments` rule has the long-form criteria and examples; this skill is the cleanup procedure.

## Procedure

1. **Pull the diff.** `git diff` for unstaged work, `git diff --staged` for staged. Focus on `+`-lines that introduced comments.
2. **For each new comment, ask one question** — *would a competent reader miss anything if this comment were removed?* If the answer is no, delete the comment.
3. **Tighten what remains.** A comment that stays should describe *why*, fit on one line where possible, and use the language's doc-comment syntax for public APIs only.

## Categories to delete on sight

- **Narration** — restates what the code does (`// increment counter`, `// loop through users`, `// validate user`).
- **Step markers** — planning artefacts (`// Step 1: fetch users`, `// now we will…`, `// AI thought: …`).
- **Task / PR / caller references** (`// added for ticket X`, `// used by Y`) — that context belongs in the commit message.
- **Commented-out code** — git keeps the history.
- **Decorative banners** (`// ===== HELPERS =====`) when nothing else in the file uses them.
- **Apologies** (`// hacky but works`) — either fix the code or open a tracked issue and link it.
- **Untracked `TODO` / `FIXME`** — pair every marker with an owner or an issue, or resolve it now.

## Categories to keep

- **Hidden constraint** — a non-obvious invariant, ordering requirement, or performance assumption.
- **External quirk** — API behaviour, browser bug, platform-specific oddity (name the system).
- **Workaround** — a fix for a tracked upstream issue (link it).
- **Surprise** — behaviour that would make a reasonable reader pause.
- **Public API contract** — inputs, outputs, errors, side effects via `///`, `/** */`, or docstrings.

## Self-check before finishing

- Diff scanned end-to-end, including test files.
- No `// Step N`, no `// loop`, no `// AI thought`, no commented-out blocks.
- Every remaining `TODO` / `FIXME` has an owner or issue.
- Comment density matches the surrounding files (scan 5–10 nearby).

Report what was removed and what was kept, with a one-line reason per surviving comment when it isn't obvious.
