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
4. **One change at a time** — Each step keeps the code working. Don't rewrite everything at once.
5. **Run tests after each step** — If tests fail, you changed behavior. Undo and try smaller.
6. **Stop when good enough** — Clear, tested, easy to change = done.

## Gotchas

- Don't extract abstractions used only once — three similar lines is better than a premature abstraction.
- Don't add design patterns just to demonstrate knowledge.
- Don't rename things across the entire codebase without asking.
- Don't change public APIs without understanding downstream impact.
- Don't refactor and add features in the same change — separate commits/PRs.
- Don't refactor code that works, is clear, and is tested just because you'd write it differently.
