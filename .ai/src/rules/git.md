# Git Rules

## Commits

- Match the project's existing commit style (check `git log --oneline -10`). If none is established, default to Conventional Commits: `<type>: <subject>` with `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.
- One logical change per commit. Don't mix unrelated work.
- Subject in imperative mood, ≤72 chars. Body explains *why*, not *what* — skip the body when the subject says enough.

## Branches

- Use descriptive names: `feat/<slug>`, `fix/<slug>`, `refactor/<slug>`.
- Rebase onto the default branch before opening a PR.

## Pull Requests

- Link the related ticket or issue in the description.
- Don't force-push to shared branches without coordination.
- Don't bypass `--no-verify` or pre-commit hooks to make CI green — fix the failure.

## What Never Goes In

- Generated artifacts, lockfile binaries, secrets, `.env*` files.
- Use `.gitignore` for environment-specific or generated output.
