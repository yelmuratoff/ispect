# Docs And Release Rules

## README Generation

- Treat `docs/readme/**` as the source for root and package README content.
- Do not hand-edit generated `README.md` or `packages/*/README.md` without also updating the matching `docs/readme/**` source.
- Run `./bash/build_readme.sh` after README source edits.
- Run `./bash/build_readme.sh --check` before finishing docs changes.

## Changelog

- Add user-facing changes to root `CHANGELOG.md`.
- Use `./bash/update_changelog.sh` to propagate release notes to package changelogs.
- Keep changelog sections tied to the current `VERSION` in `version.config`.

## Release Scripts

- Use `./bash/release_prep.sh` for standard release prep.
- Use `./bash/publish.sh --dry-run` before any publish attempt.
- Use `./bash/publish.sh --auto` only when the user explicitly asks for a real publish.

## Anti-Patterns

- Do not edit `.publish_logs` output as source material.
- Do not change CI version validation unless the release workflow itself is the task.
- Do not replace generated README markers or partials with duplicated package-specific prose.
