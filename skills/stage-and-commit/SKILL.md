---
name: stage-and-commit
description: Stages files in a git initialized repo, writes a git commit description, and commits. Use when the user asks to stage and commit the changes.
---

1. Run `git status` and `git log --oneline -5` in parallel to see what's changed and match the repo's commit style. If there are any sensitive files that should be ignored or not committed, stop and flag them to the user.
2. Stage the changes with `git add .`
3. Run `git diff --cached` to review what's staged, then write a concise commit message focused on the *why* (not the what).
4. Commit using a HEREDOC to ensure correct formatting:
   ```
   git commit -m "$(cat <<'EOF'
   Your commit message here.

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```
5. Run `git status` to confirm the commit succeeded.
