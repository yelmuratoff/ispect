---
name: comments
description: Decide whether a comment is needed and write a useful one when it is — focused on the "why" behind non-obvious code, not narration of what the code does. Use this skill when adding or editing comments, reviewing a diff for excess commentary, cleaning up "AI thought" trails, writing doc comments for public APIs, or when the user pushes back on noisy/redundant comments.
---

# Comments

Decide whether a comment belongs, then make the comment earn its place.

## Steps

1. **Try removing the comment first.** Read the line(s) without it. If a competent reader still understands the code, leave the comment out.
2. **Rename before commenting.** If the intent is unclear, the fix is usually a sharper identifier (`isExpired` beats `// check if expired`). Reach for a comment only when naming and structure can't carry the meaning.
3. **Identify the _why_.** A comment belongs when it captures something the code itself cannot show:
   - a hidden constraint or invariant
   - an external quirk (API behavior, browser bug, ordering requirement)
   - a workaround for a known issue (name the issue)
   - a surprise the reader would otherwise question
4. **Write it tight.** One line where possible. State the reason, not the mechanism. Skip phrases like "this function…" or "we will now…".
5. **Public APIs get doc comments.** Document the contract — inputs, outputs, thrown errors, side effects — using the language's doc syntax (`///`, `/** */`, docstrings). Leave internal helpers quiet unless they hide a non-obvious constraint.
6. **Match the codebase.** Before adding comments to a new area, read 5–10 nearby files. Mirror their comment density, tone, and doc-comment style.

## Anti-pattern: narration & AI thought trails

```ts
// Step 1: get users
const users = await fetchUsers();

// loop through users
for (const u of users) {
  // validate user
  if (u.isValid) {
    save(u); // save to db
  }
}

// AI thought: this handles the empty case
if (users.length === 0) return;

// old logic — keep just in case
// function oldThing() { ... }
```

This narrates what the code already says, leaves planning markers, and keeps dead code "just in case". Strip it.

## Pattern: doc the contract, capture the surprise

```ts
/**
 * Synchronizes user records with the remote backend.
 *
 * Throws SyncError if the network fails or the payload is malformed.
 */
async function syncUsers(): Promise<void> {
  // Backend returns 404 for "no data yet" on freshly provisioned accounts —
  // treat it as an empty result, not an error.
  try {
    await api.fetch();
  } catch (e) {
    if (isNotFound(e)) return;
    throw e;
  }
}

// Self-explanatory — leave it alone.
const isAdult = (user: User) => user.age >= 18;
```

The doc comment states the contract; the inline comment captures a non-obvious upstream quirk; trivial code is left to speak for itself.

## Edge cases

- **Apologies in code** ("// hacky but works") — fix the code or file a tracked issue; let the comment go.
- **Task / PR / caller references** ("// added for ticket X", "// used by Y") — keep that context in the commit message; the source of truth shouldn't follow the work item around.
- **`TODO` / `FIXME` markers** — pair every one with an owner or a tracked issue, or resolve it now.
- **Translating code line-by-line into English (or any language)** — that's narration. Comment a constraint or a surprise instead, or remove the comment entirely.
- **Section banners** (`// ===== HELPERS =====`) — match the file: use them when nearby files already do, leave them out when they don't.
- **Commented-out code** — delete it. Git keeps history.
