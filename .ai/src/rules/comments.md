# Comment Rules

## Default: code over commentary

- Make the code self-explanatory first. Reach for a clearer name, a smaller function, or a better type before adding a comment.
- Write a comment only when the code _cannot_ carry the meaning on its own — a hidden constraint, an external quirk, a workaround, or a surprise a reader would otherwise question.
- If a comment can be removed without confusing a future reader, leave it out.

## When a comment earns its place

- **Hidden constraints**: a non-obvious invariant, ordering requirement, performance assumption, or external API quirk a reader can't see from the code.
- **Workarounds**: a fix for a specific bug or upstream issue — name the system, link the issue if you have one.
- **Surprises**: behavior that would make a reasonable reader pause ("why is this list reversed?", "why catch this error silently?").
- **Public APIs**: document the contract (inputs, outputs, errors, side effects) using the language's doc-comment syntax (`///`, `/** */`, docstrings).

## Style

- Comment _why_, not _what_. State the reason, the constraint, or the surprise — leave the mechanism to the code.
- Keep inline comments to one line. If a paragraph feels necessary, the surrounding code probably wants renaming or splitting first.
- One space after the comment marker: `// like this`.
- Use the language's doc-comment syntax for public APIs only. Internal helpers stay quiet unless they hide a non-obvious constraint.
- Match the project's existing comment density and tone — read 5–10 nearby files before changing the style.

## Keep out

- Narration of what the code does ("// increment counter", "// loop through users").
- Planning artifacts and AI thought trails ("// Step 1:", "// now we will…", "// this handles the case where…").
- References to the current task, PR, ticket, or caller — that context lives in the commit message.
- Commented-out code. Delete it; git keeps history.
- `TODO`/`FIXME` markers without an owner or tracked issue — either resolve them now or file a ticket.
- Decorative banners and dividers (`// ===== HELPERS =====`) unless the file already uses them consistently.
