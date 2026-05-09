# Metaprompting

Ask the model to improve its own instructions. Most powerful technique when you can't pinpoint *why* a prompt under-performs but you can see *that* it does.

## When to use

- A prompt produces good output but slowly (overthinks, re-reads files, takes too long to first useful action).
- A prompt produces wrong output and you can't tell which instruction is the culprit.
- A prompt has accreted over many edits and feels muddled — you suspect redundancy or contradiction but can't see it.
- You inherit a prompt from someone else and want a second opinion before tuning.

## When NOT to use

- The prompt is short and clear — you can debug it by reading.
- The model is producing output that *looks fine* and you have no eval signal — metaprompting will surface plausible-but-empty edits.
- You haven't run an eval yet — without ground truth, you can't tell if the model's suggested changes are actually improvements.

## Template

Run this *immediately after* a turn that under-performed, in the same conversation, so the model has the failure context fresh.

```text
That was a high quality response, thanks! It seemed like it took you a while to finish responding though. Is there a way to clarify your instructions so you can get to a response as good as this faster next time? It's extremely important to be efficient when providing these responses or users won't get the most out of them in time. Let's see if we can improve!

think through the response you gave above
read through your instructions starting from "<paste the first 10–20 words of your system prompt here>" and look for anything that might have made you take longer to formulate a high quality response than you needed
write out targeted (but generalized) additions/changes/deletions to your instructions to make a request like this one faster next time with the same level of quality
```

Adapt the framing to the failure mode:

- **Slow / overthinking** → use the template above as-is.
- **Off-format / wrong structure** → replace "took you a while" with "didn't follow the requested format" and ask what instruction made the format ambiguous.
- **Missed a requirement** → ask which instruction would have made the requirement unmissable.
- **Too verbose / wrong tone** → ask which instruction allowed the tone to drift.

## How to filter the model's suggestions

Single-run output from metaprompting is **noisy**. The model often proposes:
- Overly specific edits tuned to *this exact* failure ("when the user asks about X, do Y") — won't generalize.
- Plausible-sounding but redundant additions (rephrasing rules already in the prompt).
- Cosmetic reordering with no behavioural effect.

The fix: **run it 2–3 times in fresh conversations**, then keep only suggestions that **recur across runs**. Recurring suggestions usually reflect a real ambiguity in the prompt; one-off suggestions are usually pattern-matching to the specific failure.

For each surviving suggestion:

1. **Generalize it** — strip references to the specific user request. The edit should work for *any* request of this class, not just this one.
2. **Check it doesn't contradict an existing instruction** — metaprompting often adds rules that quietly override earlier ones.
3. **Apply it and re-run the eval** — if the score doesn't move, revert. Don't keep edits on faith.

## Example session

Original prompt has 800 lines. Failure: agent reads files one at a time, takes 4× longer than expected. After running the metaprompt 3 times, recurring suggestion across all three runs:

> Add an explicit rule: "Before any tool call, decide all files/resources you will need, then issue them in a single parallel batch. Do not read files one-by-one unless you literally cannot know the next file without seeing the previous result."

That's recurring + generalizable + non-conflicting → apply, re-run eval, keep if score improves.

Ignored from the same runs (only appeared in one): "Skip reading test files when the user mentions a bug" — too specific, would break for other workloads.

## Iteration boundary

Metaprompting is a debugging tool, not a design tool. Use it to surface issues with an existing prompt, not to write a new one from scratch — for that, start from a vetted reference (Anthropic best-practices, OpenAI Codex starter prompt) and trim.

When the model's metaprompt suggestions stop changing across runs (you see the same handful of "improvements" that have already been applied), the prompt has stabilized — stop. Further metaprompting at that point produces noise.
