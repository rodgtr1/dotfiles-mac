# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Homebrew paths without running `brew shellenv` on every shell startup.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
fpath=("/opt/homebrew/share/zsh/site-functions" "$HOME/.bun" $fpath)
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# PATH additions. Homebrew's bin/sbin first (replaces `eval "$(brew shellenv)"`),
# then cargo, windsurf, bun, lmstudio, go, local bin.
path=(
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  "$HOME/.cargo/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/.lmstudio/bin"
  "$HOME/go/bin"
  $path
)
typeset -U path fpath
export PATH
export BUN_INSTALL="$HOME/.bun"

# Ghostty sets a TERM that some tools don't recognize.
if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
  export TERM=xterm-256color
fi

# --- Completion system ---
# Oh My Zsh used to run this for us. Initialize zsh's own completion system
# directly. `-u` skips the slow "insecure completion directories" security audit
# on every start (the old ZSH_DISABLE_COMPFIX=true). Homebrew's site-functions
# (added to fpath above) and zsh's bundled completions (git, etc.) are picked up.
autoload -Uz compinit && compinit -u

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'
export VISUAL='nvim'

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Personal aliases. For a full list of active aliases, run `alias`.
alias k="kubectl";
alias n="nvim";

cpp() {
  claude -p "$*"
}

# Re-assert all dotfiles symlinks. Some apps (Sidekick, Raycast, VS Code) save
# config via atomic write (temp file + rename), which replaces the stow symlink
# with a real file. `restow` moves any such foreign real file into a single
# backup dir (~/.dotfiles-backup, overwritten each run), then re-stows so the
# dotfiles version is authoritative again.
restow() {
  local backup="$HOME/.dotfiles-backup"
  local f rel tgt pdir pkg drift backed_up=0
  # Resolve to a physical absolute path with zsh's :A modifier. Do NOT use
  # $(cd ... && pwd -P): a chpwd hook (Sidekick/terminal OSC-7 cwd reporting)
  # emits escape sequences on every cd, and command substitution captures them
  # into the variable. That pollution is what made the folded-dir guard below
  # fail and move the repo's own source files into the backup.
  local dotfiles="$HOME/dotfiles-mac"; dotfiles=${dotfiles:A}
  [ -n "$dotfiles" ] && [ -d "$dotfiles" ] || { echo "restow: dotfiles dir not found" >&2; return 1; }
  ( cd "$dotfiles" || return 1
    for pkg in */; do
      pkg="${pkg%/}"
      [ "$pkg" = "skills" ] && continue   # skills use custom targets, not $HOME
      drift=0
      # Back up only genuine FOREIGN real files that would block stow. Skip
      # anything whose real parent already resolves into the repo — those are
      # reached through a stow-folded directory symlink, and moving them would
      # yank files straight out of the repo.
      while IFS= read -r f; do
        rel="${f#"$pkg"/}"
        tgt="$HOME/$rel"
        [ -L "$tgt" ] && continue                 # our own symlink — leave it
        [ -e "$tgt" ] || continue                 # not present — stow will link
        pdir=${tgt:h:A}                                   # physical parent dir, no cd/hook
        case "$pdir/" in "$dotfiles"/*) continue ;; esac   # reached via folded dir
        mkdir -p "$backup/$(dirname "$rel")"
        mv "$tgt" "$backup/$rel" && echo "restow: backed up $rel"
        drift=1; backed_up=1
      done < <(find "$pkg" -type f)
      # Only (re)stow packages that actually drifted. stow --restow deletes and
      # recreates symlinks; doing that to a HEALTHY package briefly removes the
      # config file, which can knock a running app (e.g. Sidekick) back to its
      # built-in defaults. Healthy links are left untouched.
      if [ "$drift" -eq 1 ]; then
        # --no-folding: keep per-file symlinks; a plain restow would re-fold the
        # package into one dir symlink, the very thing that let apps delete repo files.
        stow --no-folding --restow --target="$HOME" "$pkg" && echo "restow: re-linked $pkg" \
          || echo "restow: $pkg failed" >&2
      fi
    done
    if [ "$backed_up" -eq 0 ]; then echo "restow: nothing drifted — links healthy"
    else echo "restow: foreign files saved under $backup"; fi )
}


# Set up fzf key bindings and fuzzy completion (only if fzf is installed).
if [[ -t 0 ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

eval "$(starship init zsh)"

export PATH="$HOME/.local/bin:$PATH"

# node/npm/npx/etc. are real binaries on PATH (added in .zshenv, no nvm.sh cost).
# Only the `nvm` management command itself needs nvm.sh, so load it lazily the
# first time it's actually invoked. This shim is self-replacing: nvm.sh defines
# the real `nvm`, so there's no recursion.
nvm() {
  unset -f nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Sidekick shell integration
[[ "$TERM_PROGRAM" == "Sidekick" ]] && source "$HOME/.config/sidekick/shell-integration/sidekick.zsh"

# Machine-specific local config
# Not version controlled
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# Grey type-ahead suggestions from history (replaces the old oh-my-zsh plugin).
# Use the hardcoded prefix instead of $(brew --prefix) to avoid a subprocess on
# every shell start. Must be sourced after compinit.
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
