---
name: second-opinion
description: Get an independent second opinion on a conclusion or finding from another agent (a different model or CLI) running in a Sidekick pane. Use when the user asks to "get a second opinion", "double-check this with another model", "have codex/opus review this", "sanity-check my conclusion", or when you want an honest adversarial cross-check of an answer before committing to it. Spawns the reviewer in the same tab, waits for its verdict, and reports it back.
---

# Second Opinion

Pause the current line of reasoning, hand the conclusion + its supporting evidence
to a *different* agent running in a Sidekick pane, let it independently scrutinize
the work, then bring its verdict back here so this agent can continue with it in
hand.

The reviewer is a separate CLI process (a different model or a different vendor),
not an internal subagent. That separation is the point — it gives a genuinely
independent take rather than the same model agreeing with itself.

## Preconditions

This skill only works inside an automation-enabled Sidekick pane. Check both:

```sh
test "$SIDEKICK_ENV" = 1
command -v sidekick-ctl
```

If either fails, tell the user this skill needs to run inside Sidekick and stop.

Discover the caller's pane and tab:

```sh
sidekick-ctl pane current
```

Record the current pane's `pane_id` (call it `$ORIGIN_PANE`) and its `tab_id`
(call it `$ORIGIN_TAB`) from the JSON. `$SIDEKICK_PANE_ID` is also the origin pane.

## 1. Decide the reviewer (provider + model)

Arguments are `<provider> <model>` — `provider` selects the CLI and its flags,
`model` is passed straight through.

- `claude <model>` → `claude -p "<prompt>" --model <model>`  (e.g. `claude opus-4-8`)
- `codex <model>`  → `codex exec -m <model> "<prompt>"`       (e.g. `codex gpt-5.6`)
- A bare model with no provider → assume `claude`.

⚠️ Flag trap: `-p` means `--print` in **claude** but `--profile` in **codex**.
Never reuse one CLI's flags for the other. Codex's non-interactive mode is the
`exec` subcommand, not `-p`.

**If no arguments were given, ASK the user** (this skill has no default reviewer).
Ask two things: which provider (claude or codex) and which model id. Use the
AskUserQuestion tool. Do not guess a model.

Available reviewers on this machine: `claude`, `codex` (and `ollama` for local
models, via `ollama run <model>` if the user asks for it).

## 2. Guard the pane limit (stay in the same tab)

A Sidekick tab holds at most **4 panes**, and `pane split` does **not** fall back
to a new tab — it fails if the tab is full. So check first:

```sh
sidekick-ctl pane list
```

Count panes whose `tab_id` equals `$ORIGIN_TAB`. If that count is already 4, do
NOT split (it would error). Instead tell the user the tab is full and offer to
close the reviewer pane from a previous run, or to reuse an existing agent pane.
Never silently spill into a new tab.

## 3. Assemble the review packet

Pick a short unique run id once and reuse it for every path below, e.g.
`RID=$(date +%s)`. Write the packet to `/tmp/second-opinion-in-$RID.md` containing:

1. **The claim under review** — the exact conclusion/answer/finding to scrutinize.
2. **The supporting evidence and reasoning** — how this agent got there (key code
   paths, command output, the logic). Give the reviewer enough to actually check
   the work, not just the headline.
3. **Relevant context** — the repo is the same `cwd`, so the reviewer can read
   files. Point it at the specific files/lines that matter.
4. **The framing instruction** (honest-critical — paste this verbatim):

   > You are giving an independent second opinion. Be genuinely critical first:
   > try to find what's wrong, look for flaws, edge cases, wrong assumptions, or a
   > better answer. Do your due diligence and get to the bottom of it. But stay
   > honest and accurate — if after real scrutiny the conclusion holds up, say so
   > plainly ("this looks correct") rather than inventing objections. End with a
   > clear verdict: AGREE, DISAGREE, or PARTIALLY AGREE, and your confidence, plus
   > the few points that most drove your verdict.

Write the file with the Write tool (clean, no shell-escaping headaches).

## 4. Launch the reviewer in a same-tab pane

Split the origin pane without stealing focus, in its working directory:

```sh
sidekick-ctl pane split "$ORIGIN_PANE" --direction right --cwd "$PWD" --no-focus
```

Read `result.pane.pane_id` from the JSON (call it `$REVIEWER_PANE`). Do not guess it.

Then run the reviewer non-interactively, capturing clean output to a file and
appending a sentinel so completion is unambiguous (no ANSI scraping):

claude:
```sh
sidekick-ctl pane run "$REVIEWER_PANE" \
  'claude -p "$(cat /tmp/second-opinion-in-'$RID'.md)" --model '"$MODEL"' > /tmp/second-opinion-out-'$RID'.md 2>&1; echo ___SO_DONE_'$RID'___'
```

codex:
```sh
sidekick-ctl pane run "$REVIEWER_PANE" \
  'codex exec -m '"$MODEL"' "$(cat /tmp/second-opinion-in-'$RID'.md)" > /tmp/second-opinion-out-'$RID'.md 2>&1; echo ___SO_DONE_'$RID'___'
```

The user sees the reviewer working live in the visible pane. Print/exec mode
applies the model at launch, so there's no separate "set the model" step to miss.

## 5. Wait, then read the verdict

Block until the sentinel appears (generous timeout — real reviews take minutes):

```sh
sidekick-ctl wait output "$REVIEWER_PANE" "___SO_DONE_$RID___" --timeout 600000
```

`wait` returns exit status 1 on timeout — if it times out, read the pane to see
what happened (`sidekick-ctl pane read "$REVIEWER_PANE" --source recent`) and
report it rather than assuming a verdict.

On success, read the captured answer (clean text, not a screen scrape):

```sh
cat /tmp/second-opinion-out-$RID.md
```

## 6. Clean up and report back

Close the reviewer pane (only the one this skill created) and remove temp files:

```sh
sidekick-ctl pane close "$REVIEWER_PANE"
rm -f /tmp/second-opinion-in-$RID.md /tmp/second-opinion-out-$RID.md
```

Then present the second opinion to the user inline, clearly attributed (which
provider/model gave it) and with its verdict (AGREE / DISAGREE / PARTIALLY AGREE)
up front. Do not paraphrase away disagreement — if the reviewer found a real
problem, surface it. Then continue this agent's own work informed by that opinion.

## Notes

- One reviewer is usually enough. For a stronger check you can repeat steps 3–6
  with a second provider, but mind the 4-pane limit.
- For genuine diversity, prefer a *different vendor* (codex when you're claude, or
  vice versa) over the same family with a different model.
- Do not close panes you did not create. Do not send input to a pane whose id and
  purpose you have not verified via `pane list` or the split response.
