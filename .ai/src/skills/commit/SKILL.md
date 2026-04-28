---
name: commit
description: Create a well-structured git commit for staged or unstaged changes — analyze the diff, match the project's existing commit style, write a clear message, and create the commit. Use this skill when the user asks to commit, save changes, check in code, write a commit message, prepare changes for push, or wrap up a piece of work — even when they don't say "commit" explicitly (e.g. "let's save this", "ship it", "сохрани изменения").
---

# Commit

Write a commit message that follows the project's conventions and clearly explains what changed and why.

## Steps

1. Run `git diff --cached` (or `git diff` if nothing is staged) to see all changes.
2. Run `git log --oneline -10` to detect the project's existing commit style — copy it. Don't impose a different convention.
3. Analyze the changes: feature, fix, refactor, docs, or chore? What is the *motivation*?
4. Write the commit:
   - **First line**: imperative mood, ≤72 chars, matching the style from step 2.
   - **Body** (only if the subject can't carry the meaning): blank line, then *why*, not *what*.
5. Stage only relevant files explicitly by path. Don't `git add .` blindly — exclude generated files, secrets, unrelated changes.
6. Create the commit.

## Default style

If the project has no established convention (step 2 returns mixed messages), default to **Conventional Commits**: `<type>: <subject>` where `<type>` is `feat`, `fix`, `refactor`, `docs`, `test`, or `chore`. Use `feat:` for new behavior, `fix:` for bug fixes, `refactor:` for behavior-preserving changes; the others are self-explanatory.

## Gotchas

- Don't amend the previous commit unless explicitly asked — create a new commit.
- Don't include unrelated changes in the same commit. Split them.
- Don't commit `.env`, credentials, or generated lockfiles unless the project clearly expects it.
- If a pre-commit hook fails, fix the underlying issue and create a NEW commit — don't use `--no-verify`.
- Don't invent a new style if the project uses something specific (gitmoji, ticket-prefixed, plain-English) — match what's there.
