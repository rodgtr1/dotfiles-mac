---
name: agent-deliberation
description: Run two independent agents (Claude + Codex) against the same task in separate Sidekick panes, then have them cross-examine and revise each other's work over a fixed 4-stage pipeline, with a neutral third agent judging the final synthesis. Use when the user wants "agent deliberation", "have two agents debate", "Claude vs Codex on this", "build it twice and reconcile", or an adversarial-collaboration take on a task/post/answer/decision where one agent's blind spots should be caught by another.
---

# Agent Deliberation

Two independent agents solve the **same task** in parallel, then critique and
revise against each other, and a neutral third agent renders the final verdict.
It's the iterated, two-builder version of `second-opinion` — adversarial
collaboration, not a single model agreeing with itself.

The pipeline is **fixed at four stages** (no open-ended loop, so cost and time are
bounded):

1. **Independent conclusions** — both agents solve the task blind to each other.
2. **Cross-examination** — each attacks the *other's* answer.
3. **Weigh the findings** — each receives the critique leveled *against it*,
   concedes the valid points, rebuts the rest, and revises.
4. **Combined output** — a neutral third agent reads both revised answers plus the
   critiques and produces one final synthesis.

Total: 6 worker runs (2+2+2) plus 1 judge run = 7. No infinite-loop risk.

## Why it's built the way it is (read this — it's why the steps are short)

This skill reuses the proven mechanics of `second-opinion`. The non-obvious parts:

- **Workers only READ their prompt and PRINT output — they never need file-write
  or repo-read permission.** `claude -p` and `codex exec` run with restricted tool
  permissions and may silently skip a file write or a Read. So the moderator (you)
  embeds *all* needed context directly inside each prompt file, and each worker
  prints its answer between markers. You slice the marked block out of the pane and
  save it yourself with the Write tool. Zero permission dependency on the workers.
- **Wait on agent-status, NOT on the output marker.** The worker echoes your entire
  prompt (markers included) the instant it starts, so an output-wait on the marker
  returns immediately on that echo, before any real work exists. Wait for the pane's
  agent status to go `working` then `done` (the same Stop signal the Agent Panel
  shows). The marker is for *extraction only*.
- **No model guessing.** Use each CLI's own default model. Passing a model id is the
  #1 cause of "model not supported for this account". Only pass one if the user
  names it.
- **Anti-derail header, verbatim and FIRST in every prompt.** The worker CLIs may
  have *this very skill* installed and will otherwise try to run a deliberation of
  their own. Forbid it explicitly.

## Preconditions

Must run inside an automation-enabled Sidekick pane:

```sh
test "$SIDEKICK_ENV" = 1 && command -v sidekick-ctl
```

If that fails, tell the user this skill needs to run inside Sidekick and stop.

Find the origin pane + tab and record them:

```sh
sidekick-ctl pane current   # record pane_id ($ORIGIN_PANE) and tab_id ($ORIGIN_TAB)
```

Confirm `codex` is available (`command -v codex`). If it is missing, tell the user
and offer to run **Claude vs Claude** instead (two fresh independent sessions) —
the pipeline is identical, only the second builder's CLI changes.

## Pane budget (a tab holds at most 4 panes)

You need **2 worker panes** (Claude builder + Codex builder). The origin pane is
the 3rd. The Stage-4 judge **reuses one of the two builder panes** (run a fresh CLI
invocation in it) rather than opening a 4th — keep one slot free. Before splitting:

```sh
sidekick-ctl pane list   # count panes whose tab_id == $ORIGIN_TAB
```

If the tab already has ≥3 panes, you can't fit both builders — tell the user and
offer to close an idle pane first.

## Setup

Pick a run id once and make a work dir for the prompt/answer files:

```sh
RID=$(date +%s); D=/tmp/delib-$RID; mkdir -p "$D"
```

Split two worker panes in the same tab (read each `result.pane.pane_id` from the
JSON — never guess):

```sh
sidekick-ctl pane split "$ORIGIN_PANE" --direction right --cwd "$PWD" --no-focus   # → $PANE_CLAUDE
sidekick-ctl pane split "$ORIGIN_PANE" --direction down  --cwd "$PWD" --no-focus   # → $PANE_CODEX
```

`$PANE_CLAUDE` runs `claude -p`, `$PANE_CODEX` runs `codex exec` throughout. Keeping
each agent in its own pane lets the user watch both think live, side by side.

⚠️ **Flag trap:** `-p` is `--print` in **claude** but `--profile` in **codex**.
Codex's non-interactive mode is the `exec` subcommand. Add `-m`/`--model` ONLY if
the user named a model.

## The per-stage mechanic (used identically in stages 1–4)

For every worker run, do exactly this:

1. **Write the prompt file** with the Write tool (clean — no shell escaping). Every
   prompt file begins with the anti-derail header verbatim, then the task/context
   **fully embedded inline**, then the marker spec at the end.
2. **Launch** the CLI, passing the file via `cat`:
   - Claude pane: `sidekick-ctl pane run "$PANE_CLAUDE" 'claude -p "$(cat '$D'/PROMPT.md)"'`
   - Codex pane:  `sidekick-ctl pane run "$PANE_CODEX"  'codex exec "$(cat '$D'/PROMPT.md)"'`
3. **Wait for it to actually finish** (two phases so a stale status can't fool you):
   ```sh
   sidekick-ctl wait agent-status "$PANE" working --timeout 60000   # it STARTED
   sidekick-ctl wait agent-status "$PANE" done    --timeout 600000  # it FINISHED
   ```
   `wait` exits non-zero on timeout. If phase 1 times out the launch failed — read
   the pane and report rather than assuming output.
4. **Extract and save** the marked block yourself:
   ```sh
   sidekick-ctl pane read "$PANE" --source recent --lines 800 \
     | awk '/<<<<<DELIB/{c=""; f=1; next} /DELIB>>>>>/{f=0} f{c=c$0"\n"} END{printf "%s", c}' \
     > "$D/OUT.md"
   ```
   The awk resets on each opening marker, so the **last** (real) block wins over the
   prompt echo. Verify `$D/OUT.md` is non-empty before proceeding; if the markers
   never appear the worker errored or derailed — read the last ~100 lines raw and
   report.

The marker the workers must print around their answer, every stage:

```
<<<<<DELIB
…the full answer / critique / revision…
DELIB>>>>>
```

Stages 1's two runs are independent → launch both, then wait on both (they run
concurrently in their two panes). Same for stage 2 and stage 3.

## Stage 1 — Independent conclusions

Both prompt files contain the **same task**, embedded in full, and the instruction
to solve it completely and print the answer between the markers. Neither sees the
other. Run both panes concurrently. Save → `$D/s1-claude.md`, `$D/s1-codex.md`.

## Stage 2 — Cross-examination

Each agent attacks the **other's** Stage-1 answer (embed the rival answer inline):

- Claude's prompt embeds `s1-codex.md` → "Here is a rival solution to the task.
  Hunt for what's wrong: flaws, missing cases, wrong assumptions, weaker approach.
  Be specific and cite the part you mean. Stay honest — if a part is genuinely
  strong, say so. Print your critique between the markers."
- Codex's prompt embeds `s1-claude.md` with the same framing.

Save → `$D/s2-claude-crit.md` (Claude critiquing Codex), `$D/s2-codex-crit.md`
(Codex critiquing Claude). Run concurrently.

## Stage 3 — Weigh the findings

Each agent receives **its own Stage-1 answer** plus the **critique leveled against
it**, and revises:

- Claude's prompt embeds `s1-claude.md` + `s2-codex-crit.md` → "Here is your earlier
  answer and the objections raised against it. For each objection, concede it (and
  fix) or rebut it (with a concrete reason). Then print your revised, final answer
  between the markers."
- Codex's prompt embeds `s1-codex.md` + `s2-claude-crit.md` with the same framing.

Save → `$D/s3-claude.md`, `$D/s3-codex.md`. Run concurrently.

## Stage 4 — Combined output (neutral third-agent judge)

A **fresh** agent with no stake produces the final synthesis. Reuse one builder
pane (it's idle now) for the judge run. For neutrality, prefer the CLI that did
*not* author the version you'd otherwise be tempted to favor — a sensible default
is to run the judge as `codex exec` in `$PANE_CODEX` (or `claude -p`; either is
fine since the judge gets both sides). The judge prompt embeds **both revised
answers** (`s3-claude.md`, `s3-codex.md`) and **both critiques** (for context on
what was contested):

> You are a neutral judge. Two independent agents solved the same task, critiqued
> each other, and revised. Below are both final versions and the critiques
> exchanged. Produce the single best final answer: take the stronger choice on each
> point that still differs between them, merge complementary strengths, and drop
> what was validly refuted. Where they still genuinely conflict, decide on the
> merits and state the call briefly. Print the final combined answer between the
> markers.

Save → `$D/s4-final.md`. This is the deliverable.

## Clean up and report

```sh
sidekick-ctl pane close "$PANE_CLAUDE"   # only panes you created
sidekick-ctl pane close "$PANE_CODEX"
# keep $D for the user if they want the full transcript; otherwise: rm -rf "$D"
```

Present to the user:

1. **The final combined output** (`s4-final.md`) up front — that's what they asked
   for.
2. A short **deliberation summary**: the main points each agent raised in
   cross-examination, what got conceded vs. rebutted in Stage 3, and which way the
   judge broke any remaining conflicts. Don't paraphrase away real disagreement — if
   a substantive conflict survived to the judge, name it and how it was resolved.

Offer to keep the worker panes open if the user wants to scroll the live reasoning,
and mention `$D` holds every stage's file if they want the full transcript.

## Notes & options

- **Claude vs Claude fallback** — if `codex` is absent, run two fresh `claude -p`
  sessions as the builders. Diversity drops, but the cross-examination still
  surfaces issues a single pass misses.
- **Scope is general-purpose** — the task can be code, a blog post, an answer, or a
  decision. For code specifically, you *may* additionally let the workers read the
  repo (they run in `$PWD`), but never depend on it — embed the diff/context inline
  so the pipeline works even when their read permission is restricted.
- **Never** close panes you didn't create, send input to a pane whose id/purpose you
  haven't verified via `pane list`, or pass a model id the user didn't name.
- One pass through the four stages is the design. If the user wants more rounds,
  repeat stages 2–3 before the judge — but say you're doing so and watch the cost
  (each extra round is 2 more runs).
