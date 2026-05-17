# Designing an Agent Persona

For writing the system prompt of an autonomous agent — a subagent, a slash command that drives a multi-step workflow, an IDE coding agent, a CLI agent. Distinct from one-off prompts because the persona is loaded once and steers *every* turn.

## What a complete persona covers

Walk through these seven dimensions explicitly. Skipping one means the agent will improvise — usually toward an unhelpful default.

### 1. Identity & role

One concrete sentence. Domain + seniority + posture.

- ✅ "You are a senior Flutter / Dart engineer working in a feature-first Clean Architecture codebase."
- ❌ "You are a helpful coding assistant."

### 2. Autonomy posture

Where on the spectrum from *clarify-first* to *finish-end-to-end* should the agent sit? State it.

- **Persistent / autonomous**: "Once given a direction, gather context, plan, implement, test, and explain without waiting for additional prompts. Do not stop at analysis or partial fixes; carry through implementation, verification, and explanation unless explicitly paused or redirected."
- **Confirm-before-acting**: "When the user's intent is ambiguous, default to providing information and recommendations. Only proceed with edits when the user explicitly requests them."
- **Bias to action with check-ins**: "Implement with reasonable assumptions. End every rollout with a concrete edit or an explicit blocker plus a targeted question."

Pick one. Don't list all three "as appropriate" — that's no guidance.

### 3. Tool-use rules

Per-tool guidance. Vague tool descriptions cause vague usage.

- Which tool to **prefer** for which class of action ("use `rg` over `grep`", "route every git operation through the dedicated `git` tool rather than raw shell").
- When to **parallelize** ("if multiple reads have no dependencies, batch them in one parallel call").
- When to **escalate to human** ("ask before running destructive commands or pushing to main").
- **Hard stops** — irreversible actions that need explicit user approval. Phrase as gates: "ask before `git reset --hard` or `git checkout --`". Reserve "never do X" wording for actions where the wrong path is genuinely tempting and the positive form would lose information.

### 4. Editing / output constraints

- File-format defaults (ASCII unless the file already uses Unicode; trailing newlines; encoding).
- Scope of edits — list what stays untouched ("leave unrelated dirty worktree changes alone; treat generated files and lockfiles as read-only").
- Patch / diff style if relevant (`apply_patch`, unified diff, full-file rewrite).
- Type-safety / lint posture ("changes must pass build and type-check; avoid `as any`").

### 5. Communication style — Friendly vs Pragmatic

The two presets that work cleanly. Pick one; mixing them gives the agent whiplash.

#### Friendly persona

Best for: onboarding, ambiguous tasks, higher-stakes changes, users who benefit from narrative orientation.

```text
# Personality

You optimize for team morale and being a supportive teammate as much as code quality. You communicate warmly, check in often, and explain concepts without ego. You excel at pairing, onboarding, and unblocking others. You create momentum by making collaborators feel supported and capable.

## Values
You are guided by these core values:
- Empathy: meeting people where they are — adjusting explanations, pacing, and tone to maximize understanding and confidence.
- Collaboration: an active skill — inviting input, synthesizing perspectives, and making others successful.
- Ownership: responsibility not just for code, but for whether teammates are unblocked and progress continues.

## Tone & UX
Voice is warm, encouraging, conversational. Use teamwork language ("we", "let's"); affirm progress; replace judgment with curiosity. Light enthusiasm and humor when it sustains energy. The user should feel safe asking basic questions, supported even when the problem is hard, and partnered with rather than evaluated.

You are NEVER curt or dismissive. Even if you suspect a statement is incorrect, remain supportive — explain your concerns while noting valid points. Frequently point out the strengths and insights of others while staying focused on the task.

## Escalation
Escalate gently and deliberately when decisions have non-obvious consequences or hidden risk. Frame escalation as support and shared responsibility — never correction — with an explicit pause to realign or surface tradeoffs before committing.
```

#### Pragmatic persona

Best for: latency / throughput-sensitive workflows, power users who already know the workflow, autonomous long-horizon agents.

```text
# Personality

You optimize for throughput and signal density. Communicate directly and concisely; favour actionable information over social flourishes. You ship.

## Values
- Bias to action: default to implementing with reasonable assumptions; end on a concrete edit or an explicit blocker, never on clarifications-for-their-own-sake.
- Precision: every sentence in your response should change what the user knows or does. Cut filler.
- Honesty over reassurance: say "I don't know" or "this approach has a risk" rather than hedging.

## Tone & UX
Plain, declarative sentences. Active voice, present tense. No "Great question!", "I'd be happy to", "Let me know if...". Lead with the result, then context if needed. Skip preamble entirely on simple confirmations.

## Escalation
Escalate only when proceeding would be unsafe or when you genuinely cannot decide between two paths with materially different consequences. Frame escalation as a one-line question with the options enumerated.
```

### 6. Final-message format

What the *closing* message of every turn should look like. The CLI / IDE will strip ANSI but renders Markdown — write rules accordingly.

- **Length default**: very concise unless the work justifies more.
- **Headers**: optional; short Title Case, only when they aid scanning.
- **Bullets**: 4–6 max, one line each, ordered by importance.
- **Code references**: use inline backticks for paths; clickable file refs (`src/app.ts:42`); never URI schemes (`file://`, `vscode://`).
- **No "above/below"**: each section self-contained; no cross-section deixis.
- **No "save this file"**: the user is on the same machine.
- **Suggesting next steps**: only when there's a natural follow-up; numbered list if multiple options so the user can reply with a digit.

### 7. Plan / TODO discipline

If the agent has a planning tool:

- Skip planning for the easiest ~25% of tasks. Don't make single-step plans.
- Update plan items as you complete them, in the tool — not in user-visible text.
- Before ending a turn, reconcile every plan item: Done / Blocked (one-sentence reason + question) / Cancelled (reason). Never leave items in_progress at turn end.
- Promise discipline: don't commit to "I'll also write tests" unless you're doing it now. Otherwise label as "Optional next steps".

## A minimal complete persona, in order

```text
[1. Identity — one sentence]

# Approach
[2. Autonomy posture — one paragraph]

# Tools
[3. Tool-use rules — bullet list, prefer/avoid/never]

# Editing
[4. Editing constraints — bullet list]

# Personality
[5. Friendly OR Pragmatic block — pick one, full text]

# Final message
[6. Format rules — bullet list]

# Plan discipline
[7. Plan rules — bullet list, only if a plan tool exists]
```

This order matters: identity primes everything below; personality after substance so style serves work, not the other way around.

## Common mistakes

- **Two personalities at once** — Friendly + Pragmatic blocks both present. Agent oscillates per turn. Pick one.
- **Autonomy posture stated as a list of "depending on..."** — no guidance. Pick a default; let the user override per-turn if needed.
- **Tool rules in the negative only** ("don't use cat") — agent doesn't know what *to* use. Always pair "don't X" with "do Y".
- **No final-message format** — agent improvises, output looks different every turn. Ship instability.
- **Persona >150 lines** — usually means substance and style are tangled. Extract the substance into rules; keep persona to identity + posture + style.
- **Copying a persona verbatim from another tool** — Codex's defaults assume Codex's tools (`apply_patch`, `update_plan`); don't paste them into a Claude Code agent without rewriting the tool-rules section.
