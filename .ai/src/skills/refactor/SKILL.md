---
name: refactor
description: Restructure existing code without changing its behavior — reduce duplication, improve naming, simplify complex logic, extract helpers, split overgrown functions, untangle dependencies. Use this skill when the user asks to refactor, clean up, simplify, DRY out, rename, extract a helper, split a file, or make code "nicer" — including when they describe code-quality concerns without using the word "refactor" (e.g. "this is messy", "приведи в порядок", "это можно сделать чище").
---

# Refactor

Safely restructure code while preserving existing behavior.

## Steps

1. **Verify tests exist** — Before touching anything, confirm test coverage on the code you'll change. If tests are missing, write them first against current behavior.
2. **Name the problem** — What exactly is wrong?
   - Duplicated logic? Function doing too many things? Poor naming? Tangled dependencies? Wrong abstraction?
3. **Plan the change** — Describe what you'll do before doing it. Small, safe steps.
4. **One change at a time** — Each step keeps the code working. Big rewrites collapse on themselves; small steps stay reversible.
5. **Run tests after each step** — If tests fail, you changed behavior. Undo and try smaller.
6. **Stop when good enough** — Clear, tested, easy to change = done.

## Gotchas

- Extract abstractions only when there is real duplication — three similar lines beat a premature helper.
- Reach for a design pattern when the problem calls for one, not to demonstrate knowledge.
- Confirm with the user before renaming across the entire codebase — the blast radius is bigger than it looks.
- Map the downstream callers before touching a public API.
- Keep refactors and feature work in separate commits or PRs.
- Leave code alone when it works, is clear, and is tested — personal preference is not a reason to refactor.
