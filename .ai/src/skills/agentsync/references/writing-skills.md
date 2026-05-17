# Writing Skills

Full reference for authoring AgentSync skills. Read this when creating or editing a skill in `.ai/src/skills/<name>/`.

AgentSync skills follow the open [agentskills.io](https://agentskills.io) format — a portable standard supported by Claude Code, Codex, Cursor, Copilot, Gemini CLI, OpenCode, and ~30 other agents. Validate any skill with `skills-ref validate <path>`.

## How skills load: progressive disclosure

Agents load skills in three stages, so design with each stage in mind:

1. **Discovery (~100 tokens, all skills):** the agent reads only `name` + `description` of every available skill at startup, deciding which might be relevant.
2. **Activation (≤5000 tokens, one skill):** when a task matches a description, the agent reads the full `SKILL.md` body.
3. **Resources (on demand):** files in `references/`, `scripts/`, and `assets/` load only when `SKILL.md` instructs the agent to read them.

**Implication:** keep `SKILL.md` lean. Move detail behind explicit triggers like *"Read `references/X.md` when the input is a multi-page PDF."*

## Skill directory layout

```
my-skill/
├── SKILL.md          # Required: frontmatter + instructions
├── references/       # Optional: docs read on demand (REFERENCE.md, etc.)
├── scripts/          # Optional: executable code (Python/Bash/JS) the agent runs
├── assets/           # Optional: templates, schemas, images
└── ...
```

Use **relative paths** from the skill root (`references/foo.md`, `scripts/bar.py`) and keep references **one level deep**.

## Frontmatter fields

```yaml
---
name: skill-name # Required. Must match the parent directory name.
description: One imperative sentence on what the skill does + concrete trigger conditions.
# Optional:
license: MIT
compatibility: Requires Python 3.12+ and uv
metadata:
  author: your-team
  version: "1.0"
allowed-tools: Bash(git:*) Read Grep   # Experimental; tool-specific.
---
```

**`name` constraints (hard):**

- 1–64 characters
- Lowercase letters, digits, and hyphens only — no `_`, no uppercase, no Unicode
- No leading or trailing hyphen, no consecutive `--`
- Must equal the parent directory name (`my-skill/SKILL.md` ↔ `name: my-skill`)

**`description` constraints (hard):**

- 1–1024 characters
- Must convey *both* what the skill does *and* when to use it

## Writing the description (the trigger)

The description is the only thing the agent sees during discovery. Vague = invisible.

- **Imperative phrasing.** "Use this skill when…" beats "This skill does…". The agent is deciding whether to act.
- **Focus on user intent, not internal mechanics.** Describe what the user is trying to achieve, not the steps the skill takes.
- **Be pushy.** Explicitly list contexts where the skill applies, *including ones where the user doesn't name the domain* ("even when phrased as 'this is broken' or 'почему падает'").
- **Pack relevant keywords** the user might say or type, including alternate phrasings.
- **Concise but full.** A few sentences usually beats one. Stay under 1024 chars.

Bad: `description: Helps with testing.`
Good: `description: Write or fix tests for a feature, bug, or regression — unit, integration, or end-to-end. Use this skill when the user adds tests, asks why a test fails, requests coverage, or describes verifying behaviour — even when "test" is implied (e.g. "make sure this works", "should we cover this case").`

For a deeper trigger-tuning workflow (eval queries, train/validation split, iterating the description), see [agentskills.io/skill-creation/optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions).

## Structure of a good skill

```markdown
---
name: example-skill
description: <imperative + trigger conditions, 1–1024 chars>
---

# Skill Name

One line: what this skill does and when to invoke it.

## Bundled references (load on demand)        # Optional, only if you have references/

- `references/X.md` — read when [concrete trigger condition]
- `references/Y.md` — read when [concrete trigger condition]

## Steps                                       # The core procedure

1. Concrete numbered steps with real commands and paths.
2. Use imperative verbs.

## Output format / template                    # Optional, when format matters

\`\`\`
<concrete template the agent should fill in>
\`\`\`

## Gotchas                                     # The highest-signal section

- Every mistake the agent has made using this skill.
- Concrete corrections to wrong assumptions ("the `users` table uses soft deletes; queries must include `WHERE deleted_at IS NULL`").
- Edge cases and common pitfalls.
```

## Calibration principles

These come straight from the [agentskills.io best-practices guide](https://agentskills.io/skill-creation/best-practices). Internalise them.

- **Add what the agent lacks; omit what it knows.** Don't explain what a PDF is, what HTTP does, or how `git` works. Jump straight to project-specific conventions, non-obvious edge cases, and the particular tools or APIs to use.
- **Procedures over declarations.** Teach *how to approach* a class of problems, not the answer to one specific instance. The procedure should generalise even when individual details are concrete.
- **Defaults, not menus.** Pick one tool/library/approach and mention alternatives briefly. "Use `pdfplumber`; fall back to `pdf2image` for scanned PDFs" beats listing four equal options.
- **Match specificity to fragility.** Be prescriptive on fragile, sequence-sensitive operations ("run exactly: `python migrate.py --verify --backup`"). Be descriptive on flexible work ("look for SQL injection, weak auth, race conditions") and let the agent's judgment fill in.
- **Aim for moderate detail.** Concise stepwise guidance with a working example beats exhaustive documentation. When you're tempted to cover every edge case, ask whether the agent can handle most by judgment.
- **Design coherent units.** A skill should encapsulate one workflow that composes well with others. Too narrow → many skills load for one task. Too broad → can't be activated precisely.

## Patterns for effective instructions

Pick the ones that fit your task; not every skill needs all.

- **Gotchas section.** Concrete corrections, not generic advice. Update every time the agent makes a mistake using the skill — this is the single highest-leverage section to maintain.
- **Output templates.** When format matters, show a concrete template the agent fills in — pattern matching beats prose description. Inline for short templates; in `assets/` for long or conditional ones.
- **Checklists.** Multi-step workflows with dependencies benefit from an explicit progress list (`- [ ] Step 1: …`) so the agent tracks state and doesn't skip steps.
- **Validation loops.** "Do X → run validator → fix issues → repeat until validation passes." More reliable than asking the agent to "double-check".
- **Plan-validate-execute.** For batch or destructive operations: extract source-of-truth → produce a plan in a structured file → run a validator script that checks the plan against the source → only then execute. The validation script's error messages should give the agent enough to self-correct.
- **Bundled scripts.** If you notice the agent reinventing the same logic across runs (chart-builder, parser, validator), write the script once in `scripts/` and have `SKILL.md` invoke it.

## Size budget

- Hard recommendation: **`SKILL.md` ≤ 500 lines and ≤ 5000 tokens.** This is the body the agent loads on activation and shares context with everything else.
- Soft target for sleek skills: 50–150 lines if the workflow is simple. Don't pad to fill space.
- **When you legitimately need more,** move detail to `references/<topic>.md` and reference it with a concrete load-trigger ("read `references/X.md` when Y"). Don't dump it inline.

## Rule of three

Don't create a skill for everything. If you've done something three times manually and want it consistent next time, *then* create a skill. Earlier than that, you don't yet know the shape.

## Iteration

Skills improve through real execution, not introspection.

1. **Refine with traces.** Run the skill on real tasks. Read execution traces — not just final outputs. Wasted steps and unproductive branches usually mean an instruction is too vague, doesn't apply, or presents too many options without a default.
2. **Add gotchas as you go.** Every correction you make in a real session is a candidate gotcha. Save it before you forget.
3. **For high-stakes skills, run evals.** Define test cases (`evals/evals.json`), run with-skill vs. without-skill, grade outputs against assertions, compare. See [agentskills.io/skill-creation/evaluating-skills](https://agentskills.io/skill-creation/evaluating-skills).
