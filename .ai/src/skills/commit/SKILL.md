---
name: commit
description: Create a well-structured git commit for staged or unstaged changes — analyze the diff, match the project's existing commit style, write a clear message, and create the commit. Use this skill when the user asks to commit, save changes, check in code, write a commit message, prepare changes for push, or wrap up a piece of work — even when they don't say "commit" explicitly (e.g. "let's save this", "ship it", "сохрани изменения").
---

# Commit

Write a commit message that follows the project's conventions and clearly explains what changed and why.

## Steps

1. Run `git diff --cached` (or `git diff` if nothing is staged) to see all changes.
2. Run `git log --oneline -10` to detect the project's existing commit style — copy it. Match what's there rather than imposing a different convention.
3. Analyze the changes: feature, fix, refactor, docs, or chore? What is the *motivation*?
4. Write the commit:
   - **First line**: imperative mood, ≤72 chars, matching the style from step 2.
   - **Body** (only if the subject can't carry the meaning): blank line, then *why*, not *what*.
5. Stage relevant files explicitly by path. `git add .` sweeps in generated files, secrets, and unrelated changes.
6. Create the commit.

## Default style

If the project has no established convention (step 2 returns mixed messages), default to **Conventional Commits**: `<type>: <subject>` where `<type>` is `feat`, `fix`, `refactor`, `docs`, `test`, or `chore`. Use `feat:` for new behavior, `fix:` for bug fixes, `refactor:` for behavior-preserving changes; the others are self-explanatory.

## Gotchas

- Create a new commit rather than amending the previous one — reach for `--amend` only on explicit user request.
- Keep one logical change per commit. Split unrelated work into separate commits.
- Leave `.env`, credentials, and generated lockfiles out of the index unless the project clearly tracks them.
- When a pre-commit hook fails, fix the cause and create a new commit. Reach for `--no-verify` only when the user explicitly authorizes it.
- Match the project's existing style (gitmoji, ticket-prefixed, plain-English) rather than inventing a new one.
