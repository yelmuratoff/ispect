# Git Rules

One logical change per commit, imperative mood, generated artefacts stay out of history.

## Commits

- Match the project's existing commit style (`git log --oneline -10`). If none is established, default to Conventional Commits: `<type>: <subject>` with `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.
- One logical change per commit. Split unrelated work into separate commits.
- Subject in imperative mood, ≤72 chars. Body explains *why*; skip the body when the subject says enough.

## Branches

- Descriptive names: `feat/<slug>`, `fix/<slug>`, `refactor/<slug>`.
- Rebase onto the default branch before opening a PR.

## Pull Requests

- Link the related ticket or issue in the description.
- Resolve hook or CI failures at the source rather than passing `--no-verify` — a green CI built on bypassed checks lies.
- Prefer additive commits while reviewers are looking; coordinate before force-pushing a shared branch.

## Keep Out of History

- Generated artefacts, lockfile binaries, secrets, and `.env*` files belong outside the repo.
- Reach for `.gitignore` to fence off environment-specific or generated output.
