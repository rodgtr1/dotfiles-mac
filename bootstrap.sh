#!/usr/bin/env bash
#
# bootstrap.sh — set up a fresh macOS machine from these dotfiles.
#
# On a brand-new Mac:
#   xcode-select --install            # if git isn't available yet
#   git clone git@github.com:rodgtr1/dotfiles-mac.git ~/dotfiles-mac
#   ~/dotfiles-mac/bootstrap.sh
#
# Idempotent: safe to re-run. It skips anything already installed or linked.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*"; }

# Where pre-existing real files are moved before we replace them with symlinks.
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
backed_up=0

# Move any existing *real* (non-symlink) target files for a package out of the
# way so stow can link cleanly. stow folds directories on its own, so only file
# conflicts matter. Symlinks (incl. ones already owned by stow) are left alone.
backup_conflicts() {
  local pkg="$1" f rel tgt
  while IFS= read -r f; do
    rel="${f#"$pkg"/}"
    tgt="$HOME/$rel"
    if [ -e "$tgt" ] && [ ! -L "$tgt" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$tgt" "$BACKUP_DIR/$rel"
      warn "    backed up $rel"
      backed_up=1
    fi
  done < <(find "$pkg" -type f)
}

# 1. Xcode Command Line Tools (git, compilers — needed by Homebrew)
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  warn "Finish the Command Line Tools install in the popup, then re-run this script."
  exit 1
fi

# 2. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Load brew into this shell (Apple Silicon vs Intel)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 3. Packages
# `brew bundle` keeps going past individual failures and exits non-zero if any
# fail. We must NOT let that abort the script (set -e), or the stow step below
# — which links your actual dotfiles — would be skipped. Capture and report.
log "Installing packages from Brewfile..."
bundle_failed=0
brew bundle --file="$DOTFILES/Brewfile" || bundle_failed=1
if [ "$bundle_failed" -ne 0 ]; then
  warn "Some Brewfile entries failed to install (see output above). Continuing."
  warn "Casks (ghostty, zed, ...) commonly fail with 'xattr: Operation not permitted'"
  warn "if your terminal lacks the App Management permission. Grant it under:"
  warn "  System Settings > Privacy & Security > App Management"
  warn "then re-run: brew bundle --file=\"$DOTFILES/Brewfile\""
fi

# 4. Dotfiles via GNU Stow (every top-level package dir; hidden dirs ignored)
# stow is installed by brew above; bail out gracefully if the bundle couldn't.
if ! command -v stow >/dev/null 2>&1; then
  warn "stow is not installed — skipping dotfile linking."
  warn "Install it (brew install stow) and re-run this script to link dotfiles."
  exit 1
fi

log "Linking dotfiles with stow..."
cd "$DOTFILES"
for pkg in */; do
  pkg="${pkg%/}"
  log "  stow $pkg"
  backup_conflicts "$pkg"
  stow --restow --target="$HOME" "$pkg" || warn "  stow $pkg failed — skipping."
done

log "All done."
if [ "$backed_up" -ne 0 ]; then
  log "Existing files were backed up to: $BACKUP_DIR"
fi
if [ "$bundle_failed" -ne 0 ]; then
  warn "Note: some packages did not install — see the warnings above."
fi
log "Restart your terminal (or run 'exec zsh') to load the new shell config."
