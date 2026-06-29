---
name: second-opinion
description: Get an independent second opinion on a conclusion or finding from another agent (a different model or CLI) running in a Sidekick pane. Use when the user asks to "get a second opinion", "double-check this with another model", "have codex/opus review this", "sanity-check my conclusion", or when you want an honest adversarial cross-check of an answer before committing to it. Spawns the reviewer in the same tab, waits for its verdict, and reads it straight off the pane.
---

# Second Opinion

Hand the current conclusion + the evidence (especially the code you changed or are
about to change) to a *different* agent running in a visible Sidekick pane, let it
independently scrutinize the work, then read its verdict back and continue with it
in hand.

The reviewer is a separate CLI process (a different model or vendor), not an
internal subagent. That separation is the point — an independent take, not the
same model agreeing with itself.

## Design (read this — it's why the steps are short)

Sidekick panes are readable. `sidekick-ctl pane read <id> --source recent` returns
**clean, ANSI-stripped text** from a 64 KB rolling buffer. So:

- **No output file.** The reviewer runs in the pane (the user watches it live). You
  wait for the pane's *agent status* to go `working` then `done` (the same Stop
  signal the Agent Panel shows) — **NOT** for the verdict marker. The reviewer
  echoes your whole prompt (markers included) the instant it starts, so an
  output-wait on the marker returns immediately on that echo, long before any real
  verdict exists. Once the pane is `done`, `pane read` and slice the marked block.
  The marker is for *extraction only*, never for detecting completion.
- **No model guessing.** Use the reviewer CLI's own default model. Passing a model
  id is the #1 cause of failure ("model not supported for this account"). Only
  pass one if the user explicitly names it.
- **One input file, written once, never read back by you.** A packet that contains
  a git diff has quotes/`$`/backticks that are fragile to pass inline — the file
  is the clean way to hand it over. That's its only job.

## Preconditions

Must run inside an automation-enabled Sidekick pane:

```sh
test "$SIDEKICK_ENV" = 1 && command -v sidekick-ctl
```

If that fails, tell the user this skill needs to run inside Sidekick and stop.

Find the origin pane + tab:

```sh
sidekick-ctl pane current
```

Record `pane_id` (`$ORIGIN_PANE`, also `$SIDEKICK_PANE_ID`) and `tab_id`
(`$ORIGIN_TAB`).

## 1. Pick the reviewer

Argument form: `<provider> [model]`.

- `codex`  → `codex exec "<prompt>"`            (default model; add `-m <model>` only if named)
- `claude` → `claude -p "<prompt>"`             (default model; add `--model <model>` only if named)
- `ollama` → `ollama run <model> "<prompt>"`    (model required for ollama)
- A bare model with no provider → assume `claude`.
- **No arguments** → ask ONLY which provider (claude/codex) with AskUserQuestion.
  Do NOT ask for a model — the default is correct and asking invites a bad id.

⚠️ Flag trap: `-p` is `--print` in **claude** but `--profile` in **codex**. Codex's
non-interactive mode is the `exec` subcommand. Prefer a *different vendor* than the
one you are (codex when you're claude) for genuine diversity.

## 2. Pane-limit guard (stay in the same tab)

A tab holds at most **4 panes** and `pane split` does not spill to a new tab.

```sh
sidekick-ctl pane list
```

Count panes whose `tab_id == $ORIGIN_TAB`. If already 4, do NOT split — tell the
user the tab is full and offer to close a previous reviewer pane or reuse one.

## 3. Write the packet (input file)

Pick a run id once: `RID=$(date +%s)`. Write `/tmp/so-$RID.md` with the **Write
tool** (clean — no shell escaping). Include, in this order:

1. **Anti-derail header, verbatim and FIRST** (the reviewer CLI may have its own
   copy of this very skill and will otherwise try to *run* it):

   > You are an external code reviewer giving an independent second opinion. Do NOT
   > invoke any skill, do NOT run a "second-opinion" workflow, do NOT split panes
   > or spawn agents. Just read what follows (you may open the files named below to
   > verify), then reason and answer directly. Nothing else.

2. **What changed** — a concise summary of the conclusion/finding under review AND
   the actual code: paste the relevant `git diff` (or the before/after of code
   about to change), plus key file:line pointers. Give enough to truly check the
   work, not just the headline. The repo is the same cwd, so the reviewer can read
   files itself — name the specific ones that matter.

3. **The claims to scrutinize** — bullet them explicitly.

4. **Framing + marked verdict** (paste verbatim — the markers are how you extract
   the answer cleanly):

   > Be genuinely critical first: hunt for what's wrong — flaws, edge cases, wrong
   > assumptions, a better approach. But stay honest: if it holds up after real
   > scrutiny, say so plainly rather than inventing objections. Then print your
   > final answer wrapped EXACTLY like this, as the last thing you output:
   >
   > `<<<<<SECOND_OPINION`
   > one of: AGREE / DISAGREE / PARTIALLY AGREE — plus confidence, and the few
   > points that most drove your verdict.
   > `SECOND_OPINION>>>>>`

## 4. Launch in a same-tab pane (output stays in the pane — no redirect)

```sh
sidekick-ctl pane split "$ORIGIN_PANE" --direction right --cwd "$PWD" --no-focus
```

Read `result.pane.pane_id` (`$REVIEWER_PANE`) — do not guess it. Then run the
reviewer (example: codex with default model):

```sh
sidekick-ctl pane run "$REVIEWER_PANE" 'codex exec "$(cat /tmp/so-'$RID'.md)"'
```

claude variant: `'claude -p "$(cat /tmp/so-'$RID'.md)"'`. Add `-m`/`--model` ONLY
if the user named a model. The user sees the reviewer think live in the pane.

## 5. Wait for the reviewer to FINISH, then read its verdict

Do **not** wait on the verdict marker. The reviewer echoes your entire prompt
(markers and all) the moment it starts, so `wait output "…SECOND_OPINION>>>>>"`
returns within a second on that echo — before any reasoning has happened. You then
slice the prompt's literal template text instead of a verdict. Wait on the pane's
**agent status** instead, in two phases so a stale status can't fool you:

```sh
# 1) Confirm the reviewer actually STARTED. Guards against the pane's pre-launch
#    'idle' and against a leftover 'done' from a previous review in a reused pane.
sidekick-ctl wait agent-status "$REVIEWER_PANE" working --timeout 60000

# 2) Now block until it FINISHES — the real Stop signal (same 'done' the Agent
#    Panel shows). Generous timeout; real reviews take minutes:
sidekick-ctl wait agent-status "$REVIEWER_PANE" done --timeout 600000
```

`wait` exits non-zero on timeout. If phase 1 times out the launch likely failed —
`pane read` and report what you see rather than assuming a verdict. Only after
phase 2 returns `done` do you read and slice the block:

```sh
sidekick-ctl pane read "$REVIEWER_PANE" --source recent --lines 400 \
  | awk '/<<<<<SECOND_OPINION/{c=""; f=1; next} /SECOND_OPINION>>>>>/{f=0} f{c=c$0"\n"} END{printf "%s", c}'
```

Take the LAST marked block (the prompt echo holds the markers earlier; the awk
resets on each opening marker so the final, real block wins). If the markers never
appear (reviewer errored or derailed), read the last ~100 lines raw and report that.

> **Fallback — non-agent CLIs (plain `ollama run`):** these don't drive agent
> status, so the two-phase wait will just time out. For them only, block on the
> marker instead — `sidekick-ctl wait output "$REVIEWER_PANE" "SECOND_OPINION>>>>>"
> --timeout 600000` — then slice and take the LAST block. `codex exec` and
> `claude -p` both drive agent status (via their Stop hook), so prefer the status
> wait for those.

## 6. Clean up and report

```sh
sidekick-ctl pane close "$REVIEWER_PANE"   # only the pane you created
rm -f /tmp/so-$RID.md
```

Present the opinion inline, attributed (which provider/model) with the verdict
(AGREE / DISAGREE / PARTIALLY AGREE) up front. Do NOT paraphrase away disagreement
— if the reviewer found a real problem, surface it and act on it.

## Notes

- One reviewer is usually enough; for a stronger check repeat 3–6 with a second
  provider (mind the 4-pane limit).
- Leaving the reviewer pane open is fine if the user wants to scroll the live
  reasoning — just say so instead of closing it.
- Never close panes you didn't create, or send input to a pane whose id/purpose
  you haven't verified via `pane list` or the split response.
