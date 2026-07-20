#!/usr/bin/env bash
#
# dcg-guard.sh — Destructive Command Guard.
#
# A Claude Code PreToolUse hook (matcher: "Bash"). Before the agent runs a shell
# command, this reads the hook JSON on stdin, extracts the command, and tests it
# against the patterns in blocklist.txt. A match blocks the command.
#
#   exit 0  -> allow (no pattern matched, or nothing to check)
#   exit 2  -> BLOCK; the reason on stderr is shown back to the agent
#
# On a block it ALSO: appends a line to the audit log and (on macOS) pops a
# desktop notification, so you always know a block happened rather than silently
# wondering why the agent stalled.
#
# The rules live in blocklist.txt (one extended-regex per line). Editing that
# file is how you tighten or loosen the guard — no need to touch this script.
#
#   Log file        : ${DCG_LOG:-~/.claude/dcg-guard.log}   (override with $DCG_LOG)
#   Desktop popup   : on by default; set DCG_NOTIFY=0 to silence it
#
# Manual test (feed a command straight in, bypassing the JSON wrapper):
#   echo 'rm -rf /' | ~/.claude/hooks/dcg-guard.sh --test
#   echo 'ls -la'   | ~/.claude/hooks/dcg-guard.sh --test   # should allow
#   ~/.claude/hooks/dcg-guard.sh --log        # show recent blocks
#
# Design note: this matches the raw command string (case-insensitive). It is a
# deliberately simple first line of defense — it will NOT catch a destructive
# command hidden inside a heredoc, base64, or an aliased variable. It catches
# the common, high-regret mistakes. Treat it as a seatbelt, not a vault.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCKLIST="$HERE/blocklist.txt"
LOG="${DCG_LOG:-$HOME/.claude/dcg-guard.log}"

# --- convenience: view the log ----------------------------------------------
if [ "${1:-}" = "--log" ]; then
  [ -f "$LOG" ] && tail -n "${2:-20}" "$LOG" || echo "No blocks logged yet ($LOG)."
  exit 0
fi

# --- obtain the command being run -------------------------------------------
if [ "${1:-}" = "--test" ]; then
  # Test mode: treat stdin as the raw command.
  cmd="$(cat)"
else
  # Hook mode: stdin is Claude Code's PreToolUse JSON. Pull out the command.
  input="$(cat)"
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
fi

# Nothing to inspect (non-Bash tool, empty command, or unparseable input) ->
# fail open. We only ever *block* on a positive match.
[ -z "${cmd//[[:space:]]/}" ] && exit 0

# --- record + alert on a block ----------------------------------------------
alert() {
  local rule="$1" command="$2" ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  # Audit log: one tab-separated line per block. Never let logging failure
  # (e.g. unwritable dir) abort the block itself.
  { mkdir -p "$(dirname "$LOG")" 2>/dev/null && \
      printf '%s\tBLOCKED\trule=%s\tcmd=%s\n' "$ts" "$rule" "$command" >> "$LOG"; } 2>/dev/null || true
  # Desktop notification (macOS). Toggle off with DCG_NOTIFY=0.
  if [ "${DCG_NOTIFY:-1}" != "0" ] && command -v osascript >/dev/null 2>&1; then
    # Truncate long commands for the banner; escape double quotes for AppleScript.
    local short="${command:0:120}"
    short="${short//\"/\\\"}"
    osascript -e "display notification \"${short}\" with title \"🛑 dcg-guard blocked a command\" sound name \"Basso\"" >/dev/null 2>&1 || true
  fi
}

# --- test against the blocklist (first match wins) --------------------------
[ -f "$BLOCKLIST" ] || exit 0

while IFS= read -r line || [ -n "$line" ]; do
  # Skip blank lines and comments.
  case "$line" in
    ''|'#'*) continue ;;
  esac
  if printf '%s' "$cmd" | grep -Eiq -- "$line"; then
    alert "$line" "$cmd"
    {
      echo "🛑 dcg-guard BLOCKED a destructive command."
      echo "   Matched rule : $line"
      echo "   Command      : $cmd"
      echo
      echo "   Logged to $LOG (view: ~/.claude/hooks/dcg-guard.sh --log)."
      echo "   This guard lives in ~/dotfiles-mac/claude/.claude/hooks/blocklist.txt."
      echo "   If this command is genuinely safe and intended, run it yourself in a"
      echo "   terminal, or loosen the rule in blocklist.txt."
    } >&2
    exit 2
  fi
done < "$BLOCKLIST"

exit 0
