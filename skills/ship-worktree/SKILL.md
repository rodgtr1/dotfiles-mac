---
name: ship-worktree
description: Ship the current git worktree — commit its work, merge the branch into the primary checkout, and leave both clean. Use when the user says "ship this worktree", "ship it", "merge this worktree into main", or asks to land a worktree's work from inside it.
sidekick-palette: true
sidekick-palette-label: Ship Worktree
sidekick-palette-submit: true
---

# Ship Worktree

Land this worktree's work in the primary checkout in one motion: commit,
merge, report. Shipping ends with both checkouts clean and main's history
moved; it never pushes, and it never removes the worktree you are standing
in.

## Preconditions

- You are inside a *linked* worktree, not the primary checkout. Check with
  `git worktree list --porcelain`: the first block is the primary; if its
  path is your toplevel (`git rev-parse --show-toplevel`), stop — there is
  nothing to ship from the primary, point the user at the Worktrees panel.
- You are on a branch. Detached HEAD → stop and ask which branch this work
  belongs on.

Record the primary's path and branch from that same `--porcelain` output;
every later `git -C <primary>` uses them. Never guess either.

## 1. Commit the work

If `git status --porcelain` shows anything, invoke the **stage-and-commit**
skill — it owns the commit rules (sensitive-file check, message style, no
agent attribution). Done when the worktree is clean.

If the tree is already clean *and* `git log <primary-branch>..HEAD --oneline`
is empty, there is nothing to ship: say so and stop.

## 2. Preflight the target

`git -C <primary> status --porcelain` must be empty. If it isn't, stop and
report what's dirty there — never stash or commit someone else's
half-finished work in the primary; the user decides.

## 3. Merge

Run `git -C <primary> merge <branch>`.

- On conflict: `git -C <primary> merge --abort`, then report the conflicted
  files (`git -C <primary> diff --name-only --diff-filter=U` before
  aborting). The primary must end clean — verify with `status --porcelain`
  — and the fix happens here in the worktree (rebase or merge the primary
  branch in, resolve, re-ship).
- Done when the merge commits (or fast-forwards) and
  `git -C <primary> log --oneline -1` shows it.

## 4. Report

State what landed: the branch, the commit(s), main's new head. Then the two
things shipping deliberately leaves to the user:

- The worktree still exists — your own process runs inside it, so removing
  it is not yours to do. Point at Worktrees panel → right-click → Remove
  Worktree, which now shows it clean.
- Nothing was pushed. Pushing is the user's call.
