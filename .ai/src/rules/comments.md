# Comments

A comment earns its place when it captures something the code itself cannot show — a hidden constraint, an external quirk, a workaround, or a surprise the reader would otherwise question. Everything else lives in the code.

## The test

Read the line without the comment. If a competent reader still understands the code, leave the comment out. Reach for a sharper identifier (`isExpired` beats `// check if expired`) or a smaller function before reaching for prose.

## Where a comment helps

- **Hidden constraint** — a non-obvious invariant, ordering requirement, performance assumption, or external API quirk.
- **Workaround** — a fix for a specific upstream bug or platform behaviour. Name the system, link the issue when you have one.
- **Surprise** — behaviour that would make a reasonable reader pause ("why is this list reversed?", "why catch this error silently?").
- **Public API contract** — inputs, outputs, errors, side effects — via the language's doc-comment syntax (`///`, `/** */`, docstrings). Internal helpers stay quiet unless they hide a constraint.

## Style

- Describe *why*, not *what*. The code shows the mechanism; the comment supplies the reason.
- One line where possible. A paragraph usually signals the surrounding code wants splitting or renaming.
- Single space after the marker: `// like this`.
- Match the file's existing density and tone — scan 5–10 nearby files before changing the style.
- Pair every `TODO` / `FIXME` with an owner or a tracked issue, or resolve it now.
- Match section banners (`// ===== HELPERS =====`) to what the file already uses.

## Examples

```
// Sharper name beats a narrating comment:
- // check if user is an adult
- if (user.age >= 18) { ... }
+ const isAdult = user.age >= 18;
+ if (isAdult) { ... }

// Step markers and narration belong in the diff, not the file:
- // Step 1: fetch users
- const users = await fetchUsers();
- // loop through users
- for (const u of users) { ... }
+ const users = await fetchUsers();
+ for (const u of users) { ... }

// A real "why" comment earns its keep:
+ // Backend returns 404 for "no data yet" on new accounts — treat as empty.
+ if (isNotFound(e)) return;

// Doc comments capture the contract on a public API:
+ /**
+  * Synchronizes user records with the remote backend.
+  * Throws SyncError on network failure or malformed payload.
+  */
+ async function syncUsers() { ... }
```

Unused code belongs in git history rather than in commented-out blocks. Task numbers, PR references, and caller lists belong in the commit message rather than in the source.
