---
name: second-opinion
description: Get an independent second opinion on a conclusion or finding from another agent (a different model or CLI) running in a Cortland pane. Use when the user asks to "get a second opinion", "double-check this with another model", "have codex/opus review this", "sanity-check my conclusion", or when you want an honest adversarial cross-check of an answer before committing to it. Spawns the reviewer in the same tab, waits for its verdict, and reads it straight off the pane.
cortland-palette: true
---

# Second Opinion

Hand the current conclusion + the evidence (especially the code you changed or are
about to change) to a *different* agent running in a visible Cortland pane, let it
independently scrutinize the work, then read its verdict back and continue with it
in hand.

The reviewer is a separate CLI process (a different model or vendor), not an
internal subagent. That separation is the point — an independent take, not the
same model agreeing with itself. The user picks the reviewer by naming it:
`second-opinion codex`, `second-opinion claude opus`, `second-opinion claude
fable`, `second-opinion ollama llama3` — provider first, model optional.

## Design (read this — it's why the steps are short)

`pane split --exec <cmd...>` launches the reviewer as the new pane's **root
process**: argv is passed positionally through a fixed `exec "$@"`, never
re-parsed by a shell. Claude runs interactively so its TUI streams visibly and
its Stop hook drives the pane's agent status to `done`; one-shot CLIs drive
`done` when their process exits. That collapses the whole launch/wait dance:

- **One launch call, one wait.** The pane is brand new (starts `idle`, can't hold
  a stale `done`), and either Claude's Stop hook or one-shot process exit forces
  `done`. So a single `wait agent-status done` is the completion signal. Never wait on
  the verdict marker for completion: the reviewer echoes your whole prompt
  (markers included) in its transcript the instant it starts, so an output-wait
  on the marker fires on that echo long before any real verdict exists. The
  marker is for *extraction only*.
- **No model guessing.** Use the reviewer CLI's own default model. Passing a model
  id is the #1 cause of failure ("model not supported for this account"). Only
  pass one if the user explicitly names it.
- **One input file, written once, never read back by you.** A packet that contains
  a git diff has quotes/`$`/backticks that are fragile to pass inline — the file
  is the clean way to hand it over. At launch, `"$(cat file)"` expands to a
  single argv word (no re-parse), so the packet rides in cleanly.

## Preconditions

Must run inside an automation-enabled Cortland pane. Three checks, in order —
report the one that failed and stop (do not attempt the workflow degraded):

```sh
test "$CORTLAND_ENV" = 1   # not set → this terminal is not a Cortland pane
command -v cortland-ctl    # missing → Cortland's CLI is not installed/on PATH
cortland-ctl ping          # fails → Cortland pane, but the control socket is
                           # unreachable (typical inside a codex sandbox —
                           # retry with escalated permissions before giving up)
```

Find the origin pane + tab:

```sh
cortland-ctl pane current
```

Record `pane_id` (`$ORIGIN_PANE`, also `$CORTLAND_PANE_ID`) and `tab_id`
(`$ORIGIN_TAB`).

## 1. Pick the reviewer

Argument form: `<provider> [model]`.

- `codex`  → `codex exec "<packet>"`            (default model; add `-m <model>` only if named)
- `claude` → `claude -- "<packet>"`              (interactive; add `--model <model>` only if named)
- `ollama` → `ollama run <model> "<packet>"`    (model required for ollama)
- A bare model with no provider → assume `claude` (so `opus`, `sonnet`,
  `fable` alone mean `claude --model <that>`).
- **No arguments** → ask ONLY which provider (claude/codex) with AskUserQuestion.
  Do NOT ask for a model — the default is correct and asking invites a bad id.

When the user DOES name a model, pass it through as given — the claude CLI
accepts family aliases (`opus`, `sonnet`, `haiku`, `fable`) as well as full ids
like `claude-opus-4-8`. If the CLI rejects it (exits instantly with a model
error in the pane), report the error and offer the provider's default instead
of guessing a different id.

⚠️ Flag trap: `-p` is `--print` in **claude** but `--profile` in **codex**. Codex's
non-interactive mode is the `exec` subcommand. Prefer a *different vendor* than the
one you are (codex when you're claude) for genuine diversity.

## 2. Pane-limit guard (stay in the same tab)

A tab holds at most **4 panes** and `pane split` does not spill to a new tab.

```sh
cortland-ctl pane list
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

## 4. Launch: split with the reviewer as the pane's process

One call — the reviewer starts immediately as the new pane's root process
(example: codex with default model):

```sh
cortland-ctl pane split "$ORIGIN_PANE" --direction right --cwd "$PWD" --no-focus \
  --exec codex exec "$(cat /tmp/so-$RID.md)"
```

claude variant: `--exec claude -- "$(cat /tmp/so-$RID.md)"`; ollama:
`--exec ollama run <model> "$(cat /tmp/so-$RID.md)"`. Add `-m`/`--model` ONLY if
the user named a model. Read `result.pane.pane_id` (`$REVIEWER_PANE`) from the
split response — do not guess it. The user sees the reviewer think live in the
pane.

> **Big packets:** each `--exec` argv item is capped at 32 KB. If the split is
> rejected for a huge diff, do NOT wrap the launch in `sh -c` — a wrapper hides
> the program from Cortland's approval-flag injection. Keep the reviewer CLI as
> the program and point at the file instead:
> `--exec codex exec "Read /tmp/so-<RID>.md and follow its instructions exactly."`
> (claude variant: `--exec claude -- "Read /tmp/so-<RID>.md and follow its instructions exactly."`)

## 5. Wait for `done`, then read the verdict

Claude's Stop hook drives the interactive pane to `done`; process exit does the
same for one-shot reviewers (the same signal the Agent Panel shows), so one wait
covers every provider:

```sh
cortland-ctl wait agent-status "$REVIEWER_PANE" done --timeout 600000
```

`wait` exits non-zero on timeout; real reviews take minutes, hence the generous
timeout. On timeout, `pane read` and report what you see rather than assuming a
verdict. After `done`, read and slice the marked block:

```sh
cortland-ctl pane read "$REVIEWER_PANE" --source recent --lines 400 \
  | awk '/<<<<<SECOND_OPINION/{c=""; f=1; next} /SECOND_OPINION>>>>>/{f=0} f{c=c$0"\n"} END{printf "%s", c}'
```

Take the LAST marked block (the prompt echo holds the markers earlier; the awk
resets on each opening marker so the final, real block wins). If `done` arrived
but the markers are absent, two possibilities:

- **Launch failed** (bad binary/flags exits instantly, which also lands on
  `done`) — the pane tail will show the error; report it.
- **Premature `done`** (a non-hook CLI that went quiet mid-generation) — run
  `cortland-ctl wait output "$REVIEWER_PANE" "SECOND_OPINION>>>>>" --timeout
  600000` once as a safety net, then re-read and slice. If the markers still
  never appear, read the last ~100 lines raw and report that.

## 6. Clean up and report

```sh
cortland-ctl pane close "$REVIEWER_PANE"   # only the pane you created
rm -f /tmp/so-$RID.md
```

Present the opinion inline, attributed (which provider/model) with the verdict
(AGREE / DISAGREE / PARTIALLY AGREE) up front. Do NOT paraphrase away disagreement
— if the reviewer found a real problem, surface it and act on it.

## 7. Weigh it — do NOT blindly accept

The second opinion is *input*, not a verdict you must obey. After reading it, you
(the original agent) explicitly evaluate each point the reviewer raised and decide
for yourself whether to adopt it. A second opinion is exactly that — an opinion. It
can be wrong, miss context you have, or misread the intent.

For each substantive suggestion or objection, state your own position:

- **Accept** — you agree it's right; explain briefly why and apply it.
- **Reject** — you disagree; **give the concrete reason** (it misread the code,
  lacks context X, the tradeoff is intentional, it's factually wrong, etc.). Do not
  reject just to defend your original answer — only when you have a real reason.
- **Partially accept** — take the valid part, explain what you're leaving and why.

Then give a short final decision: what you're changing, what you're keeping as-is,
and the reasoning. If the reviewer changed your mind, say so plainly; if it didn't,
say why its points didn't hold up. The goal is a reasoned synthesis, not automatic
deference to the reviewer and not reflexive defense of yourself.

## Notes

- One reviewer is usually enough; for a stronger check repeat 3–6 with a second
  provider (mind the 4-pane limit).
- Leaving the reviewer pane open is fine if the user wants to scroll the live
  reasoning — just say so instead of closing it. A Claude reviewer remains an
  interactive session; one-shot reviewer processes have already exited.
- Workers launched via `--exec` with `claude`/`codex` as the program inherit
  Cortland's scoped permission flags automatically; don't add your own
  permission-mode flags.
- Never close panes you didn't create, or send input to a pane whose id/purpose
  you haven't verified via `pane list` or the split response.
