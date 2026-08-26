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

## Versioning

- Write prerelease counters in the dot form (`7.1.0-dev.1`, `7.1.0-dev.2`); a counter glued to its label sorts as text, so `dev10` resolves below `dev8`.
- Let the scripts compute the next version; they reject anything Pub does not order above the current `VERSION`.
- `7.0.0-dev8`…`7.0.0-dev11` shipped in the glued form — Pub ranks `7.0.0-dev9` highest, so the next 7.0.0 prerelease has to leave the `dev` label.
- `./bash/publish.sh` blocks a version the resolver does not rank above the published peak of its `MAJOR.MINOR` line; treat that as a wrong version, not as a reason to pass `--skip-pub-version-check`.

## Release Scripts

- Use `./bash/release_prep.sh` for standard release prep.
- Use `./bash/publish.sh --dry-run` before any publish attempt.
- Use `./bash/publish.sh --auto` only when the user explicitly asks for a real publish.

## Anti-Patterns

- Do not edit `.publish_logs` output as source material.
- Do not change CI version validation unless the release workflow itself is the task.
- Do not replace generated README markers or partials with duplicated package-specific prose.
