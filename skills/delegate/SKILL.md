---
name: delegate
description: Delegate an implementation task to a worker agent in a visible Sidekick pane, supervise it, then independently review the result and iterate with feedback until it passes. The default worker matches the supervisor's family (Fable delegates to Opus; Codex sol delegates to terra), or name one explicitly ("delegate claude fable", "delegate codex terra"). Use when the user says "delegate this", "have opus do this", "send this to a worker", "spin up a worker for this", or wants the calling agent to hand off build work and act as the reviewer. The worker is a separate interactive CLI process driven via sidekick-ctl; the caller stays as supervisor.
---

# Delegate

Hand a well-specified task to a worker agent running interactively in a split
pane, wait for it to finish, then review its work yourself — diff, tests, the
worker's own summary — and send it feedback rounds until the work passes or you
escalate to the user. You (the supervising agent) never do the implementation;
you own the spec and the verdict.

This is the sibling of `second-opinion` with the roles reversed: there, the
other agent judges your work; here, you judge the other agent's work. The pane
conventions come from `sidekick-panes` — read pane IDs from responses, never
guess them, never close panes you didn't create.

## Preconditions

Three checks, in order — each failure means something different, so report the
one that actually failed and stop (do not attempt the workflow degraded):

```sh
test "$SIDEKICK_ENV" = 1   # not set → this terminal is not a Sidekick pane
command -v sidekick-ctl    # missing → Sidekick's CLI is not installed/on PATH
sidekick-ctl ping          # fails → Sidekick pane, but the control socket is
                           # unreachable (typical inside a codex sandbox —
                           # retry with escalated permissions before giving up)
```

Then discover the layout:

```sh
sidekick-ctl pane current    # record $ORIGIN_PANE and $ORIGIN_TAB
sidekick-ctl pane list       # 4-pane tab limit: if full, ask before closing anything
```

## 1. Pick the worker

Argument form: `[provider] [model] <task>`.

**No provider/model given → default by who is supervising.** You (the agent
reading this) know which CLI you are; the worker defaults to your own family —
the usual pairings are Fable supervising Opus, and Codex sol supervising terra:

- Supervisor is claude (Fable) → worker `claude --model opus`
- Supervisor is codex (sol)    → worker `codex -m terra`

Explicit forms, when the user names the pair (it may differ run to run):

- `delegate claude fable <task>` → `claude --model fable`
- `delegate claude opus <task>`  → `claude --model opus`
- `delegate codex sol <task>`    → `codex -m sol`
- `delegate codex terra <task>`  → `codex -m terra`

Bare model with no provider → infer it: `opus`, `sonnet`, `haiku`, `fable`
mean claude; `sol`, `terra` mean codex. Pass the model through exactly as the
user gave it — the claude CLI accepts family aliases, and codex takes `-m`.
Do NOT guess or expand model ids yourself; a wrong id is the #1 launch
failure. If the CLI rejects the model (instant exit with a model error in the
pane), report the error and offer that provider's default instead of trying a
different id.

⚠️ Flag trap: the model flag is `--model` for claude but `-m` for codex.

Workers launched with `claude`/`codex` as the program inherit Sidekick's scoped
permission flags automatically — do NOT add your own permission-mode flags.

## 2. Write the task packet

Pick `RID=$(date +%s)`. Write `/tmp/delegate-$RID.md` with the Write tool (no
shell escaping). A good packet is a spec, not a wish. Include, in order:

1. **Anti-derail header, verbatim and FIRST:**

   > You are a worker agent implementing a delegated task. Do NOT invoke a
   > "delegate" skill, do NOT split panes or spawn further agents. Implement
   > the task below directly in this repository, then stop.

2. **The task** — goal, the specific files/areas involved (name them), and
   constraints (what must not change, style rules, no commits unless asked).

3. **Definition of done** — the tests/build commands that must pass, verbatim.

4. **Completion contract** (paste verbatim):

   > When you are done, end your final message with a summary wrapped EXACTLY:
   >
   > `<<<<<DELEGATE_DONE`
   > what you changed (files), what you verified (commands + results), and
   > anything you deliberately skipped.
   > `DELEGATE_DONE>>>>>`

## 3. Launch interactive, in a split

Interactive (not `-p`) so the user can watch, and so feedback rounds land in
the same session with full context (example shows the default worker; swap in
the provider/model chosen in step 1):

```sh
sidekick-ctl pane split "$ORIGIN_PANE" --direction right --cwd "$PWD" --no-focus \
  --exec claude --model opus -- "$(cat /tmp/delegate-$RID.md)"
```

Read `result.pane.pane_id` → `$WORKER_PANE`. If the task touches files you are
concurrently editing yourself, add `--worktree <branch>` instead of `--cwd`
(shared panes do not isolate filesystem changes) — but the default is same-cwd,
since the supervisor should be reading, not writing, during delegation.

> Each `--exec` argv item is capped at 32 KB. For a huge packet, launch as
> `--exec sh -c 'exec claude --model opus -- "$(cat /tmp/delegate-<RID>.md)"'`.

## 4. Wait, and handle the human-input case

```sh
sidekick-ctl wait agent-status "$WORKER_PANE" done --timeout 900000
```

The Stop hook flips the pane to `done` when the worker's turn completes, even
in interactive mode. Do not end your turn after dispatching — block, then
review, in the same turn. On timeout: `pane read --source visible --lines 60`
and triage:

- **Working** (output still flowing) → wait again.
- **Needs input** (approval prompt, question) → if it's a routine tool/edit
  approval within the task's stated scope, answer it via `pane send-key`; if
  it's a real decision, surface it to the user instead of guessing.
- **Stuck/errored** → report what the pane shows.

## 5. Review — independently, then iterate

After `done`, extract the worker's summary (LAST marked block — the prompt echo
contains the markers too):

```sh
sidekick-ctl pane read "$WORKER_PANE" --source recent --lines 400 \
  | awk '/<<<<<DELEGATE_DONE/{c=""; f=1; next} /DELEGATE_DONE>>>>>/{f=0} f{c=c$0"\n"} END{printf "%s", c}'
```

Then verify yourself — the summary is a claim, not evidence:

- `git status` + `git diff` — read the actual changes.
- Run the definition-of-done commands yourself; do not trust reported results.
- Check the diff for scope creep (files the packet didn't authorize).

**If it fails review**, send one consolidated feedback round (not a drip):

```sh
sidekick-ctl pane run "$WORKER_PANE" "Review feedback: <specific defects, file:line>. Fix these, re-run <tests>, and end with the same DELEGATE_DONE block."
```

Read the pane to confirm the prompt submitted (send `pane send-key
"$WORKER_PANE" enter` if it's sitting in the input box). The pane may still
read `done` from the previous turn, so re-arm the wait:
`wait agent-status "$WORKER_PANE" working --timeout 15000 || true`, then wait
for `done` again and re-review. **Two feedback rounds maximum** — if it still
fails, stop and report honestly what's wrong rather than looping.

## 6. Report

Leave the worker pane open (the user watches it; say so) unless they asked for
cleanup. Report: what was delegated and to whom, your independent verdict on
the diff and tests (not the worker's self-assessment), what feedback rounds
changed, and anything you'd still fix. `rm -f /tmp/delegate-$RID.md`.
