# Maintenance

Read this when running `agentsync update`, `agentsync resolve`, `agentsync simplify`, or when a teammate reports stale-override or upstream-drift problems.

## Resolving upstream drift

When you run `agentsync update`, the CLI snapshots the install-dir tool catalog before pulling the new release, then compares it against the newly-pulled catalog field-by-field. For every upstream change to a field you have overridden, the update prints a warning and writes the list to `.ai/.pending-resolutions.yaml`:

```yaml
schema: 1
from_version: "0.7.0"
to_version: "0.8.0"
conflicts:
  - tool: "claude"
    field: "targets.rules.dest"
    base_before: ".claude/rules"
    base_after: ".claude/rules-v2"
    your_override: ".claude/my-rules"
```

- `agentsync resolve` reads this queue on startup and flags the affected fields with `⚡`. Walking through every override (not a subset with `resolve <tool>`) clears the queue automatically.
- Pass `--strict` to `agentsync update` to exit non-zero on any conflict — useful in CI to block a merge until someone reviews upstream changes.
- The file is non-authoritative: delete it any time if you prefer to ignore the warnings. Your overrides are untouched until you explicitly adopt a base value via `agentsync resolve`.

## Simplifying redundant overrides

After `agentsync customize <tool> --full`, an override carries the entire base template verbatim. Over time those redundant fields pin stale values and silently block upstream updates — if base moves forward, the redundant override wins and you stay on the old value.

`agentsync simplify` walks every user override and drops fields that already match the current base, leaving only the ones that actually diverge.

```
agentsync simplify              # dry-run every override
agentsync simplify cursor       # dry-run just one tool
agentsync simplify --apply      # persist changes
agentsync simplify --apply -y   # persist + auto-delete emptied files
```

- Dry-run by default — prints a preview of fields that would be removed and fields that would stay. Pass `--apply` to write.
- If every overridden field matches base, the entire override file is redundant. With `--apply -y` the file is deleted automatically; in an interactive shell without `-y` you're prompted.
- Idempotent: running with `--apply` twice in a row is a no-op the second time.
- Comments inside a user override are not preserved when a nearby field is removed — the line-level YAML mutator strips the key and any indented comments below it. If you rely on inline documentation, keep a separate note or use `agentsync show <tool>` to re-derive intent.

## Recommended cadence

- **After each `agentsync update`:** review `.ai/.pending-resolutions.yaml` (if present) and run `agentsync resolve` before continuing other work.
- **Quarterly or after a major version bump:** run `agentsync simplify` (dry-run first) to drop stale fields; commit the result on its own so the diff is reviewable.
- **In CI for a config-stable repo:** add `agentsync update --strict` so unreviewed upstream drift fails the build.
