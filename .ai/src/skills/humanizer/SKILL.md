---
name: humanizer
description: Rewrite text so it reads like a real human wrote it, or generate long-form prose (blog posts, essays, articles, newsletters, social posts, op-eds, short stories) in that same plain, grounded voice. Strips common AI tells, including em dashes, semicolons, framing colons, inflated vocabulary (utilize, leverage, delve, tapestry, robust), contrastive negation, significance inflation, forced triads, sycophantic openers, and chatbot closers. Trigger whenever the user asks to humanize, de-AI, or de-slop text, even with casual phrasing like "make this less AI-sounding," "fix the AI vibe," or equivalent phrasing in any language. Also trigger when the user asks Claude to write a prose deliverable they will publish or share, like an article, blog post, essay, newsletter, or short story. Do not use for code, casual chat replies, or technical documentation.
---

# Humanizer

Rewrite text, or generate prose from scratch, so it reads like a real person wrote it. Clear, direct, grounded. Preserve every fact, claim, and piece of core meaning from the source. Add nothing that is not there. Keep roughly the same length unless the original is bloated.

## Two modes

**Rewriting existing text.** The user pastes something (often AI-written, sometimes their own) and asks for a humanized version. Read the source carefully, then return only the rewritten text in the same language as the input. No preamble, no explanation, no closing remark.

**Generating new prose.** The user asks for a blog post, essay, article, newsletter, op-ed, short story, or similar deliverable. Apply these same principles from the very first draft so the output never has the AI tells to begin with. Skip the dutiful AI moves while generating: no setup paragraph that explains what you are about to do, no qualifier-laden hedging, no closing summary of what the reader just read.

Apply this style to prose deliverables the user will publish or share. Skip it for code, casual conversational replies, technical documentation, lists the user specifically asked for, or anything where the user explicitly wants a different voice.

## Format

Write in flowing paragraphs. If the input has lists, bullets, or bold-header sections, convert them into prose with real transitions. Structure should come from the logic of the ideas, not from visual markup.

Allowed punctuation: commas, periods, parentheses, question marks. Question marks are fine in normal proportion, including the rhetorical kind, because real writers use them constantly. Reserve exclamation marks for a real moment of emphasis or surprise. Filler intensifiers in the AI manner ("This is huge!", "What a game-changer!") are tells — leave them out.

Actively remove the following:

- Em dashes (—), en dashes (–), and hyphens (-) used for pauses or parenthetical asides become commas or separate sentences.
- Colons (:) used for lists or rhetorical framing, the "Feature: explanation" move, become natural sentences.
- Semicolons (;) become periods.
  The reason this matters: these marks are some of the strongest AI tells in modern text, em dashes especially. Pulling them out forces a sentence-level rewrite that breaks the AI rhythm, which is the whole point.

No bold inside body text. Bolding random words mid-paragraph for emphasis is almost exclusively an AI tic, and it disappears from real writing the moment a human takes over. Italics are allowed for the normal writerly purposes, titles of works, foreign terms, the occasional moment of genuine stress, but never as a substitute for the banned bold or sprinkled through paragraphs to add fake texture.

## Vocabulary

Use short, common words. Replace inflated vocabulary with plain alternatives. Some English anchors:

- "utilize" becomes "use"
- "facilitate" becomes "help"
- "embark on" becomes "start"
- "leverage" becomes "use"
- "serves as" / "stands as" / "functions as" / "boasts" become "is," "are," or "has"
- "pivotal" / "crucial" / "paramount" get cut, or replaced once with "important" if absolutely needed
  Cut or rewrite around these AI-favorite words entirely: delve, tapestry, landscape (when used abstractly), realm, interplay, intricacies, furthermore, moreover, consequently, additionally, underscore, showcase, testament, enduring, vibrant, seamless, robust, groundbreaking, nestled, breathtaking, renowned, synergy, holistic, multifaceted, garner, foster, harness, elevate.

The same trap shows up in every language with different vocabulary. The principle is universal: when a word sounds inflated, abstract, official, or fancy compared to how a person would actually say the thing, swap it for the plain everyday equivalent in whatever language the piece is in. Trust your ear over any specific list.

## Rhythm

Vary sentence length on purpose. Put a short sentence after a long one sometimes. Let some sentences run long before they land. If a paragraph has a monotone hum of equal-length sentences, break the pattern. AI text drifts toward sentences of similar medium length and the resulting steady metronome tone is one of the easiest things to spot.

## Voice

React to the material when the tone allows it. A short aside, an honest note of uncertainty, a mild opinion, these are what makes writing feel like a person and not a template. Aim for the tone of a smart person explaining something to a friend. Direct, a little informal, still respectful of the subject.

## Patterns to rewrite as direct statements

When any of the following show up in a draft, rewrite. State the actual point plainly.

Contrastive negation ("Not X, but Y," "It's not X, it's Y," "Not just X, but Y," "Not X, not Y, but Z") becomes one positive sentence that says the point directly. The same shape works in any language — the giveaway is the negated half existing only as a setup for the affirmative half. Write the affirmative half on its own.

Faux reframes ("more than just X," "goes beyond Y," "represents more than just") become a plain statement of what the thing actually is.

Significance inflation ("marks a pivotal moment in," "stands as a testament to," "reflects broader trends," "sets the stage for") becomes the concrete fact, without the editorial packaging around it.

Participial tags that just restate the previous clause (", making it easier to Y," ", highlighting the importance of Z") get cut. End the sentence before the comma.

False ranges ("From X to Y, from A to B") become a plain list or a single sentence that describes the scope.

Performative fragment pairs ("The result? Better outcomes.") become one normal sentence.

Sycophantic openers ("Great question!," "Certainly!," "Absolutely!") get deleted. Start with the content.

Chatbot closers ("I hope this helps," "Let me know if you'd like me to expand") get deleted.

Knowledge-cutoff disclaimers ("While specific details are limited...," "based on available information...") get replaced with a plain statement of what is known, no apology for what is not.

Formulaic "challenges" arcs ("Despite its success, X faces challenges... Despite these challenges, it continues to thrive") get replaced with a real description of the situation, without the synthetic narrative arc.

Section summaries ("In summary," "Overall," "In conclusion") get deleted. End the section instead. The reader just read it; restating it is filler.

Forced triads, ideas grouped into threes to sound balanced, get trimmed to only the items that matter.

Vague authority ("experts argue," "observers note") gets replaced with the claim itself, or with a specific source if one exists in the original.

Generic upbeat endings ("the future looks bright," "exciting times lie ahead") get replaced with a specific concrete detail.

Hedging stacks ("could potentially perhaps be somewhat") get one qualifier and then move on.

Empty intensifiers (powerful, compelling, meaningful, profound, robust, scalable, strategic, transformative, sophisticated) get cut or replaced with the specific reason behind the praise. If you cannot name the reason, the adjective was filler.

Pivot transitions (That said, That being said, Having said that, With that in mind, On that note) get deleted. If the next sentence actually pivots, the content does the work; the announcement is redundant.

Metaphor verbs for "explain" (unpack, unlock, decode, dive into, peel back the layers, shed light on) get replaced with plain ones: look at, show, explain, describe.

## Paragraph structure

Vary how paragraphs begin. Sometimes with a specific detail, sometimes with a claim, sometimes mid-thought. A paragraph that opens with a topic sentence, fills in evidence, then closes with a summary of itself, that paragraph feels assembled. Real writing varies its shape.

## Final pass

Before returning the result, read what you wrote with fresh eyes and check three things.

First, scan for forbidden marks. Any em dashes, en dashes, hyphens used as pauses, semicolons, framing colons that slipped through, fix them now. Any bold mid-paragraph, kill it.

Second, scan for the banned vocabulary list. The longer the piece, the more likely a "delve" or "utilize" or "данный" snuck back in. Replace it.

Third, find any sentence that still sounds templated, promotional, or structurally identical to a nearby sentence. Rewrite those.

Only then return the result.

## Output

Return only the rewritten or generated text, in the same language as the input or the user's request. No preamble, no explanation, no closing remark.

Default to delivering the text inline in the chat reply, not as a separate file. The user is usually tuning the voice and needs to see the result immediately, react to it, and iterate. Only save to a markdown file if the piece is genuinely long (roughly 1500+ words, like a full essay or a short story) or if the user explicitly asks for a file.

## Reference

`references/wikipedia_signs_of_ai_writing.md` is a condensed field guide of AI-writing tells (significance inflation, superficial-analysis participles, AI vocabulary, copula substitution, negative parallelisms, false ranges, inline-header lists, knowledge-cutoff disclaimers, and so on). It expands on the patterns named above with trigger-word lists and short examples. Consult it when a draft has a pattern that does not match anything in this file, or when the user asks why a specific phrase reads as AI.

## Bundled script: typographic cleanup

`scripts/strip-ai-chars.sh` is a deterministic stdin-to-stdout filter. It strips invisible / zero-width / bidi-formatting / tag-character watermarks, removes decorative symbols not on any keyboard (math alphanumerics, arrows, math operators, box drawing, enclosed alphanumerics, dingbat bullets), normalises curly quotes / dashes / ellipsis / NBSP to ASCII, and trims trailing whitespace. Preserves every script's letters, emoji, and common symbols (✓ ✗ ★ ❤ ™ № etc.). Does not change wording. Requires `perl` (ships on macOS, Linux, Git Bash on Windows).

    bash scripts/strip-ai-chars.sh < input.txt

Use it when the user wants typographic-only cleanup (return its output verbatim, no prose changes) or as a pre-pass before semantic rewriting. If intent is unclear, ask once.
