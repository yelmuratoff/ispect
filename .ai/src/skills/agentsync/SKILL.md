---
name: agentsync
description: Create or edit AgentSync configuration for this repo: AGENTS.md, rules, skills, commands, subagents, Claude settings, hooks, or tool-specific sync behavior. Use when working in `.ai/src/`, generated agent directories, or when the user asks to add an AI rule, skill, command, agent, permission, or run AgentSync sync/dry-run.
---

# AgentSync

Maintain AI instructions from `.ai/src/`, the source of truth for this repository.

## Structure

```
.ai/src/
  AGENTS.md
  rules/
  skills/<skill-name>/SKILL.md
  commands/
  agents/
  settings/
  hooks/
  tools/
```

## Steps

1. Edit source files under `.ai/src/`; do not edit generated tool directories first.
2. Keep `AGENTS.md` project-specific and around 40-70 lines.
3. Keep rule files focused: one topic, 20-50 lines, imperative constraints.
4. Create skills only for repeated workflows. Use trigger-rich frontmatter descriptions and concrete gotchas.
5. Keep commands as focused prompts for one workflow; use `$ARGUMENTS` and embedded shell output only when it helps.
6. Create subagents only for distinct specializations. Prefer read-only tools for reviewers and auditors.
7. Validate with `agentsync sync --dry-run` before a real sync.
8. Run `agentsync sync` only when the user wants generated tool outputs updated.

## Current Project Notes

- Enabled tools are configured in `.ai/agent_sync.yaml`: Claude, Copilot, and Codex.
- This installed AgentSync version supports `--dry-run`; it does not support `sync --check`.
- `.ai/src/settings/claude.json` still works, but AgentSync reports it as a legacy payload override layout for 0.11.x.
- The generated directories are disposable outputs; `.ai/src/` is the durable source.

## Gotchas

- Do not create overlapping skills with the same trigger phrasing; make descriptions mutually exclusive or merge them.
- Do not leave empty skill directories; AgentSync can still count them during sync.
- Do not reference missing `references/`, `scripts/`, or `assets/` files from `SKILL.md`.
- Do not use aggressive `MUST`/`ALWAYS` language unless the sequence is fragile.
