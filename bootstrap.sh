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
log "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES/Brewfile"

# 4. Dotfiles via GNU Stow (every top-level package dir; hidden dirs ignored)
log "Linking dotfiles with stow..."
cd "$DOTFILES"
for pkg in */; do
  pkg="${pkg%/}"
  log "  stow $pkg"
  stow --restow --target="$HOME" "$pkg"
done

log "All done."
log "Restart your terminal (or run 'exec zsh') to load the new shell config."
