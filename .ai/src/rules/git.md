# Git Rules

## Commits

- Match the repo's mixed history: Conventional Commits are preferred for structured changes (`feat(ispectify): ...`, `fix(ispect): ...`, `chore(release): ...`), while short docs commits also exist.
- Keep one logical package or workflow change per commit.
- Mention the affected package in the scope when the change is package-specific.

## Review Prep

- Use `git status --short` and `git diff --stat` before summarizing work.
- Review generated README/version/changelog diffs separately from source changes.
- Do not hide failing hooks with `--no-verify`; fix version, dependency, README, analyzer, or test failures.

## Anti-Patterns

- Do not force-push, reset hard, or delete branches unless the user asks.
- Do not commit `.env*`, credentials, certificates, build output, or coverage output.
- Do not mix release automation changes with feature implementation unless the task is release prep.
