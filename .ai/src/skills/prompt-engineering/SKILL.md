---
name: prompt-engineering
description: Design, debug, and refine prompts for LLM-based coding tools, agents, and pipelines. Use this skill when writing or rewriting a system prompt, agent persona, slash-command body, rule, or skill description; tuning a prompt that produces vague, incomplete, off-format, hallucinated, or over-/under-triggering output; choosing among techniques like XML tags, few-shot examples, role-setting, reasoning steps, or recap; debugging a model that ignores instructions, leaks information, or over-engineers solutions; or designing the persona, autonomy posture, or tool-use rules of an autonomous agent — even when the user does not explicitly mention "prompt engineering" or "system prompt". Not for AgentSync file structure, frontmatter, or scaffolding new rule/skill/command files — use the `agentsync` skill for that.
---

# Prompt Engineering

A workflow and toolbox for writing prompts that steer modern LLMs reliably — system prompts, slash commands, skills, rules, agent personas, and one-off queries.

## Bundled references (load on demand)

- **`references/snippets.md`** — read **when you need a copy-paste prompt fragment** for a recurring concern: anti-overengineering, parallel tool calls, default-to-action / do-not-act, investigate-before-answering, code-review coverage, frontend aesthetics, persistence across context windows, reversibility/safety, verbosity, long-document grounding. ~20 vetted blocks.
- **`references/metaprompting.md`** — read **when a prompt under-performs and the cause is unclear**: full metaprompting template, filtering procedure for the model's suggestions, when to use vs. skip.
- **`references/agent-persona.md`** — read **when designing or auditing the system prompt of an autonomous agent**: identity, autonomy posture, tool-use rules, editing constraints, full Friendly and Pragmatic personality blocks, final-message format, plan discipline.

## Workflow

1. **Define success first** — write one sentence: *what must the output be, and for whom*. Define the eval criteria *before* the prompt. If you can't, the prompt isn't ready.
2. **Draft with the minimal components** — Objective + Instructions + (if needed) Context, Role, Format, Examples. Don't add a component you can't justify.
3. **Build a test set** — 3+ diverse inputs: happy path, edge cases, malformed input. Tiny is fine; some signal beats none.
4. **Run and grade** — code-grade where possible (JSON/regex/Python parse, length, keyword presence), model-grade for quality, human-grade for nuance. Always demand reasoning + score from a model grader, not a bare score.
5. **Diagnose, don't patch** — name the cause (ambiguous scope? missing context? conflicting instruction? wrong format?). Fix the cause, not the symptom. If you can't pinpoint the cause, run metaprompting (see `references/metaprompting.md`).
6. **Change one thing at a time** — otherwise you won't know what worked.
7. **Iterate** — re-run the same test set, compare versions; stop when stable across all of them, not when "looks good once".
8. **Pin and version** — for production, pin to a specific model snapshot (e.g., `claude-opus-4-7`, `gpt-5.3-codex`) and re-run evals when upgrading.

## Prompt components (include only what's load-bearing)

- **Objective / goal** — what success looks like. Concrete and measurable ("summary ≤ 3 sentences", not "brief summary").
- **Instructions** — ordered, imperative steps when order matters.
- **Role / persona** — one sentence shifts tone and domain lens. "You are a senior Flutter engineer" beats "You are a helpful assistant". For full agent personas, see `references/agent-persona.md`.
- **Context** — background the model can't derive. Put *long* context near the top, query at the bottom (30%+ quality lift on multi-doc tasks).
- **Constraints** — what it must / must not do. State *scope explicitly* ("apply to every section, not just the first"). Two flavours of specificity:
  - *Type A — attributes:* qualities of the output (length, tone, structure). Useful in almost every prompt.
  - *Type B — steps:* the reasoning path the model should follow. Use when the natural approach would miss something.
- **Output format** — structure, length, schema. Show it in an example if non-trivial. Use a widely-parsable format (JSON / XML / Markdown / YAML) unless you have reason not to.
- **Few-shot examples** — 3–5, relevant, diverse, wrapped in `<example>` / `<examples>` tags. Place them *after* instructions, not before. Add a one-line rationale per example explaining *why* the output is ideal — this teaches the pattern, not just the surface.
- **Reasoning step** — "think step by step" or `<thinking>` tags when the task needs multi-step logic. On models with adaptive/native thinking (Claude 4.6+, GPT-5 reasoning, Gemini Thinking), prefer goal-only guidance ("think thoroughly") over prescriptive steps — the model often outperforms a hand-written plan.
- **Recap** — for long prompts, restate the hard constraints and format at the end.

## Techniques that reliably work

- **Golden rule**: show your prompt to a colleague with no context. If they'd be confused, the model will be too.
- **Explain the *why***: "never use ellipses" → "your response is read by TTS, which can't pronounce ellipses." The model generalises from the reason.
- **Tell it what to do, not what to avoid**: "respond in flowing prose" beats "don't use bullet points".
- **Prefer positive examples over negative ones.**
- **Use XML tags** (`<instructions>`, `<context>`, `<input>`, `<example>`) to separate sections — especially effective on Claude. Name them descriptively (`<sales_records>` beats `<data>`); the tag name itself signals what's inside.
- **Name custom tools semantically** — `semantic_search` over `search`, `apply_patch` over `edit`. Tool names and argument names should look "in-distribution" for what the model was trained on.
- **Match prompt style to desired output** — markdown-heavy prompts produce markdown-heavy responses; plain prose begets plain prose.
- **Be explicit about tool use** — "change this function" not "can you suggest some changes", unless suggestion is the goal.
- **Ground long-document tasks in quotes first** — ask the model to extract relevant quotes before answering.
- **Self-check step** — "before finishing, verify the answer against [criteria]" catches errors reliably on code and math.
- **Metaprompting** — when a prompt under-performs without an obvious cause, ask the model to propose changes to its own instructions. Full procedure in `references/metaprompting.md`.
- **Start from a vetted snippet** — for any of the recurring concerns listed at the top, drop in the relevant block from `references/snippets.md` rather than writing from scratch.
- **Truncate long tool outputs deterministically** — for agentic loops, cap tool output at ~10k tokens; if exceeded, keep the first half and last half with `...N tokens truncated...` between. Random or only-tail truncation throws away signal.

## Common failure modes and fixes

| Symptom                                        | Likely cause                           | Fix                                                                                                            |
| ---------------------------------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Output drifts off-format                       | Format not specified or only described | Show the format in an example; use XML/JSON schema.                                                            |
| Answers are vague or generic                   | Objective is vague                     | Replace qualitative words ("brief", "good") with measurable ones ("≤3 sentences").                             |
| Model only suggests, doesn't act               | Verb is passive                        | Use imperative ("change", "write"), not "can you suggest". See `default_to_action` in `references/snippets.md`.|
| Instruction applied to first item, not all     | Scope not stated                       | "Apply to every X, not just the first".                                                                        |
| Output too verbose                             | No length cap; markdown-heavy prompt   | Cap length; remove markdown from the prompt; ask for "concise, focused" responses.                             |
| Model over-triggers tools / skills             | Aggressive language ("MUST", "ALWAYS") | Soften to "use when..."; modern models over-comply with ALL-CAPS directives.                                   |
| Over-engineered / extra files                  | No scope constraint                    | Drop in the anti-overengineering snippet from `references/snippets.md`.                                        |
| Hallucinated code / file references            | No grounding requirement               | Drop in the `investigate_before_answering` snippet from `references/snippets.md`.                              |
| Shallow reasoning on hard tasks                | Effort too low / thinking off          | Raise `effort` (Claude) or `reasoning_effort` (OpenAI) before re-prompting.                                    |
| Extended thinking on trivial questions         | Prompt implies complexity              | Add: "respond directly when the task doesn't need multi-step reasoning".                                       |
| Cause unclear despite reading the prompt       | Prompt has accreted edits              | Run metaprompting (`references/metaprompting.md`).                                                             |

## Prompt health checklist

Before shipping a prompt, check:

- [ ] Typos, grammar, punctuation clean.
- [ ] No undefined jargon or acronyms.
- [ ] No ambiguous qualifiers ("good", "brief", "appropriate") — replaced with measurable ones.
- [ ] No conflicting instructions or examples.
- [ ] No redundant restatements of the same rule.
- [ ] Role and output format defined when the task needs them.
- [ ] Edge cases and missing-data handling addressed.
- [ ] Not trying to do too many distinct tasks in one pass — split if so.
- [ ] No emotional manipulation ("very bad things will happen") — doesn't help modern models; often hurts.
- [ ] Untrusted user input is isolated (XML tags, labelled boundaries) to resist injection.
- [ ] For production: pinned to a specific model snapshot.

## Tool-specific notes

- **Claude (Opus 4.6+/4.7)** — interprets instructions literally; state scope explicitly. Uses adaptive thinking — tune via `effort`, not by over-prompting. Dial back "MUST/ALWAYS/CRITICAL" — it over-triggers. Prefers XML tags.
- **OpenAI GPT-5 / Codex** — uses `instructions` + `input` roles; pin production prompts to a specific model snapshot; build evals alongside prompts. Reasoning models: prefer goal-only prompts over step-by-step instructions. For `gpt-5.3-codex`, persist the `phase` field on assistant items (commentary vs. final_answer) — dropping it degrades performance.
- **Gemini** — responds well to the full component template (Objective → Instructions → Constraints → Context → Output format → Examples → Recap). Native Thinking: avoid explicit step-by-step.
- **Agent rules / skills / commands (this repo)** — rules are always-on constraints (imperative, 20–50 lines, one topic). Skills are on-demand recipes with a triggering description. Commands are one-workflow prompts. See the `agentsync` skill for AgentSync file format and scaffolding.

## Gotchas

- Don't blindly copy tips across tools — a prompt tuned for GPT-4 can under- or over-trigger on Claude Opus 4.7 and vice versa.
- Don't keep adding rules when the model misbehaves — first check if an existing rule is ambiguous or conflicts with another. Metaprompting (`references/metaprompting.md`) often surfaces these.
- Don't mix instructions and raw data in the same paragraph — always separate with XML tags or clear headings.
- Don't put the question at the top when the context is long — questions at the bottom of a long prompt perform meaningfully better.
- Don't demand JSON/structured output only via prose — show the schema or use the native structured-outputs feature of the tool.
- Don't use prefilled assistant messages on Claude 4.6+ — deprecated; use structured outputs or explicit format instructions instead.
- Don't skip evals. Every non-trivial prompt change needs a test set — otherwise you're tuning on vibes.
- Don't optimise a prompt before you've defined what "good output" means. The eval criteria come first; the prompt serves them.
- Don't ship a prompt without a snapshot pin in production — model upgrades silently shift behaviour, and your evals are the only way to know.
- Don't trust a single model-grader score — ask for *strengths, weaknesses, reasoning, and score* together, otherwise the grader collapses to default-middling 5–7s.
- Don't conflate "the model failed" with "the prompt is wrong" without checking effort/reasoning settings first — shallow output at low effort isn't a prompt problem.
- Don't stack two personality blocks (Friendly + Pragmatic) in one agent persona — they cancel each other. See `references/agent-persona.md` for picking one.
- Don't paste snippets verbatim without checking conflicts — `default_to_action` and `do_not_act_before_instructions` are mutually exclusive; reducing-verbosity fights state-tracking persistence.
